import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { v4 as uuidv4 } from "uuid";

admin.initializeApp();

interface InviteMemberData {
  familyId: string;
  emailOrName: string;
  isRegisteredUser: boolean;
  isUnregisteredUserEmail?: boolean; // New optional field
  initialRole?: string;
  initialRelationshipType?: string;
  isDeceased?: boolean;
  isPet?: boolean;
}

interface JoinFamilyData {
  invitationCode: string;
}

// Placeholder for a function that would send an email.
// In a real-world scenario, this would use a service like SendGrid, Mailgun, etc.
// eslint-disable-next-line @typescript-eslint/no-unused-vars
async function sendInvitationEmail(email: string, link: string) {
  // This is a placeholder. In a real app, you would integrate an email service.
  console.log(`Sending invitation email to ${email} with link: ${link}`);
  // Example with a theoretical email service:
  // await emailService.send({
  //   to: email,
  //   subject: "You're invited to join a family on Healthy Families!",
  //   html: `<p>Click <a href="${link}">here</a> to join.</p>`,
  // });
  return Promise.resolve();
}

export const inviteFamilyMember = functions.https.onCall(
  async (request: functions.https.CallableRequest<InviteMemberData>) => {
    const {
      familyId,
      emailOrName,
      isRegisteredUser,
      isUnregisteredUserEmail,
      initialRole,
      initialRelationshipType,
      isDeceased,
      isPet,
    } = request.data;
    const inviterId = request.auth?.uid;

    if (!inviterId) {
      throw new functions.https.HttpsError("unauthenticated", "User is not authenticated.");
    }

    const db = admin.firestore();
    const familyRef = db.collection("families").doc(familyId);
    const familyDoc = await familyRef.get();

    if (!familyDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Familia no encontrada.");
    }

    const familyData = familyDoc.data();
    if (!familyData?.adminUserIds?.includes(inviterId)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Solo los administradores pueden invitar nuevos miembros."
      );
    }

    const batch = db.batch();

    if (isRegisteredUser) {
      // Scenario 1: Invite a registered user by email
      const invitedUserQuery = await db
        .collection("users")
        .where("email", "==", emailOrName)
        .limit(1)
        .get();

      if (invitedUserQuery.empty) {
        throw new functions.https.HttpsError(
          "not-found",
          "No se encontró ningún usuario registrado con ese correo electrónico."
        );
      }
      const invitedUserDoc = invitedUserQuery.docs[0];
      const invitedUserId = invitedUserDoc.id;

      if (familyData.memberUserIds.includes(invitedUserId)) {
        throw new functions.https.HttpsError(
          "already-exists",
          "Este usuario ya es miembro de la familia."
        );
      }
      if (familyData.usersPending.includes(invitedUserId)) {
        throw new functions.https.HttpsError(
          "already-exists",
          "Ya existe una invitación pendiente para este usuario."
        );
      }

      const invitationCode = Math.random().toString(36).substring(2, 10).toUpperCase();
      const invitationId = db.collection("invitations").doc().id;
      const inviterProfile = (await db.collection("users").doc(inviterId).get()).data();
      const invitedByDisplayName = inviterProfile?.displayName || "Administrator";

      const newInvitation = {
        familyId,
        invitedByUserId: inviterId,
        invitedByDisplayName,
        invitedEmail: emailOrName,
        invitedUserId,
        initialRole: initialRole || "child",
        initialRelationshipType: initialRelationshipType || "other",
        status: "pending",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 7 * 24 * 60 * 60 * 1000),
        invitationCode,
      };

      batch.set(db.collection("invitations").doc(invitationId), newInvitation);
      batch.update(familyRef, {
        usersPending: admin.firestore.FieldValue.arrayUnion(invitedUserId),
      });
    } else if (isUnregisteredUserEmail) {
      // Scenario 2: Invite an unregistered user by email
      const invitedUserQuery = await db
        .collection("users")
        .where("email", "==", emailOrName)
        .limit(1)
        .get();
      if (!invitedUserQuery.empty) {
        throw new functions.https.HttpsError(
          "already-exists",
          "Un usuario con este correo electrónico ya está registrado. Invítalo como usuario registrado."
        );
      }

      const invitationId = db.collection("invitations").doc().id;
      const inviterProfile = (await db.collection("users").doc(inviterId).get()).data();
      const invitedByDisplayName = inviterProfile?.displayName || "Administrator";

      const newInvitation = {
        familyId,
        invitedByUserId: inviterId,
        invitedByDisplayName,
        invitedEmail: emailOrName,
        invitedUserId: null, // No UID yet
        initialRole: initialRole || "child",
        initialRelationshipType: initialRelationshipType || "other",
        status: "pending_unregistered",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 7 * 24 * 60 * 60 * 1000),
        invitationCode: null, // No code needed, link-based
      };
      batch.set(db.collection("invitations").doc(invitationId), newInvitation);

      const actionCodeSettings = {
        url: `https://healthy-families-dev.web.app/join?invitationId=${invitationId}`,
        handleCodeInApp: true,
      };

      const link = await admin.auth().generateSignInWithEmailLink(emailOrName, actionCodeSettings);

      // Placeholder for sending the email
      await sendInvitationEmail(emailOrName, link);

      batch.update(familyRef, {
        usersPending: admin.firestore.FieldValue.arrayUnion(emailOrName),
      });
    } else {
      // Scenario 3: Add an unregistered member by name (pet/deceased)
      const memberId = uuidv4();
      const unregisteredMember = {
        memberId,
        name: emailOrName,
        relationship: initialRelationshipType || "other",
        profileData: {},
        isDeceased: isDeceased || false,
        isPet: isPet || false,
      };
      batch.update(familyRef, {
        unregisteredMembers: admin.firestore.FieldValue.arrayUnion(unregisteredMember),
      });
    }

    await batch.commit();

    return { status: "success", message: "Invitación/Miembro añadido con éxito." };
  }
);

