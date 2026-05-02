import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../services/native_bridge_service.dart';

class OfflineWelcomeScreen extends StatefulWidget {
  const OfflineWelcomeScreen({super.key});

  @override
  State<OfflineWelcomeScreen> createState() => _OfflineWelcomeScreenState();
}

class _OfflineWelcomeScreenState extends State<OfflineWelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final AnimationController _entryCtrl;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _playOffline() async {
    final native = context.read<NativeBridgeService>();
    await native.launchOfflineGame();
  }

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    final results = await Connectivity().checkConnectivity();
    final online = results.isNotEmpty &&
        results.any((r) => r != ConnectivityResult.none);
    if (!mounted) return;
    if (online) {
      // AppState listens to the connectivity stream in main.dart and will
      // flip isOnline → AuthGate rebuilds to LoginScreen automatically.
      context.read<AppState>().updateConnectivity(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يزال الاتصال غير متوفر، حاول مرة أخرى'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/ui/bg_login.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF08112F).withValues(alpha: 0.82),
                      const Color(0xFF060C24).withValues(alpha: 0.95),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: FadeTransition(
                    opacity: fade,
                    child: SlideTransition(
                      position: slide,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _glowCtrl,
                            builder: (_, child) => Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.14),
                                border: Border.all(
                                  color: const Color(0xFFEF4444).withValues(
                                    alpha: 0.35 + _glowCtrl.value * 0.4,
                                  ),
                                  width: 1.6,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444).withValues(
                                      alpha: _glowCtrl.value * 0.35,
                                    ),
                                    blurRadius: 22,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: child,
                            ),
                            child: const Icon(
                              Icons.wifi_off_rounded,
                              size: 46,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'لا يوجد اتصال بالإنترنت',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'يمكنك اللعب الآن في الطور الأوفلاين، وستتم مزامنة تقدّمك تلقائياً عند تسجيل الدخول مع توفّر الاتصال.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Colors.white.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _PrimaryButton(
                            label: 'العب الآن أوفلاين',
                            icon: Icons.sports_esports_rounded,
                            glowCtrl: _glowCtrl,
                            onPressed: _playOffline,
                          ),
                          const SizedBox(height: 12),
                          _SecondaryButton(
                            label: _retrying
                                ? 'جارٍ التحقق...'
                                : 'إعادة محاولة الاتصال',
                            icon: Icons.refresh_rounded,
                            busy: _retrying,
                            onPressed: _retrying ? null : _retry,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.glowCtrl,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final AnimationController glowCtrl;
  final VoidCallback onPressed;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.glowCtrl,
      builder: (_, __) {
        final glow = 0.35 + widget.glowCtrl.value * 0.4;
        return AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) {
              setState(() => _pressed = false);
              widget.onPressed();
            },
            child: Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF8D34C), Color(0xFFF59E0B)],
                ),
                border: Border.all(
                    color: const Color(0xFFFFF3A3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color:
                        const Color(0xFFF59E0B).withValues(alpha: glow),
                    blurRadius: 22,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon,
                      color: const Color(0xFF1F2937), size: 24),
                  const SizedBox(width: 10),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1F2937),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.busy = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
              color: Colors.white.withValues(alpha: 0.35), width: 1.4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              )
            else
              Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
