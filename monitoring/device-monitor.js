const admin = require('firebase-admin');
const mqtt = require('mqtt');
const cron = require('node-cron');

// Configuration Firebase
const serviceAccount = require('./firebase-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: process.env.FIREBASE_DATABASE_URL
});

const db = admin.firestore();

// Configuration MQTT
const mqttClient = mqtt.connect(process.env.MQTT_BROKER_URL, {
  username: process.env.MQTT_USERNAME,
  password: process.env.MQTT_PASSWORD,
  clientId: 'pet-smart-monitor-' + Math.random().toString(16).substr(2, 8)
});

// Topics MQTT à surveiller
const TOPICS = {
  HEARTBEAT: 'pet-smart-home/+/heartbeat',
  STATUS: 'pet-smart-home/+/status',
  ERROR: 'pet-smart-home/+/error',
  FEEDING: 'pet-smart-home/+/feeding',
  ACCESS: 'pet-smart-home/+/access'
};

// Base de données des appareils connectés
const connectedDevices = new Map();
const deviceAlerts = new Map();

// Connexion MQTT
mqttClient.on('connect', () => {
  console.log('🔗 Connecté au broker MQTT');
  
  // S'abonner aux topics
  Object.values(TOPICS).forEach(topic => {
    mqttClient.subscribe(topic, (err) => {
      if (err) {
        console.error(`❌ Erreur d'abonnement au topic ${topic}:`, err);
      } else {
        console.log(`✅ Abonné au topic: ${topic}`);
      }
    });
  });
});

// Traitement des messages MQTT
mqttClient.on('message', async (topic, message) => {
  try {
    const data = JSON.parse(message.toString());
    const deviceId = extractDeviceId(topic);
    
    // Mettre à jour le statut de l'appareil
    updateDeviceStatus(deviceId, data);
    
    // Traiter selon le type de message
    if (topic.includes('heartbeat')) {
      await handleHeartbeat(deviceId, data);
    } else if (topic.includes('status')) {
      await handleStatusUpdate(deviceId, data);
    } else if (topic.includes('error')) {
      await handleError(deviceId, data);
    } else if (topic.includes('feeding')) {
      await handleFeedingEvent(deviceId, data);
    } else if (topic.includes('access')) {
      await handleAccessEvent(deviceId, data);
    }
    
  } catch (error) {
    console.error('❌ Erreur de traitement du message MQTT:', error);
  }
});

// Extraire l'ID de l'appareil du topic
function extractDeviceId(topic) {
  const parts = topic.split('/');
  return parts[1]; // pet-smart-home/{deviceId}/...
}

// Mettre à jour le statut de l'appareil
function updateDeviceStatus(deviceId, data) {
  connectedDevices.set(deviceId, {
    lastSeen: new Date(),
    status: 'online',
    data: data
  });
}

// Gérer les heartbeats
async function handleHeartbeat(deviceId, data) {
  console.log(`💓 Heartbeat reçu de ${deviceId}`);
  
  try {
    await db.collection('device_status').doc(deviceId).set({
      lastHeartbeat: admin.firestore.FieldValue.serverTimestamp(),
      status: 'online',
      batteryLevel: data.batteryLevel || null,
      wifiSignal: data.wifiSignal || null,
      freeMemory: data.freeMemory || null,
      uptime: data.uptime || null
    }, { merge: true });
    
    // Supprimer les alertes de déconnexion si l'appareil est de retour
    if (deviceAlerts.has(deviceId)) {
      deviceAlerts.delete(deviceId);
      await sendNotification(deviceId, 'device_reconnected', {
        message: `L'appareil ${deviceId} est de nouveau en ligne`
      });
    }
    
  } catch (error) {
    console.error(`❌ Erreur lors de la sauvegarde du heartbeat pour ${deviceId}:`, error);
  }
}

// Gérer les mises à jour de statut
async function handleStatusUpdate(deviceId, data) {
  console.log(`📊 Mise à jour de statut pour ${deviceId}:`, data);
  
  try {
    await db.collection('device_status').doc(deviceId).update({
      lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
      ...data
    });
    
    // Vérifier les seuils d'alerte
    await checkAlertThresholds(deviceId, data);
    
  } catch (error) {
    console.error(`❌ Erreur lors de la mise à jour du statut pour ${deviceId}:`, error);
  }
}

// Gérer les erreurs
async function handleError(deviceId, data) {
  console.error(`🚨 Erreur signalée par ${deviceId}:`, data);
  
  try {
    // Enregistrer l'erreur
    await db.collection('device_errors').add({
      deviceId,
      error: data,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      resolved: false
    });
    
    // Envoyer une notification d'alerte
    await sendNotification(deviceId, 'device_error', {
      message: `Erreur détectée sur l'appareil ${deviceId}: ${data.message}`,
      severity: data.severity || 'medium'
    });
    
  } catch (error) {
    console.error(`❌ Erreur lors de l'enregistrement de l'erreur pour ${deviceId}:`, error);
  }
}

// Gérer les événements de distribution
async function handleFeedingEvent(deviceId, data) {
  console.log(`🍽️ Événement de distribution pour ${deviceId}:`, data);
  
  try {
    await db.collection('feeding_logs').add({
      deviceId,
      petId: data.petId,
      amount: data.amount,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      success: data.success,
      remainingFood: data.remainingFood
    });
    
    // Vérifier le niveau de nourriture
    if (data.remainingFood && data.remainingFood < 10) {
      await sendNotification(deviceId, 'low_food', {
        message: `Niveau de nourriture bas pour l'appareil ${deviceId}: ${data.remainingFood}%`
      });
    }
    
  } catch (error) {
    console.error(`❌ Erreur lors de l'enregistrement de la distribution pour ${deviceId}:`, error);
  }
}

