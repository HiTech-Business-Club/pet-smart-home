import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pet.dart';
import '../models/device.dart';
import '../models/feeding_schedule.dart';
import '../models/access_log.dart';

// Providers pour Firebase
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final messagingProvider = Provider<FirebaseMessaging>((ref) => FirebaseMessaging.instance);

// Provider pour l'état d'authentification
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// Provider pour le service Firebase
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    messaging: ref.watch(messagingProvider),
  );
});

class FirebaseService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  FirebaseService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required FirebaseMessaging messaging,
  })  : _auth = auth,
        _firestore = firestore,
        _messaging = messaging;

  // Authentification
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet email.';
      case 'weak-password':
        return 'Le mot de passe est trop faible.';
      case 'invalid-email':
        return 'L\'adresse email n\'est pas valide.';
      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard.';
      default:
        return 'Une erreur s\'est produite: ${e.message}';
    }
  }

  // Gestion des animaux
  Future<void> addPet(Pet pet) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Utilisateur non connecté');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(pet.id)
        .set(pet.toJson());
  }

  Future<void> updatePet(Pet pet) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Utilisateur non connecté');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(pet.id)
        .update(pet.toJson());
  }

  Future<void> deletePet(String petId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Utilisateur non connecté');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .doc(petId)
        .delete();
  }

  Stream<List<Pet>> getPets() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Pet.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Gestion des appareils
  Future<void> addDevice(Device device) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Utilisateur non connecté');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc(device.id)
        .set(device.toJson());
  }

  Future<void> updateDevice(Device device) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Utilisateur non connecté');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc(device.id)
        .update(device.toJson());
  }

  Stream<List<Device>> getDevices() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Device.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Gestion des horaires de repas
  Future<void> saveFeedingSchedule(String deviceId, FeedingSchedule schedule) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Utilisateur non connecté');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc(deviceId)
        .collection('feeding_schedules')
        .doc(schedule.id)
        .set(schedule.toJson());
  }

  Stream<List<FeedingSchedule>> getFeedingSchedules(String deviceId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc(deviceId)
        .collection('feeding_schedules')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedingSchedule.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Gestion des logs d'accès
  Future<void> addAccessLog(AccessLog log) async {
    await _firestore
        .collection('access_logs')
        .add(log.toJson());
  }

  Stream<List<AccessLog>> getAccessLogs(String deviceId, {int limit = 50}) {
    return _firestore
        .collection('access_logs')
        .where('deviceId', isEqualTo: deviceId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccessLog.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Gestion des notifications
  Future<String?> getFCMToken() async {
    return await _messaging.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  // Sauvegarde du token FCM pour l'utilisateur
  Future<void> saveFCMToken() async {
    final userId = _auth.currentUser?.uid;
    final token = await getFCMToken();
    
    if (userId != null && token != null) {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'fcmToken': token});
    }
  }

  // Envoi de commande à un appareil
  Future<void> sendDeviceCommand(String deviceId, Map<String, dynamic> command) async {
    await _firestore
        .collection('device_commands')
        .add({
          'deviceId': deviceId,
          'command': command,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
  }
}