import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { HttpsError } from 'firebase-functions/v2/https';

// Initialisation Firebase Admin
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// Types
interface DeviceCommand {
  deviceId: string;
  command: {
    type: 'feed' | 'open_door' | 'close_door' | 'get_status' | 'update_config';
    payload?: any;
  };
  timestamp: admin.firestore.Timestamp;
  status: 'pending' | 'sent' | 'acknowledged' | 'failed';
  userId: string;
}

interface AccessLog {
  deviceId: string;
  petId?: string;
  direction: 'entry' | 'exit';
  method: 'rfid' | 'ble' | 'manual' | 'scheduled';
  status: 'success' | 'denied' | 'error' | 'timeout';
  timestamp: admin.firestore.Timestamp;
  rfidTag?: string;
  bleMacAddress?: string;
  errorMessage?: string;
}

interface FeedingLog {
  deviceId: string;
  petId?: string;
  amount: number;
  scheduledAmount?: number;
  timestamp: admin.firestore.Timestamp;
  status: 'success' | 'failed' | 'partial';
  errorMessage?: string;
}

// Cloud Function: Traitement des commandes d'appareils
export const processDeviceCommand = onDocumentCreated(
  'device_commands/{commandId}',
  async (event) => {
    const commandData = event.data?.data() as DeviceCommand;
    const commandId = event.params.commandId;

    if (!commandData) {
      console.error('Aucune donnée de commande trouvée');
      return;
    }

    try {
      // Publier la commande via MQTT (simulation)
      console.log(`Envoi de la commande ${commandData.command.type} à l'appareil ${commandData.deviceId}`);
      
      // Mettre à jour le statut de la commande
      await db.collection('device_commands').doc(commandId).update({
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Envoyer une notification à l'utilisateur
      await sendNotificationToUser(
        commandData.userId,
        'Commande envoyée',
        `La commande ${commandData.command.type} a été envoyée à votre appareil.`,
        { commandId, deviceId: commandData.deviceId }
      );

    } catch (error) {
      console.error('Erreur lors du traitement de la commande:', error);
      
      // Marquer la commande comme échouée
      await db.collection('device_commands').doc(commandId).update({
        status: 'failed',
        error: error instanceof Error ? error.message : 'Erreur inconnue',
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
);

// Cloud Function: Traitement des logs d'accès
export const processAccessLog = onDocumentCreated(
  'access_logs/{logId}',
  async (event) => {
    const logData = event.data?.data() as AccessLog;

    if (!logData) return;

    try {
      // Trouver le propriétaire de l'appareil
      const deviceQuery = await db.collectionGroup('devices')
        .where('id', '==', logData.deviceId)
        .limit(1)
        .get();

      if (deviceQuery.empty) {
        console.error(`Appareil ${logData.deviceId} non trouvé`);
        return;
      }

      const deviceDoc = deviceQuery.docs[0];
      const userId = deviceDoc.ref.parent.parent?.id;

      if (!userId) {
        console.error('Impossible de déterminer le propriétaire de l\'appareil');
        return;
      }

      // Envoyer une notification selon le statut
      let title = '';
      let body = '';
      let priority: 'normal' | 'high' = 'normal';

      switch (logData.status) {
        case 'success':
          title = `Accès ${logData.direction === 'entry' ? 'autorisé' : 'sortie'}`;
          body = logData.petId 
            ? `Votre animal a ${logData.direction === 'entry' ? 'entré' : 'quitté'} la maison`
            : `Accès ${logData.direction === 'entry' ? 'entrant' : 'sortant'} détecté`;
          break;
        case 'denied':
          title = 'Accès refusé';
          body = 'Tentative d\'accès non autorisée détectée';
          priority = 'high';
          break;
        case 'error':
        case 'timeout':
          title = 'Erreur d\'accès';
          body = logData.errorMessage || 'Erreur lors de la tentative d\'accès';
          priority = 'high';
          break;
      }

      await sendNotificationToUser(userId, title, body, {
        type: 'access_log',
        logId: event.params.logId,
        deviceId: logData.deviceId,
        status: logData.status,
      }, priority);

      // Mettre à jour les statistiques
      await updateAccessStatistics(userId, logData.deviceId, logData);

    } catch (error) {
      console.error('Erreur lors du traitement du log d\'accès:', error);
    }
  }
);

// Cloud Function: Traitement des logs de distribution
export const processFeedingLog = onDocumentCreated(
  'feeding_logs/{logId}',
  async (event) => {
    const logData = event.data?.data() as FeedingLog;

    if (!logData) return;

    try {
      // Trouver le propriétaire de l'appareil
      const deviceQuery = await db.collectionGroup('devices')
        .where('id', '==', logData.deviceId)
        .limit(1)
        .get();

      if (deviceQuery.empty) return;

      const deviceDoc = deviceQuery.docs[0];
      const userId = deviceDoc.ref.parent.parent?.id;

      if (!userId) return;

      // Envoyer une notification
      let title = '';
      let body = '';

      switch (logData.status) {
        case 'success':
          title = 'Distribution réussie';
          body = `${logData.amount}g de nourriture distribués`;
          break;
        case 'failed':
          title = 'Échec de distribution';
          body = logData.errorMessage || 'Erreur lors de la distribution';
          break;
        case 'partial':
          title = 'Distribution partielle';
          body = `Seulement ${logData.amount}g distribués sur ${logData.scheduledAmount}g prévus`;
          break;
      }

      await sendNotificationToUser(userId, title, body, {
        type: 'feeding_log',
        logId: event.params.logId,
        deviceId: logData.deviceId,
        status: logData.status,
      });

      // Mettre à jour les statistiques de distribution
      await updateFeedingStatistics(userId, logData.deviceId, logData);

    } catch (error) {
      console.error('Erreur lors du traitement du log de distribution:', error);
    }
  }
);

// Cloud Function: Surveillance des appareils hors ligne
export const checkOfflineDevices = onSchedule('every 5 minutes', async () => {
  try {
    const fiveMinutesAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 5 * 60 * 1000)
    );

    // Trouver tous les appareils qui n'ont pas donné signe de vie depuis 5 minutes
    const offlineDevicesQuery = await db.collectionGroup('devices')
      .where('lastSeen', '<', fiveMinutesAgo)
      .where('status', '!=', 'offline')
      .get();

    const batch = db.batch();
    const notifications: Promise<void>[] = [];

    for (const deviceDoc of offlineDevicesQuery.docs) {
      const deviceData = deviceDoc.data();
      const userId = deviceDoc.ref.parent.parent?.id;

      if (!userId) continue;

      // Marquer l'appareil comme hors ligne
      batch.update(deviceDoc.ref, {
        status: 'offline',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Programmer une notification
      notifications.push(
        sendNotificationToUser(
          userId,
          'Appareil hors ligne',
          `${deviceData.name} ne répond plus depuis plus de 5 minutes`,
          {
            type: 'device_offline',
            deviceId: deviceData.id,
          },
          'high'
        )
      );
    }

    // Exécuter toutes les mises à jour
    if (!offlineDevicesQuery.empty) {
      await batch.commit();
      await Promise.all(notifications);
    }

    console.log(`${offlineDevicesQuery.size} appareils marqués comme hors ligne`);

  } catch (error) {
    console.error('Erreur lors de la vérification des appareils hors ligne:', error);
  }
});

// Cloud Function: Nettoyage des anciens logs
export const cleanupOldLogs = onSchedule('every 24 hours', async () => {
  try {
    const thirtyDaysAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
    );

    // Nettoyer les logs d'accès anciens
    const oldAccessLogs = await db.collection('access_logs')
      .where('timestamp', '<', thirtyDaysAgo)
      .limit(500)
      .get();

    const accessBatch = db.batch();
    oldAccessLogs.docs.forEach(doc => {
      accessBatch.delete(doc.ref);
    });

    if (!oldAccessLogs.empty) {
      await accessBatch.commit();
    }

    // Nettoyer les logs de distribution anciens
    const oldFeedingLogs = await db.collection('feeding_logs')
      .where('timestamp', '<', thirtyDaysAgo)
      .limit(500)
      .get();

    const feedingBatch = db.batch();
    oldFeedingLogs.docs.forEach(doc => {
      feedingBatch.delete(doc.ref);
    });

    if (!oldFeedingLogs.empty) {
      await feedingBatch.commit();
    }

    console.log(`Nettoyage terminé: ${oldAccessLogs.size} logs d'accès et ${oldFeedingLogs.size} logs de distribution supprimés`);

  } catch (error) {
    console.error('Erreur lors du nettoyage des logs:', error);
  }
});

// Fonction utilitaire: Envoyer une notification à un utilisateur
async function sendNotificationToUser(
  userId: string,
  title: string,
  body: string,
  data: Record<string, any> = {},
  priority: 'normal' | 'high' = 'normal'
): Promise<void> {
  try {
    // Récupérer le token FCM de l'utilisateur
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.data();

    if (!userData?.fcmToken) {
      console.log(`Aucun token FCM trouvé pour l'utilisateur ${userId}`);
      return;
    }

    // Envoyer la notification
    const message = {
      token: userData.fcmToken,
      notification: {
        title,
        body,
      },
      data: {
        ...data,
        timestamp: Date.now().toString(),
      },
      android: {
        priority: priority as 'normal' | 'high',
        notification: {
          channelId: 'pet_smart_home_notifications',
          priority: priority as 'default_' | 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title,
              body,
            },
            badge: 1,
            sound: 'default',
          },
        },
      },
    };

    await messaging.send(message);

    // Sauvegarder la notification dans Firestore
    await db.collection('notifications').add({
      userId,
      title,
      body,
      data,
      read: false,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

  } catch (error) {
    console.error('Erreur lors de l\'envoi de la notification:', error);
  }
}

// Fonction utilitaire: Mettre à jour les statistiques d'accès
async function updateAccessStatistics(
  userId: string,
  deviceId: string,
  logData: AccessLog
): Promise<void> {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const statsId = `${deviceId}_${today.getTime()}`;

    const statsRef = db.collection('statistics').doc(statsId);
    
    await db.runTransaction(async (transaction) => {
      const statsDoc = await transaction.get(statsRef);
      
      if (statsDoc.exists) {
        const stats = statsDoc.data()!;
        transaction.update(statsRef, {
          totalAccesses: stats.totalAccesses + 1,
          [`${logData.status}Count`]: (stats[`${logData.status}Count`] || 0) + 1,
          [`${logData.direction}Count`]: (stats[`${logData.direction}Count`] || 0) + 1,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(statsRef, {
          userId,
          deviceId,
          date: admin.firestore.Timestamp.fromDate(today),
          totalAccesses: 1,
          successCount: logData.status === 'success' ? 1 : 0,
          deniedCount: logData.status === 'denied' ? 1 : 0,
          errorCount: ['error', 'timeout'].includes(logData.status) ? 1 : 0,
          entryCount: logData.direction === 'entry' ? 1 : 0,
          exitCount: logData.direction === 'exit' ? 1 : 0,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    });

  } catch (error) {
    console.error('Erreur lors de la mise à jour des statistiques d\'accès:', error);
  }
}

// Fonction utilitaire: Mettre à jour les statistiques de distribution
async function updateFeedingStatistics(
  userId: string,
  deviceId: string,
  logData: FeedingLog
): Promise<void> {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const statsId = `${deviceId}_feeding_${today.getTime()}`;

    const statsRef = db.collection('statistics').doc(statsId);
    
    await db.runTransaction(async (transaction) => {
      const statsDoc = await transaction.get(statsRef);
      
      if (statsDoc.exists) {
        const stats = statsDoc.data()!;
        transaction.update(statsRef, {
          totalFeedings: stats.totalFeedings + 1,
          totalAmount: stats.totalAmount + logData.amount,
          [`${logData.status}Count`]: (stats[`${logData.status}Count`] || 0) + 1,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(statsRef, {
          userId,
          deviceId,
          date: admin.firestore.Timestamp.fromDate(today),
          totalFeedings: 1,
          totalAmount: logData.amount,
          successCount: logData.status === 'success' ? 1 : 0,
          failedCount: logData.status === 'failed' ? 1 : 0,
          partialCount: logData.status === 'partial' ? 1 : 0,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    });

  } catch (error) {
    console.error('Erreur lors de la mise à jour des statistiques de distribution:', error);
  }
}