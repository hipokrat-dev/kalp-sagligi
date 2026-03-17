import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
