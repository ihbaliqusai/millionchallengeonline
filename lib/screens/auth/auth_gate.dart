import 'package:flutter/material.dart';
import 'package:millionaire_flutter_exact/screens/home/home_screen.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import 'login_screen.dart';
import 'offline_welcome_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (appState.user == null) {
          return appState.isOnline
              ? const LoginScreen()
              : const OfflineWelcomeScreen();
        }
        return const HomeScreen();
      },
    );
  }
}
