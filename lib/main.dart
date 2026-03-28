import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/plan_service.dart';
import 'services/session_service.dart';
import 'services/settings_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
  runApp(const PowerLogApp());
}

class PowerLogApp extends StatelessWidget {
  const PowerLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => SessionService()),
        ChangeNotifierProvider(create: (_) => PlanService()),
        ChangeNotifierProvider(create: (_) => SettingsService()),
      ],
      child: MaterialApp(
        title: 'PowerLog',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE53935),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF0D0D0D),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0D0D0D),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
