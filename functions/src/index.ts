// functions/src/familyInvitations.ts
import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { v4 as uuidv4 } from "uuid";

admin.initializeApp();

interface InviteMemberData {
  familyId: string;
  emailOrName: string; // email (esc.1/2) o nombre (esc.3)
  isRegisteredUser: boolean; // true => esc.1; false => esc.2 o 3
  isUnregisteredUserEmail?: boolean; // true => esc.2
  initialRole?: string;
  initialRelationshipType?: string;
  isDeceased?: boolean;
  isPet?: boolean;
}

interface JoinFamilyData {
  invitationCode: string;
}

type FamilyDoc = {
  adminUserIds?: string[];
  memberUserIds?: string[]; // SIEMPRE string[] de UIDs
  usersPending?: (string)[]; // email o uid (string)
  unregisteredMembers?: any[];
};

const normalizeEmail = (s: string) => s.trim().toLowerCase();
const generateInvitationCode = () =>
  Math.random().toString(36).substring(2, 10).toUpperCase();

const isTimestampExpired = (ts: any) => {
  if (!ts) return false;
  const ms = typeof ts.toMillis === "function" ? ts.toMillis() : ts?.seconds * 1000;
  return typeof ms === "number" ? ms <= Date.now() : false;
};

// ============================== inviteFamilyMember ==============================