// Gérer les événements d'accès
async function handleAccessEvent(deviceId, data) {
  console.log(`🚪 Événement d'accès pour ${deviceId}:`, data);
  
  try {
    await db.collection('access_logs').add({
      deviceId,
      petId: data.petId,
      accessType: data.accessType, // 'granted', 'denied', 'unknown'
      method: data.method, // 'rfid', 'bluetooth', 'manual'
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // Alerte pour accès refusé
    if (data.accessType === 'denied') {
      await sendNotification(deviceId, 'access_denied', {
        message: `Accès refusé sur l'appareil ${deviceId}`
      });
    }
    
  } catch (error) {
    console.error(`❌ Erreur lors de l'enregistrement de l'accès pour ${deviceId}:`, error);
  }
}

// Vérifier les seuils d'alerte
async function checkAlertThresholds(deviceId, data) {
  const alerts = [];
  
  // Batterie faible
  if (data.batteryLevel && data.batteryLevel < 20) {
    alerts.push({
      type: 'low_battery',
      message: `Batterie faible pour ${deviceId}: ${data.batteryLevel}%`
    });
  }
  
  // Signal WiFi faible
  if (data.wifiSignal && data.wifiSignal < -70) {
    alerts.push({
      type: 'weak_wifi',
      message: `Signal WiFi faible pour ${deviceId}: ${data.wifiSignal} dBm`
    });
  }
  
  // Mémoire faible
  if (data.freeMemory && data.freeMemory < 10000) {
    alerts.push({
      type: 'low_memory',
      message: `Mémoire faible pour ${deviceId}: ${data.freeMemory} bytes`
    });
  }
  
  // Envoyer les alertes
  for (const alert of alerts) {
    await sendNotification(deviceId, alert.type, { message: alert.message });
  }
}

// Envoyer une notification
async function sendNotification(deviceId, type, data) {
  try {
    await db.collection('notifications').add({
      deviceId,
      type,
      data,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      read: false
    });
    
    console.log(`📢 Notification envoyée pour ${deviceId}: ${type}`);
    
  } catch (error) {
    console.error(`❌ Erreur lors de l'envoi de la notification:`, error);
  }
}

// Tâche cron pour vérifier les appareils déconnectés
cron.schedule('*/5 * * * *', async () => {
  console.log('🔍 Vérification des appareils déconnectés...');
  
  const now = new Date();
  const offlineThreshold = 10 * 60 * 1000; // 10 minutes
  
  for (const [deviceId, device] of connectedDevices.entries()) {
    const timeSinceLastSeen = now - device.lastSeen;
    
    if (timeSinceLastSeen > offlineThreshold) {
      // Marquer l'appareil comme hors ligne
      try {
        await db.collection('device_status').doc(deviceId).update({
          status: 'offline',
          lastSeen: admin.firestore.Timestamp.fromDate(device.lastSeen)
        });
        
        // Envoyer une alerte si pas déjà envoyée
        if (!deviceAlerts.has(deviceId)) {
          await sendNotification(deviceId, 'device_offline', {
            message: `L'appareil ${deviceId} est hors ligne depuis ${Math.round(timeSinceLastSeen / 60000)} minutes`
          });
          deviceAlerts.set(deviceId, now);
        }
        
        // Supprimer de la liste des appareils connectés
        connectedDevices.delete(deviceId);
        
      } catch (error) {
        console.error(`❌ Erreur lors de la mise à jour du statut hors ligne pour ${deviceId}:`, error);
      }
    }
  }
});

// Tâche cron pour les statistiques quotidiennes
cron.schedule('0 0 * * *', async () => {
  console.log('📊 Génération des statistiques quotidiennes...');
  
  try {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(0, 0, 0, 0);
    
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    // Statistiques de distribution
    const feedingSnapshot = await db.collection('feeding_logs')
      .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(yesterday))
      .where('timestamp', '<', admin.firestore.Timestamp.fromDate(today))
      .get();
    
    // Statistiques d'accès
    const accessSnapshot = await db.collection('access_logs')
      .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(yesterday))
      .where('timestamp', '<', admin.firestore.Timestamp.fromDate(today))
      .get();
    
    // Sauvegarder les statistiques
    await db.collection('daily_stats').doc(yesterday.toISOString().split('T')[0]).set({
      date: admin.firestore.Timestamp.fromDate(yesterday),
      totalFeedings: feedingSnapshot.size,
      totalAccess: accessSnapshot.size,
      activeDevices: connectedDevices.size,
      generatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log(`✅ Statistiques générées pour ${yesterday.toDateString()}`);
    
  } catch (error) {
    console.error('❌ Erreur lors de la génération des statistiques:', error);
  }
});

// Gestion des erreurs MQTT
mqttClient.on('error', (error) => {
  console.error('❌ Erreur MQTT:', error);
});

mqttClient.on('offline', () => {
  console.warn('⚠️ Client MQTT hors ligne');
});

mqttClient.on('reconnect', () => {
  console.log('🔄 Reconnexion MQTT...');
});

console.log('🚀 Système de monitoring Pet Smart Home démarré');
console.log('📡 En attente des messages MQTT...');