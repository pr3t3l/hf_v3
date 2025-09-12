import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { v4 as uuidv4 } from "uuid";

admin.initializeApp();

interface InviteMemberData {
  familyId: string;
  emailOrName: string;            // email (esc. 1 y 2) o nombre (esc. 3)
  isRegisteredUser: boolean;      // true => esc. 1; false => esc. 2 o 3
  isUnregisteredUserEmail?: boolean; // true => esc. 2; false/undefined => esc. 3
  initialRole?: string;
  initialRelationshipType?: string;
  isDeceased?: boolean;
  isPet?: boolean;
}

interface JoinFamilyData {
  invitationCode: string;
}

const normalizeEmail = (s: string) => s.trim().toLowerCase();

// --- inviteFamilyMember ------------------------------------------------------

/**
 * Maneja la invitación de nuevos miembros a una familia.
 * Soporta 3 escenarios:
 * 1) Usuario registrado por email.
 * 2) Persona NO registrada por email (passwordless link + extensión /mail).
 * 3) Miembro no registrado (mascota/fallecido) por nombre.
 */
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

    const familyData = familyDoc.data() as any;
    if (!familyData?.adminUserIds?.includes(inviterId)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Solo los administradores pueden invitar nuevos miembros."
      );
    }

    const batch = db.batch();

    // ESCENARIO 1: Usuario registrado (por email)
    if (isRegisteredUser) {
      const normalizedEmail = normalizeEmail(emailOrName);

      const invitedUserQuery = await db
        .collection("users")
        .where("email", "==", normalizedEmail)
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

      const memberUserIds: string[] = Array.isArray(familyData.memberUserIds) ? familyData.memberUserIds : [];
      const usersPending: (string)[] = Array.isArray(familyData.usersPending) ? familyData.usersPending : [];

      if (memberUserIds.includes(invitedUserId)) {
        throw new functions.https.HttpsError("already-exists", "Este usuario ya es miembro de la familia.");
      }
      if (usersPending.includes(invitedUserId)) {
        throw new functions.https.HttpsError("already-exists", "Ya existe una invitación pendiente para este usuario.");
      }

      const invitationCode = Math.random().toString(36).substring(2, 10).toUpperCase();
      const invitationId = db.collection("invitations").doc().id;
      const inviterProfile = (await db.collection("users").doc(inviterId).get()).data();
      const invitedByDisplayName = inviterProfile?.displayName || "Administrator";

      const newInvitation = {
        familyId,
        invitedByUserId: inviterId,
        invitedByDisplayName,
        invitedEmail: normalizedEmail,
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
        usersPending: admin.firestore.FieldValue.arrayUnion(invitedUserId), // UID en pending
      });

      await batch.commit();
      return { status: "success", message: "Invitación enviada a usuario registrado." };
    }

    // ESCENARIO 2: Persona NO registrada (por email con enlace passwordless)
    if (isUnregisteredUserEmail) {
      const normalizedEmail = normalizeEmail(emailOrName);

      // Debe NO existir usuario con ese email
      const invitedUserQuery = await db
        .collection("users")
        .where("email", "==", normalizedEmail)
        .limit(1)
        .get();
      if (!invitedUserQuery.empty) {
        throw new functions.https.HttpsError(
          "already-exists",
          "Un usuario con este correo electrónico ya está registrado. Invítalo como usuario registrado."
        );
      }

      const invitationId = db.collection("invitations").doc().id;
      const invitationCode = Math.random().toString(36).substring(2, 10).toUpperCase();
      const inviterProfile = (await db.collection("users").doc(inviterId).get()).data();
      const invitedByDisplayName = inviterProfile?.displayName || "Administrator";

      const newInvitation = {
        familyId,
        invitedByUserId: inviterId,
        invitedByDisplayName,
        invitedEmail: normalizedEmail,
        invitedUserId: null, // aún no hay UID
        initialRole: initialRole || "child",
        initialRelationshipType: initialRelationshipType || "other",
        status: "pending", // importante: 'pending' para que joinFamily la encuentre
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 7 * 24 * 60 * 60 * 1000),
        invitationCode, // código presente para uniformidad del flujo
      };
      batch.set(db.collection("invitations").doc(invitationId), newInvitation);

      // Generar link passwordless incluyendo invitationCode en la continue URL
      const actionCodeSettings = {
        url: `https://healthy-families-dev.web.app/join?invitationCode=${invitationCode}`,
        handleCodeInApp: true,
      };
      const link = await admin.auth().generateSignInWithEmailLink(normalizedEmail, actionCodeSettings);

      // Escribir en /mail para disparar la extensión Trigger Email (OAuth2)
      batch.set(db.collection("mail").doc(), {
        to: [normalizedEmail],
        message: {
          subject: "¡Has sido invitado a unirte a una familia!",
          html: `<p><b>Hola,</b></p>
                 <p>Has sido invitado a unirte a una familia en Healthy Families.</p>
                 <p>Utiliza este enlace para continuar el proceso seguro: <a href="${link}">Aceptar invitación</a></p>`,
          text: `Has sido invitado a unirte a una familia. Abre este enlace para aceptar: ${link}`,
        },
      });

      // En pending guardamos el identificador disponible (email). Luego joinFamily lo limpiará por uid o email.
      batch.update(familyRef, {
        usersPending: admin.firestore.FieldValue.arrayUnion(normalizedEmail),
      });

      await batch.commit();
      return { status: "success", message: "Invitación enviada a persona no registrada (email link)." };
    }

    // ESCENARIO 3: Miembro no registrado (mascota/fallecido) por nombre
    const memberId = uuidv4();
    const unregisteredMember = {
      memberId,
      name: emailOrName, // aquí es nombre, no email
      relationship: initialRelationshipType || "other",
      profileData: {},
      isDeceased: !!isDeceased,
      isPet: !!isPet,
    };

    batch.update(familyRef, {
      unregisteredMembers: admin.firestore.FieldValue.arrayUnion(unregisteredMember),
    });

    await batch.commit();
    return { status: "success", message: "Miembro no registrado añadido con éxito." };
  }
);

