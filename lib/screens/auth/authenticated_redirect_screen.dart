import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';

class AuthenticatedRedirectScreen extends StatefulWidget {
  const AuthenticatedRedirectScreen({super.key});

  @override
  State<AuthenticatedRedirectScreen> createState() => _AuthenticatedRedirectScreenState();
}

class _AuthenticatedRedirectScreenState extends State<AuthenticatedRedirectScreen> {
  bool _launching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openLanding());
  }

  Future<void> _openLanding() async {
    if (_launching || !mounted) return;
    setState(() {
      _launching = true;
      _error = null;
    });

    try {
      await context.read<AppState>().openAuthenticatedLanding();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _launching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/ui/bg_main.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF030712).withOpacity(0.80),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    const Text(
                      'Opening your game...',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error ?? 'Syncing your player profile and moving you into the main game screen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.78), height: 1.35),
                    ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: _openLanding,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
