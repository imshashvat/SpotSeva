import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'injection_container.dart' as di;
import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init — graceful fallback if not yet configured
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('⚠️  Firebase not configured yet. Run: flutterfire configure');
    debugPrint('   Error: $e');
  }

  await di.init();
  runApp(const AdoptASpotApp());
}
