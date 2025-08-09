// functions/src/index.ts (o index.js si usas JavaScript)

import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";

import * as admin from "firebase-admin";
import { v4 as uuidv4 } from "uuid"; // Necesitarás instalar 'uuid' y '@types/uuid'

// Inicializa el SDK de Admin de Firebase
admin.initializeApp();
const db = admin.firestore();

// Define una interfaz para la estructura de los datos que esperas del cliente
interface InviteMemberData {
  familyId: string;
  emailOrName: string;
  isRegisteredUser: boolean;
  initialRole?: string;
  initialRelationshipType?: string;
  isDeceased?: boolean;
  isPet?: boolean;
}

// Función Callable para invitar a miembros a una familia
export const inviteFamilyMember = onCall<InviteMemberData>(async (request: CallableRequest<InviteMemberData>) => {
  const { data, auth } = request;

  // 1. Autenticación y Verificación de Administrador
  // Asegurarse de que el contexto de autenticación existe y el usuario está logueado
  if (!auth || !auth.uid) {
    throw new HttpsError(
      "unauthenticated",
      "La solicitud debe estar autenticada."
    );
  }

  const currentUserId = auth.uid;
  
  // Extraer datos del payload de forma segura
  const {
    familyId,
    emailOrName,
    isRegisteredUser,
    initialRole,
    initialRelationshipType,
    isDeceased = false, // Asignar valor por defecto para evitar undefined
    isPet = false,      // Asignar valor por defecto para evitar undefined
  } = data;

  if (!familyId || !emailOrName) {
    throw new HttpsError(
      "invalid-argument",
      "familyId y emailOrName son obligatorios."
    );
  }

  const familyRef = db.collection("families").doc(familyId);
  const familyDoc = await familyRef.get();

  if (!familyDoc.exists) {
    throw new HttpsError("not-found", "Familia no encontrada.");
  }

  const familyData = familyDoc.data();
  const adminUserIds: string[] = familyData?.adminUserIds || [];

  // Verificar si el usuario que llama es un administrador de la familia
  if (!adminUserIds.includes(currentUserId)) {
    throw new HttpsError(
      "permission-denied",
      "Solo los administradores de la familia pueden invitar miembros."
    );
  }

  const currentUserProfileDoc = await db.collection("users").doc(currentUserId).get();
  const invitedByDisplayName = currentUserProfileDoc.data()?.displayName || "Usuario Desconocido";

  // 2. Lógica de Invitación / Añadir Miembro
  const batch = db.batch();

  if (isRegisteredUser) {
    // --- Invitar usuario registrado existente por email ---
    const invitedUserQuery = await db
      .collection("users")
      .where("email", "==", emailOrName)
      .limit(1)
      .get();

    if (invitedUserQuery.empty) {
      throw new HttpsError(
        "not-found",
        "No se encontró usuario registrado con este email."
      );
    }
    const invitedUserId = invitedUserQuery.docs[0].id;

    // Verificar si ya es miembro
    const memberUserIds: string[] = familyData?.memberUserIds || [];
    if (memberUserIds.includes(invitedUserId)) {
      throw new HttpsError(
        "already-exists",
        "Este usuario ya es miembro de la familia."
      );
    }

    // Verificar si ya hay una invitación pendiente
    const existingInvitation = await db
      .collection("invitations")
      .where("familyId", "==", familyId)
      .where("invitedUserId", "==", invitedUserId)
      .where("status", "==", "pending")
      .limit(1)
      .get();

    if (!existingInvitation.empty) {
      throw new HttpsError(
        "already-exists",
        "Ya existe una invitación pendiente para este usuario a esta familia."
      );
    }

    // Crear invitación
    const invitationId = uuidv4();
    const invitationCode = uuidv4().substring(0, 8).toUpperCase(); // Código corto
    const expiresAt = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 días desde ahora
    );

    batch.set(db.collection("invitations").doc(invitationId), {
      invitationId: invitationId,
      familyId: familyId,
      invitedByUserId: currentUserId,
      invitedByDisplayName: invitedByDisplayName,
      invitedEmail: emailOrName,
      invitedUserId: invitedUserId,
      initialRole: initialRole,
      initialRelationshipType: initialRelationshipType,
      status: "pending",
      createdAt: admin.firestore.Timestamp.now(),
      expiresAt: expiresAt,
      invitationCode: invitationCode,
    });

    // TODO: Aquí se podría integrar el envío de correo electrónico (ej. con SendGrid)
    // logger.info(`Invitation created for ${emailOrName} with code: ${invitationCode}`);

    await batch.commit();

    return { status: "success", message: "Invitación enviada con éxito." };
  } else {
    // --- Añadir miembro no registrado por nombre (puede ser fallecido/mascota) ---
    const unregisteredMembers: any[] = familyData?.unregisteredMembers || [];
    if (
      unregisteredMembers.some(
        (member: any) =>
          member.name === emailOrName &&
          member.isDeceased === isDeceased &&
          member.isPet === isPet
      )
    ) {
      throw new HttpsError(
        "already-exists",
        "Un miembro no registrado con este nombre y tipo ya existe en la familia."
      );
    }

    const memberId = uuidv4();
    const unregisteredMember = {
      memberId: memberId,
      name: emailOrName,
      relationship: initialRelationshipType || "other",
      profileData: {}, // Inicialmente vacío
      isDeceased: isDeceased,
      isPet: isPet,
    };

    // Añadir miembro no registrado al array en el documento de la familia
    batch.update(familyRef, {
      unregisteredMembers:
        admin.firestore.FieldValue.arrayUnion(unregisteredMember),
    });

    // Crear relación inicial entre el invitador y el nuevo miembro no registrado
    if (initialRelationshipType) {
      const relationshipId = uuidv4();
      batch.set(db.collection("familyRelationships").doc(relationshipId), {
        familyId: familyId,
        member1Ref: { type: "user", id: currentUserId },
        member2Ref: { type: "unregisteredMember", id: memberId },
        relationshipType: initialRelationshipType,
        dynamicType: "initial_connection",
        description: "Relación establecida al añadir miembro no registrado.",
        frequency: 0.0,
        lastInteraction: admin.firestore.Timestamp.now(),
        patterns: [],
        iaConfidenceScore: 0.0,
        interactionCount: 0,
      });
    }

    await batch.commit();
    return { status: "success", message: "Miembro no registrado añadido con éxito." };
  }
});