// --- joinFamily --------------------------------------------------------------

/**
 * Permite a un usuario autenticado unirse a una familia proporcionando un invitationCode válido.
 * Soporta:
 *  - Invitaciones a usuarios ya registrados (invitedUserId presente).
 *  - Invitaciones passwordless (invitedUserId null), verificando coincidencia por email.
 */
export const joinFamily = functions.https.onCall(
  async (request: functions.https.CallableRequest<JoinFamilyData>) => {
    const { invitationCode } = request.data;
    const userId = request.auth?.uid;

    if (!userId) {
      throw new functions.https.HttpsError("unauthenticated", "El usuario no está autenticado.");
    }

    const db = admin.firestore();

    // 1) Recuperar invitación por código
    const invitationSnap = await db
      .collection("invitations")
      .where("invitationCode", "==", invitationCode)
      .limit(1)
      .get();

    if (invitationSnap.empty) {
      throw new functions.https.HttpsError("not-found", "Invitación no encontrada.");
    }

    const invitationDoc = invitationSnap.docs[0];
    const invitationData = invitationDoc.data() as any;

    // 2) Validar estado y expiración
    const isPending = invitationData.status === "pending";
    const notExpired =
      !invitationData.expiresAt ||
      (invitationData.expiresAt.toMillis && invitationData.expiresAt.toMillis() > Date.now());

    if (!isPending || !notExpired) {
      throw new functions.https.HttpsError("failed-precondition", "Invitación no válida o expirada.");
    }

    const familyId = invitationData.familyId;

    // 3) Cargar usuario y familia
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

    const user = userDoc.data() as any;
    const userEmail = (user?.email ? String(user.email) : "").toLowerCase();
    if (!userEmail) {
      throw new functions.https.HttpsError("failed-precondition", "El usuario no tiene email registrado.");
    }

    const familyData = familyDoc.data() as { memberUserIds?: string[]; usersPending?: (string)[] };

    // 4) Validar destinatario de la invitación
    // - Si la invitación ya trae invitedUserId, debe coincidir con el uid actual.
    // - Si no trae invitedUserId, debe coincidir el email del usuario con invitedEmail.
    if (invitationData.invitedUserId && invitationData.invitedUserId !== userId) {
      throw new functions.https.HttpsError("permission-denied", "La invitación no corresponde a este usuario.");
    }
    if (!invitationData.invitedUserId) {
      const invitedEmail = (invitationData.invitedEmail || "").toLowerCase();
      if (!invitedEmail || invitedEmail !== userEmail) {
        throw new functions.https.HttpsError("permission-denied", "La invitación no corresponde a este email.");
      }
    }

    // 5) Evitar duplicados en miembros
    const memberUserIds: string[] = Array.isArray(familyData?.memberUserIds) ? familyData!.memberUserIds! : [];
    if (memberUserIds.includes(userId)) {
      throw new functions.https.HttpsError("already-exists", "Ya eres miembro de esta familia.");
    }

    const usersPending: (string)[] = Array.isArray(familyData?.usersPending) ? familyData!.usersPending! : [];

    const batch = db.batch();

    // 6) Actualizaciones atómicas:
    // - Mover usuario a miembros (string[] de uid)
    // - Limpiar pending por uid o email
    const updatedMemberUserIds = [...memberUserIds, userId];
    const updatedUsersPending = usersPending.filter((x) => x !== userId && x.toLowerCase?.() !== userEmail);

    batch.update(familyDoc.ref, {
      memberUserIds: updatedMemberUserIds,
      usersPending: updatedUsersPending,
    });

    // - Añadir familyId al usuario
    batch.update(userDoc.ref, {
      familyIds: admin.firestore.FieldValue.arrayUnion(familyId),
    });

    // - Marcar invitación como aceptada y, si no tenía invitedUserId, setearlo
    const invitationUpdate: any = { status: "accepted" };
    if (!invitationData.invitedUserId) {
      invitationUpdate.invitedUserId = userId;
    }
    batch.update(invitationDoc.ref, invitationUpdate);

    // 7) Crear relación inicial en /familyRelationships si no existe (idempotente)
    const member1Id = invitationData.invitedByUserId;
    const member2Id = userId;

    const existingRelationshipQuery = await db
      .collection("familyRelationships")
      .where("familyId", "==", familyId)
      .where("member1Ref.id", "==", member1Id)
      .where("member2Ref.id", "==", member2Id)
      .limit(1)
      .get();

    const existingRelationshipQueryReverse = await db
      .collection("familyRelationships")
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

    // 8) Commit
    await batch.commit();

    return { status: "success", message: "¡Te has unido a la familia con éxito!", familyId };
  }
);
