import * as functions from "firebase-functions/v2"; // Usamos la sintaxis v2
import * as admin from "firebase-admin";
import { v4 as uuidv4 } from "uuid";

// Inicializa Firebase Admin SDK solo una vez
admin.initializeApp();

// Definiciones de tipos para mejorar la legibilidad y el tipado
interface InviteMemberData {
  familyId: string;
  emailOrName: string;
  isRegisteredUser: boolean;
  initialRole?: string;
  initialRelationshipType?: string;
  isDeceased?: boolean;
  isPet?: boolean;
}

interface JoinFamilyData {
  invitationCode: string;
}

// =================================================================
// Cloud Function: inviteFamilyMember
// Permite a un administrador invitar a un usuario registrado o añadir
// un miembro no registrado a una familia.
// =================================================================
export const inviteFamilyMember = functions.https.onCall(
  async (request: functions.https.CallableRequest<InviteMemberData>) => {
    const {
      familyId,
      emailOrName,
      isRegisteredUser,
      initialRole,
      initialRelationshipType,
      isDeceased,
      isPet,
    } = request.data;
    const inviterId = request.auth?.uid;

    // 1. Autenticación y validación del invitador
    if (!inviterId) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "El usuario no está autenticado."
      );
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
      // Escenario 1: Invitar a un usuario ya registrado por correo electrónico
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

      // Verificar si ya es miembro o tiene una invitación pendiente
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
      const invitedByDisplayName = inviterProfile?.displayName || "Administrador";

      const newInvitation = {
        familyId,
        invitedByUserId: inviterId,
        invitedByDisplayName,
        invitedEmail: emailOrName,
        invitedUserId,
        initialRole: initialRole || "child", // Rol por defecto si no se especifica
        initialRelationshipType: initialRelationshipType || "other", // Relación por defecto
        status: "pending",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 7 * 24 * 60 * 60 * 1000), // Expira en 7 días
        invitationCode,
      };

      batch.set(db.collection("invitations").doc(invitationId), newInvitation);

      // Actualizar la familia: añadir a usersPending y opcionalmente a adminUserIds
      const familyUpdates: { [key: string]: any } = {
        usersPending: admin.firestore.FieldValue.arrayUnion(invitedUserId),
      };
      if (initialRole === "administrator") {
        familyUpdates.adminUserIds = admin.firestore.FieldValue.arrayUnion(invitedUserId);
      }
      batch.update(familyRef, familyUpdates);

    } else {
      // Escenario 2: Añadir un miembro no registrado (por nombre)
      // No requiere una cuenta de usuario en la app.
      const memberId = uuidv4(); // Generar un ID único para el miembro no registrado
      const unregisteredMember = {
        memberId,
        name: emailOrName,
        relationship: initialRelationshipType || "other",
        profileData: {}, // Datos de perfilamiento IA iniciales vacíos
        isDeceased: isDeceased || false,
        isPet: isPet || false,
      };

      // Añadir el miembro no registrado al array 'unregisteredMembers' de la familia
      batch.update(familyRef, {
        unregisteredMembers: admin.firestore.FieldValue.arrayUnion(unregisteredMember),
      });

      // Opcional: Crear una relación inicial en /familyRelationships para miembros no registrados
      if (initialRelationshipType) {
        const relationshipId = db.collection("familyRelationships").doc().id;
        const relationshipData = {
          familyId,
          member1Ref: { type: "user", id: inviterId },
          member2Ref: { type: "unregisteredMember", id: memberId },
          relationshipType: initialRelationshipType,
          dynamicType: "initial_connection",
          description: "Relación establecida al añadir miembro no registrado.",
          frequency: 0.1,
          lastInteraction: admin.firestore.FieldValue.serverTimestamp(),
          iaConfidenceScore: 0.1,
          interactionCount: 1,
        };
        batch.set(db.collection("familyRelationships").doc(relationshipId), relationshipData);
      }
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
      memberUserIds: string[];
      usersPending: string[];
      adminUserIds: string[];
    };
    const userData = userDoc.data() as { displayName?: string };

    // 4. Validar que el usuario no sea ya un miembro
    if (familyData?.memberUserIds?.includes(userId)) {
      throw new functions.https.HttpsError(
        "already-exists",
        "Ya eres miembro de esta familia."
      );
    }

    const batch = db.batch();

    // 5. Create member document in the subcollection
    const memberRef = db.collection("families").doc(familyId).collection("members").doc(userId);
    batch.set(memberRef, {
      role: invitationData.initialRole || "child",
      displayName: userData.displayName ?? "Usuario",
    });

    // 6. Update the main family document
    const familyUpdates: { [key: string]: any } = {
      memberUserIds: admin.firestore.FieldValue.arrayUnion(userId),
      usersPending: admin.firestore.FieldValue.arrayRemove(userId),
    };

    if (invitationData.initialRole === "administrator") {
      familyUpdates.adminUserIds = admin.firestore.FieldValue.arrayUnion(userId);
    }
    batch.update(familyDoc.ref, familyUpdates);


    // 7. Actualizar el documento del usuario: añadir el familyId
    batch.update(userDoc.ref, {
      familyIds: admin.firestore.FieldValue.arrayUnion(familyId),
    });

    // 8. Actualizar el estado de la invitación a "accepted"
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
