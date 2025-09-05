"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.joinFamily = exports.inviteFamilyMember = void 0;
const functions = __importStar(require("firebase-functions/v2"));
const admin = __importStar(require("firebase-admin"));
const uuid_1 = require("uuid");
admin.initializeApp();
exports.inviteFamilyMember = functions.https.onCall(async (request) => {
    var _a, _b;
    const { familyId, emailOrName, isRegisteredUser, initialRole, initialRelationshipType, isDeceased, isPet, } = request.data;
    const inviterId = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
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
    if (!((_b = familyData === null || familyData === void 0 ? void 0 : familyData.adminUserIds) === null || _b === void 0 ? void 0 : _b.includes(inviterId))) {
        throw new functions.https.HttpsError("permission-denied", "Solo los administradores pueden invitar nuevos miembros.");
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
            throw new functions.https.HttpsError("not-found", "No se encontró ningún usuario registrado con ese correo electrónico.");
        }
        const invitedUserDoc = invitedUserQuery.docs[0];
        const invitedUserId = invitedUserDoc.id;
        // Verificar si ya es miembro o tiene una invitación pendiente
        if (familyData.memberUserIds.some((m) => m.userId === invitedUserId)) {
            throw new functions.https.HttpsError("already-exists", "Este usuario ya es miembro de la familia.");
        }
        if (familyData.usersPending.includes(invitedUserId)) {
            throw new functions.https.HttpsError("already-exists", "Ya existe una invitación pendiente para este usuario.");
        }
        const invitationCode = Math.random().toString(36).substring(2, 10).toUpperCase();
        const invitationId = db.collection("invitations").doc().id;
        const inviterProfile = (await db.collection("users").doc(inviterId).get()).data();
        const invitedByDisplayName = (inviterProfile === null || inviterProfile === void 0 ? void 0 : inviterProfile.displayName) || "Administrador";
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
        // Actualizar usersPending en el documento de la familia
        batch.update(familyRef, {
            usersPending: admin.firestore.FieldValue.arrayUnion(invitedUserId),
        });
    }
    else {
        // Escenario 2: Añadir un miembro no registrado (por nombre)
        // No requiere una cuenta de usuario en la app.
        const memberId = (0, uuid_1.v4)(); // Generar un ID único para el miembro no registrado
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
});
// =================================================================
// Cloud Function: joinFamily
// Permite a un usuario aceptar una invitación para unirse a una familia.
// =================================================================
exports.joinFamily = functions.https.onCall(async (request) => {
    var _a, _b;
    const { invitationCode } = request.data;
    const userId = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
    // 1. Autenticación del usuario
    if (!userId) {
        throw new functions.https.HttpsError("unauthenticated", "El usuario no está autenticado.");
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
        throw new functions.https.HttpsError("not-found", "Invitación no encontrada o ya no es válida.");
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
    const familyData = familyDoc.data();
    // 4. Validar que el usuario no sea ya un miembro
    if ((_b = familyData === null || familyData === void 0 ? void 0 : familyData.memberUserIds) === null || _b === void 0 ? void 0 : _b.some((m) => m.userId === userId)) {
        throw new functions.https.HttpsError("already-exists", "Ya eres miembro de esta familia.");
    }
    const batch = db.batch();
    // 5. Actualizar el documento de la familia:
    //    - Mover al usuario de 'usersPending' a 'memberUserIds'.
    //    - Corregido para añadir solo el UID al array.
    const updatedMemberUserIds = [...familyData.memberUserIds, userId]; // AHORA ES CORRECTO
    const updatedUsersPending = familyData.usersPending.filter((uid) => uid !== userId);
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
    }
    else {
        console.log("Ya existe una relación entre estos miembros, se omite la creación.");
    }
    // 9. Commit del lote de escrituras
    await batch.commit();
    return { status: "success", message: "¡Te has unido a la familia con éxito!", familyId };
});
//# sourceMappingURL=index.js.map