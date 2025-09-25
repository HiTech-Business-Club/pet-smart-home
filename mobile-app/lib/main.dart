import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'config/app_config.dart';
import 'config/theme_config.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/dashboard_screen.dart';

// Handler pour les notifications en arrière-plan
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation Firebase
  await Firebase.initializeApp();
  
  // Initialisation Hive pour le stockage local
  await Hive.initFlutter();
  
  // Configuration des notifications
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(
    const ProviderScope(
      child: PetSmartHomeApp(),
    ),
  );
}

class PetSmartHomeApp extends ConsumerWidget {
  const PetSmartHomeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: ThemeConfig.lightTheme,
      darkTheme: ThemeConfig.darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return authState.when(
      data: (user) {
        if (user != null) {
          return const DashboardScreen();
        } else {
          return const LoginScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur d\'initialisation',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(authStateProvider);
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}