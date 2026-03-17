import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/main_shell.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await NotificationService.instance.init();
  await AuthService.instance.init();

  final autoLoggedIn = await AuthService.instance.tryAutoLogin();

  runApp(KalpSagligiApp(isLoggedIn: autoLoggedIn));
}

class KalpSagligiApp extends StatelessWidget {
  final bool isLoggedIn;
  const KalpSagligiApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kalp Sağlığı',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: isLoggedIn ? const MainShell() : const LoginScreen(),
    );
  }
}
