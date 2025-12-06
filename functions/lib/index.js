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
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.notifierStatutCommande = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
// Seuil pour considérer une commande comme "nouvelle" (en minutes)
const NOUVELLE_COMMANDE_SEUIL = 2;
exports.notifierStatutCommande = (0, firestore_1.onDocumentUpdated)("orders/{orderId}", async (event) => {
    var _a, _b, _c;
    if (!event.data) {
        console.log("Pas de données associées à l'événement.");
        return;
    }
    const avant = event.data.before.data();
    const apres = event.data.after.data();
    // Si le statut n'a pas changé, on ne fait rien
    if (avant.status === apres.status) {
        return;
    }
    const orderId = event.params.orderId;
    console.log(`Changement de statut pour la commande ${orderId}: ${avant.status} -> ${apres.status}`);
    // --- Scénario 1 : Nouvelle commande pour le Chef ---
    if (apres.status === "pending") {
        const dateCreation = apres.createdAt.toDate();
        const maintenant = new Date();
        const differenceMinutes = (maintenant.getTime() - dateCreation.getTime()) / (1000 * 60);
        if (differenceMinutes > NOUVELLE_COMMANDE_SEUIL) {
            console.log("Ancienne commande passée à 'pending', pas de notif.");
            return;
        }
        const chefsSnapshot = await admin.firestore().collection("users")
            .where("role", "==", "Chef")
            .where("isActive", "==", true)
            .get();
        if (chefsSnapshot.empty) {
            console.log("Aucun chef actif trouvé.");
            return;
        }
        const tokens = chefsSnapshot.docs
            .map((doc) => doc.data().fcmToken)
            .filter((t) => !!t);
        if (tokens.length === 0) {
            console.log("Aucun chef avec un token FCM.");
            return;
        }
        const payload = {
            notification: {
                title: "Nouvelle Commande !",
                body: `La table ${(_a = apres.tableNumber) !== null && _a !== void 0 ? _a : "à emporter"} attend.`,
                sound: "default",
            },
        };
        console.log(`Envoi de notif (nouvelle commande) aux tokens: ${tokens.join(", ")}`);
        await admin.messaging().sendToDevice(tokens, payload);
        return;
    }
    // --- Scénario 2 : Commande prête pour le Serveur ---
    if (apres.status === "ready") {
        const serveurId = apres.serverId;
        if (!serveurId) {
            console.log("Aucun serveur assigné à cette commande.");
            return;
        }
        const userDoc = await admin.firestore().collection("users").doc(serveurId).get();
        if (!userDoc.exists) {
            console.log(`Le document du serveur ${serveurId} n'existe pas.`);
            return;
        }
        const token = (_b = userDoc.data()) === null || _b === void 0 ? void 0 : _b.fcmToken;
        if (!token) {
            console.log(`Le serveur ${serveurId} n'a pas de token FCM.`);
            return;
        }
        const payload = {
            notification: {
                title: "Commande Prête !",
                body: `La commande pour la table ${(_c = apres.tableNumber) !== null && _c !== void 0 ? _c : "à emporter"} est prête.`,
                sound: "default",
            },
        };
        console.log(`Envoi de notif (commande prête) au token: ${token}`);
        await admin.messaging().sendToDevice(token, payload);
        return;
    }
});
//# sourceMappingURL=index.js.map