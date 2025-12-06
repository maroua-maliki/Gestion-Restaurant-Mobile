    import {onDocumentUpdated} from "firebase-functions/v2/firestore";
    import * as admin from "firebase-admin";

    admin.initializeApp();

    // Seuil pour considérer une commande comme "nouvelle" (en minutes)
    const NOUVELLE_COMMANDE_SEUIL = 2;

    export const notifierStatutCommande = onDocumentUpdated("orders/{orderId}", async (event) => {
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
        const dateCreation = (apres.createdAt as admin.firestore.Timestamp).toDate();
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
          .filter((t): t is string => !!t);

        if (tokens.length === 0) {
          console.log("Aucun chef avec un token FCM.");
          return;
        }

        const payload: admin.messaging.MessagingPayload = {
          notification: {
            title: "Nouvelle Commande !",
            body: `La table ${apres.tableNumber ?? "à emporter"} attend.`,
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

        const token = userDoc.data()?.fcmToken;
        if (!token) {
          console.log(`Le serveur ${serveurId} n'a pas de token FCM.`);
          return;
        }

        const payload: admin.messaging.MessagingPayload = {
          notification: {
            title: "Commande Prête !",
            body: `La commande pour la table ${apres.tableNumber ?? "à emporter"} est prête.`,
            sound: "default",
          },
        };

        console.log(`Envoi de notif (commande prête) au token: ${token}`);
        await admin.messaging().sendToDevice(token, payload);
        return;
      }
    });
    