import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'app/providers.dart';
import 'features/notifications/services/push_ready.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Push notifications. Reads android/app/google-services.json. If it
  // fails the app still works, just without notifications.
  try {
    await Firebase.initializeApp();
    pushReady = true;
  } catch (error) {
    debugPrint('[push] Firebase failed to start: $error');
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const EventApp(),
    ),
  );
}