// =================================================================
// Cloud Function: joinFamily
// Permite a un usuario aceptar una invitación para unirse a una familia.
// =================================================================
export const joinFamily = functions.https.onCall(
  async (request: functions.https.CallableRequest<JoinFamilyData>) => {
    const { invitationCode } = request.data;
    const userId = request.auth?.uid;

    // 1. Autenticación del usuario
    if (!userId) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "El usuario no está autenticado."
      );
    }

    const db = admin.firestore();

    // 2. Encontrar y validar la invitación
    const invitationQuery = await db.collection("invitations")
      .where("invitationCode", "==", invitationCode)
      .where("status", "==", "pending")
      .where("invitedUserId", "==", userId)
      .limit(1)
      .get();

    if (invitationQuery.empty) {
      throw new functions.https.HttpsError(
        "not-found",
        "Invitación no encontrada o ya no es válida."
      );
    }

    const invitationDoc = invitationQuery.docs[0];
    const invitationData = invitationDoc.data();
    const familyId = invitationData.familyId;

    // 3. Obtener los documentos del usuario y de la familia en paralelo (Promise.all)
    const [userDoc, familyDoc] = await Promise.all([
      db.collection("users").doc(userId).get(),
      db.collection("families").doc(familyId).get(),
    ]);

    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Perfil de usuario no encontrado.");
    }
    if (!familyDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Familia no existe.");
    }

    const familyData = familyDoc.data() as {
      memberUserIds: any[];
      usersPending: string[];
    };

    // 4. Validar que el usuario no sea ya un miembro
    if (familyData?.memberUserIds?.some((m: any) => m.userId === userId)) {
      throw new functions.https.HttpsError(
        "already-exists",
        "Ya eres miembro de esta familia."
      );
    }

    const batch = db.batch();

    // 5. Actualizar el documento de la familia:
    //    - Mover al usuario de 'usersPending' a 'memberUserIds'.
    //    - Corregido para añadir solo el UID al array.
    const updatedMemberUserIds = [...familyData.memberUserIds, userId]; // AHORA ES CORRECTO
    const updatedUsersPending = familyData.usersPending.filter(
      (uid: string) => uid !== userId
    );

    batch.update(familyDoc.ref, {
      memberUserIds: updatedMemberUserIds,
      usersPending: updatedUsersPending,
    });
    batch.update(familyDoc.ref, {
      memberUserIds: updatedMemberUserIds,
      usersPending: updatedUsersPending,
    });

    // 6. Actualizar el documento del usuario: añadir el familyId
    batch.update(userDoc.ref, {
      familyIds: admin.firestore.FieldValue.arrayUnion(familyId),
    });

    // 7. Actualizar el estado de la invitación a "accepted"
    batch.update(invitationDoc.ref, {
      status: "accepted",
    });

    // 8. Crear una relación inicial en /familyRelationships (IDEMPOTENTE)
    // Verificar si la relación ya existe para evitar duplicados.
    // Se verifica en ambas direcciones (A-B y B-A)
    const member1Id = invitationData.invitedByUserId;
    const member2Id = userId;

    const existingRelationshipQuery = await db.collection("familyRelationships")
      .where("familyId", "==", familyId)
      .where("member1Ref.id", "==", member1Id)
      .where("member2Ref.id", "==", member2Id)
      .limit(1)
      .get();

    const existingRelationshipQueryReverse = await db.collection("familyRelationships")
      .where("familyId", "==", familyId)
      .where("member1Ref.id", "==", member2Id)
      .where("member2Ref.id", "==", member1Id)
      .limit(1)
      .get();

    if (existingRelationshipQuery.empty && existingRelationshipQueryReverse.empty) {
      const relationshipId = db.collection("familyRelationships").doc().id;
      const relationshipData = {
        familyId,
        member1Ref: { type: "user", id: member1Id },
        member2Ref: { type: "user", id: member2Id },
        relationshipType: invitationData.initialRelationshipType || "other",
        dynamicType: "initial_connection",
        description: "Relación inicial establecida al unirse a la familia.",
        frequency: 0.1,
        lastInteraction: admin.firestore.FieldValue.serverTimestamp(),
        iaConfidenceScore: 0.1,
        interactionCount: 1,
      };
      batch.set(db.collection("familyRelationships").doc(relationshipId), relationshipData);
    } else {
      console.log("Ya existe una relación entre estos miembros, se omite la creación.");
    }

    // 9. Commit del lote de escrituras
    await batch.commit();

    return { status: "success", message: "¡Te has unido a la familia con éxito!", familyId };
  }
);
