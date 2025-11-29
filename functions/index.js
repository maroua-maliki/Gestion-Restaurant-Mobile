const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

// --- FONCTION DE CRÉATION ---
exports.createUser = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Vous devez être authentifié.");
  }
  
  const email = request.data.email;
  const password = request.data.password;
  const displayName = request.data.displayName;
  const role = request.data.role;

  if (!email || !password || !displayName || !role) {
    throw new HttpsError("invalid-argument", "Informations manquantes.");
  }
  
  try {
    const userRecord = await admin.auth().createUser({ email, password, displayName });
    await admin.firestore().collection("users").doc(userRecord.uid).set({ displayName, email, role, isActive: true });
    await admin.auth().setCustomUserClaims(userRecord.uid, { role: role });
    return { result: `Utilisateur ${displayName} créé.` };
  } catch (error) {
    console.error("Erreur création utilisateur:", error);
    throw new HttpsError("internal", "Erreur interne du serveur.");
  }
});

// --- FONCTION DE MODIFICATION ---
exports.updateUser = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Vous devez être authentifié.");
  }

  const uid = request.data.uid;
  const email = request.data.email;
  const displayName = request.data.displayName;
  const role = request.data.role;

  if (!uid || !email || !displayName || !role) {
    throw new HttpsError("invalid-argument", "Informations de mise à jour manquantes.");
  }

  try {
    // Mise à jour de l'email et du nom dans Firebase Authentication
    await admin.auth().updateUser(uid, { email, displayName });

    // Mise à jour des infos dans Firestore
    await admin.firestore().collection("users").doc(uid).update({ email, displayName, role });

    // Mise à jour du rôle (custom claim)
    await admin.auth().setCustomUserClaims(uid, { role: role });

    return { result: `Utilisateur ${displayName} mis à jour.` };
  } catch (error) {
    console.error("Erreur mise à jour utilisateur:", error);
    throw new HttpsError("internal", "Erreur interne du serveur.");
  }
});

// --- FONCTION DE SUPPRESSION ---
exports.deleteUser = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Vous devez être authentifié.");
  }

  const uid = request.data.uid;
  if (!uid) {
    throw new HttpsError("invalid-argument", "UID manquant.");
  }

  try {
    await admin.auth().deleteUser(uid);
    await admin.firestore().collection("users").doc(uid).delete();
    return { result: `Utilisateur supprimé.` };
  } catch (error) {
    console.error("Erreur suppression utilisateur:", error);
    throw new HttpsError("internal", "Erreur interne du serveur.");
  }
});