/**
 * Escenarios:
 * 1) Usuario registrado (por email)  -> crea invitación con code, pone UID en usersPending.
 * 2) Persona NO registrada (email)   -> crea invitación con code, manda passwordless link (extensión /mail), pone email en usersPending.
 * 3) Miembro no registrado (nombre)  -> añade a unregisteredMembers.
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
    const familySnap = await familyRef.get();

    if (!familySnap.exists) {
      throw new functions.https.HttpsError("not-found", "Familia no encontrada.");
    }

    const familyData = (familySnap.data() || {}) as FamilyDoc;
    if (!familyData.adminUserIds?.includes(inviterId)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Solo los administradores pueden invitar nuevos miembros."
      );
    }

    const batch = db.batch();
    const inviterProfile = (await db.collection("users").doc(inviterId).get()).data();
    const invitedByDisplayName = inviterProfile?.displayName || "Administrator";

    // ------------------ Escenario 1: usuario registrado por email ------------------
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

      const memberUserIds = Array.isArray(familyData.memberUserIds) ? familyData.memberUserIds : [];
      const usersPending = Array.isArray(familyData.usersPending) ? familyData.usersPending : [];

      if (memberUserIds.includes(invitedUserId)) {
        throw new functions.https.HttpsError("already-exists", "Este usuario ya es miembro de la familia.");
      }
      if (usersPending.includes(invitedUserId)) {
        throw new functions.https.HttpsError("already-exists", "Ya existe una invitación pendiente para este usuario.");
      }

      const invitationId = db.collection("invitations").doc().id;
      const invitationCode = generateInvitationCode();

      const newInvitation = {
        familyId,
        invitedByUserId: inviterId,
        invitedByDisplayName,
        invitedEmail: normalizedEmail,
        invitedUserId, // ya existe
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

    // ---- Escenario 2: NO registrado (passwordless email link + extensión /mail) ----
    if (isUnregisteredUserEmail) {
      const normalizedEmail = normalizeEmail(emailOrName);

      // Confirma que no exista ya un usuario
      const existing = await db.collection("users").where("email", "==", normalizedEmail).limit(1).get();
      if (!existing.empty) {
        throw new functions.https.HttpsError(
          "already-exists",
          "Este correo corresponde a un usuario registrado. Invítalo como usuario registrado."
        );
      }

      const invitationId = db.collection("invitations").doc().id;
      const invitationCode = generateInvitationCode();

      const newInvitation = {
        familyId,
        invitedByUserId: inviterId,
        invitedByDisplayName,
        invitedEmail: normalizedEmail,
        invitedUserId: null, // aún no hay UID
        initialRole: initialRole || "child",
        initialRelationshipType: initialRelationshipType || "other",
        status: "pending", // unificado
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 7 * 24 * 60 * 60 * 1000),
        invitationCode, // SIEMPRE presente
      };
      batch.set(db.collection("invitations").doc(invitationId), newInvitation);

      // Genera passwordless link con continue URL que incluye el invitationCode
      const actionCodeSettings = {
        url: `https://healthy-families-dev.web.app/join?invitationCode=${invitationCode}`,
        handleCodeInApp: true,
      };
      const link = await admin.auth().generateSignInWithEmailLink(normalizedEmail, actionCodeSettings);

      // Dispara la extensión Trigger Email (OAuth2) escribiendo en /mail
      batch.set(db.collection("mail").doc(), {
        to: [normalizedEmail],
        message: {
          subject: "¡Has sido invitado a unirte a una familia en Healthy Families!",
          html: `<p>Hola,</p>
                 <p>Has sido invitado a unirte a una familia.</p>
                 <p>Usa este enlace para continuar de forma segura: <a href="${link}">Aceptar invitación</a></p>
                 <p>Código de invitación: <b>${invitationCode}</b> (por si necesitas ingresarlo manualmente)</p>`,
          text: `Has sido invitado a unirte a una familia. Acepta aquí: ${link}\nCódigo: ${invitationCode}`,
        },
      });

      // En pending guardamos el email (no hay UID aún)
      batch.update(familyRef, {
        usersPending: admin.firestore.FieldValue.arrayUnion(normalizedEmail),
      });

      await batch.commit();
      return { status: "success", message: "Invitación enviada a persona no registrada (email link)." };
    }

    // ---------------------- Escenario 3: miembro no registrado ----------------------
    const memberId = uuidv4();
    const unregisteredMember = {
      memberId,
      name: emailOrName, // aquí es nombre
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

// ================================= joinFamily =================================

/**
 * Acepta la invitación por `invitationCode`.
 * Reglas:
 * - Invitación debe estar en `status: "pending"` y no expirada.
 * - Si existe `invitedUserId`, debe coincidir con el `uid` actual.
 * - Si NO existe `invitedUserId`, debe coincidir el email del usuario autenticado con `invitedEmail` (normalizado).
 * - Mueve de `usersPending` a `memberUserIds` y limpia por uid/email.
 * - Marca la invitación como `accepted` y, si no tenía `invitedUserId`, lo setea.
 * - Crea relación inicial idempotente en `/familyRelationships`.
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
    const inv = invitationDoc.data() as any;

    // 2) Validar estado/expiración
    if (inv.status !== "pending") {
      throw new functions.https.HttpsError("failed-precondition", "La invitación no está disponible.");
    }
    if (isTimestampExpired(inv.expiresAt)) {
      throw new functions.https.HttpsError("failed-precondition", "La invitación ha expirado.");
    }

    // 3) Cargar usuario y familia
    const [userSnap, familySnap] = await Promise.all([
      db.collection("users").doc(userId).get(),
      db.collection("families").doc(inv.familyId).get(),
    ]);

    if (!userSnap.exists) {
      throw new functions.https.HttpsError("not-found", "Perfil de usuario no encontrado.");
    }
    if (!familySnap.exists) {
      throw new functions.https.HttpsError("not-found", "Familia no encontrada.");
    }

    const user = userSnap.data() as any;
    const userEmail = user?.email ? normalizeEmail(String(user.email)) : "";
    if (!userEmail) {
      throw new functions.https.HttpsError("failed-precondition", "El usuario no tiene email registrado.");
    }

    // 4) Validar destinatario
    if (inv.invitedUserId && inv.invitedUserId !== userId) {
      throw new functions.https.HttpsError("permission-denied", "La invitación no corresponde a este usuario.");
    }
    if (!inv.invitedUserId) {
      const invitedEmail = inv.invitedEmail ? normalizeEmail(String(inv.invitedEmail)) : "";
      if (!invitedEmail || invitedEmail !== userEmail) {
        throw new functions.https.HttpsError("permission-denied", "La invitación no corresponde a este email.");
      }
    }

    const familyData = (familySnap.data() || {}) as FamilyDoc;
    const memberUserIds = Array.isArray(familyData.memberUserIds) ? familyData.memberUserIds : [];
    const usersPending = Array.isArray(familyData.usersPending) ? familyData.usersPending : [];

    // 5) Evitar duplicados
    if (memberUserIds.includes(userId)) {
      throw new functions.https.HttpsError("already-exists", "Ya eres miembro de esta familia.");
    }

    // 6) Actualizaciones atómicas
    const batch = db.batch();
    const updatedMemberUserIds = [...memberUserIds, userId];
    const updatedUsersPending = usersPending.filter(
      (x) => x !== userId && (typeof x !== "string" || normalizeEmail(x) !== userEmail)
    );

    batch.update(familySnap.ref, {
      memberUserIds: updatedMemberUserIds,
      usersPending: updatedUsersPending,
    });

    batch.update(userSnap.ref, {
      familyIds: admin.firestore.FieldValue.arrayUnion(inv.familyId),
    });

    const invitationUpdate: any = { status: "accepted" };
    if (!inv.invitedUserId) {
      invitationUpdate.invitedUserId = userId;
    }
    batch.update(invitationDoc.ref, invitationUpdate);

    // 7) Relación inicial idempotente
    const member1Id = inv.invitedByUserId;
    const member2Id = userId;

    const [q1, q2] = await Promise.all([
      db.collection("familyRelationships")
        .where("familyId", "==", inv.familyId)
        .where("member1Ref.id", "==", member1Id)
        .where("member2Ref.id", "==", member2Id)
        .limit(1)
        .get(),
      db.collection("familyRelationships")
        .where("familyId", "==", inv.familyId)
        .where("member1Ref.id", "==", member2Id)
        .where("member2Ref.id", "==", member1Id)
        .limit(1)
        .get(),
    ]);

    if (q1.empty && q2.empty) {
      const relationshipId = db.collection("familyRelationships").doc().id;
      batch.set(db.collection("familyRelationships").doc(relationshipId), {
        familyId: inv.familyId,
        member1Ref: { type: "user", id: member1Id },
        member2Ref: { type: "user", id: member2Id },
        relationshipType: inv.initialRelationshipType || "other",
        dynamicType: "initial_connection",
        description: "Relación inicial establecida al unirse a la familia.",
        frequency: 0.1,
        lastInteraction: admin.firestore.FieldValue.serverTimestamp(),
        iaConfidenceScore: 0.1,
        interactionCount: 1,
      });
    }

    await batch.commit();
    return { status: "success", message: "¡Te has unido a la familia con éxito!", familyId: inv.familyId };
  }
);
