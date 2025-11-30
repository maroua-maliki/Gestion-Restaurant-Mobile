const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

// --- FONCTION DE CRÉATION ---
exports.createUser = onCall(async (request) => {
  if (!request.auth) { throw new HttpsError("unauthenticated", "Vous devez être authentifié."); }
  const { email, password, displayName, role } = request.data;
  if (!email || !password || !displayName || !role) { throw new HttpsError("invalid-argument", "Informations manquantes."); }
  try {
    const userRecord = await admin.auth().createUser({ email, password, displayName });
    await admin.firestore().collection("users").doc(userRecord.uid).set({ 
      displayName, 
      email, 
      role, 
      isActive: true, 
      deleted_at: null
    });
    await admin.auth().setCustomUserClaims(userRecord.uid, { role });
    return { result: `Utilisateur ${displayName} créé.` };
  } catch (error) {
    console.error("Erreur création:", error);
    throw new HttpsError("internal", "Erreur interne du serveur.");
  }
});

// --- FONCTION DE MODIFICATION ---
exports.updateUser = onCall(async (request) => {
  if (!request.auth) { throw new HttpsError("unauthenticated", "Vous devez être authentifié."); }
  const { uid, email, displayName, role } = request.data;
  if (!uid || !email || !displayName || !role) { throw new HttpsError("invalid-argument", "Informations manquantes."); }
  try {
    await admin.auth().updateUser(uid, { email, displayName });
    await admin.firestore().collection("users").doc(uid).update({ email, displayName, role });
    await admin.auth().setCustomUserClaims(uid, { role });
    return { result: `Utilisateur ${displayName} mis à jour.` };
  } catch (error) {
    console.error("Erreur mise à jour:", error);
    throw new HttpsError("internal", "Erreur interne du serveur.");
  }
});

// --- FONCTION POUR ACTIVER/DÉSACTIVER ---
exports.toggleUserStatus = onCall(async (request) => {
  if (!request.auth) { throw new HttpsError("unauthenticated", "Vous devez être authentifié."); }
  const { uid, isActive } = request.data;
  if (uid == null || isActive == null) { throw new HttpsError("invalid-argument", "Informations manquantes."); }
  try {
    await admin.auth().updateUser(uid, { disabled: !isActive });
    await admin.firestore().collection("users").doc(uid).update({ isActive: isActive });
    if (!isActive) {
      const tablesQuery = await admin.firestore().collection('tables').where('assignedServerId', '==', uid).get();
      const batch = admin.firestore().batch();
      tablesQuery.docs.forEach(doc => { batch.update(doc.ref, { assignedServerId: null }); });
      await batch.commit();
    }
    return { result: `Statut de l'utilisateur mis à jour.` };
  } catch (error) {
    console.error("Erreur changement de statut:", error);
    throw new HttpsError("internal", "Erreur interne du serveur.");
  }
});

// --- FONCTION DE SUPPRESSION LOGIQUE (CORRIGÉE) ---
exports.deleteUser = onCall(async (request) => {
  if (!request.auth) { throw new HttpsError("unauthenticated", "Vous devez être authentifié."); }
  const { uid } = request.data;
  if (!uid) { throw new HttpsError("invalid-argument", "UID manquant."); }
  try {
    await admin.auth().updateUser(uid, { disabled: true });
    // La ligne correcte pour la suppression logique
    await admin.firestore().collection("users").doc(uid).update({ 
      isActive: false,
      deleted_at: admin.firestore.FieldValue.serverTimestamp()
    });
    const tablesQuery = await admin.firestore().collection('tables').where('assignedServerId', '==', uid).get();
    const batch = admin.firestore().batch();
    tablesQuery.docs.forEach(doc => { batch.update(doc.ref, { assignedServerId: null }); });
    await batch.commit();
    return { result: `Utilisateur archivé avec succès.` };
  } catch (error) {
    console.error("Erreur lors de la suppression logique:", error);
    throw new HttpsError("internal", "Erreur interne du serveur.");
  }
});
