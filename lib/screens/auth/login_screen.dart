import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../widgets/game_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _register = false;

  // ── controllers ──────────────────────────────────────────────
  late final AnimationController _cardCtrl;
  late final AnimationController _particlesCtrl;
  late final AnimationController _iconPulseCtrl;

  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();

    // card entrance
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _cardFade = CurvedAnimation(
      parent: _cardCtrl,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));

    // floating particles
    _particlesCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // icon glow pulse
    _iconPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _cardCtrl.dispose();
    _particlesCtrl.dispose();
    _iconPulseCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final username = _usernameController.text.trim();

    if (email.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    if (password.isEmpty) return 'يرجى إدخال كلمة المرور';
    if (password.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    if (_register && username.isEmpty) return 'يرجى إدخال اسم اللاعب';
    return null;
  }

  static String _arabicFirebaseError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('wrong-password') || lower.contains('invalid-credential')) {
      return 'كلمة المرور أو البريد الإلكتروني غير صحيح';
    }
    if (lower.contains('user-not-found')) return 'لا يوجد حساب بهذا البريد الإلكتروني';
    if (lower.contains('email-already-in-use')) return 'هذا البريد الإلكتروني مستخدم بالفعل';
    if (lower.contains('invalid-email')) return 'صيغة البريد الإلكتروني غير صحيحة';
    if (lower.contains('weak-password')) return 'كلمة المرور ضعيفة جداً';
    if (lower.contains('too-many-requests')) return 'تم تجاوز عدد المحاولات، حاول لاحقاً';
    if (lower.contains('network-request-failed')) return 'تحقق من اتصالك بالإنترنت';
    if (lower.contains('operation-not-allowed')) return 'طريقة تسجيل الدخول هذه غير مفعّلة';
    return 'حدث خطأ، حاول مرة أخرى';
  }

  Future<void> _submit(AppState state) async {
    final validationError = _validate();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }
    try {
      if (_register) {
        await state.register(
          _emailController.text.trim(),
          _passwordController.text,
          _usernameController.text.trim(),
        );
      } else {
        await state.signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_arabicFirebaseError(e.toString()))),
      );
    }
  }

  void _toggleMode() {
    // animate card out → swap content → animate back in
    _cardCtrl.reverse().then((_) {
      setState(() => _register = !_register);
      _cardCtrl.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => Scaffold(
        // ✅ هذا يزيل الـ padding الافتراضي للـ Scaffold
        resizeToAvoidBottomInset: true,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/ui/bg_login.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            // ✅ حذف SafeArea تماماً — هي السبب الرئيسي للإزاحة
            children: <Widget>[
              // خلفية داكنة تغطي كل الشاشة
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        const Color(0xFF08112F).withValues(alpha: 0.75),
                        const Color(0xFF060C24).withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                ),
              ),

              // الجسيمات الطائرة
              AnimatedBuilder(
                animation: _particlesCtrl,
                builder: (_, __) => CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _ParticlesPainter(_particlesCtrl.value),
                ),
              ),

              // الفورم في المنتصف مع مراعاة لوحة المفاتيح فقط
              Positioned.fill(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true, // ✅ إزالة padding الأعلى
                  removeLeft: true, // ✅ إزالة padding اليسار
                  removeRight: true,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 20,
                        // ✅ مسافة للأسفل عند ظهور الكيبورد فقط
                        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: FadeTransition(
                          opacity: _cardFade,
                          child: SlideTransition(
                            position: _cardSlide,
                            child: _LoginForm(
                              register: _register,
                              state: state,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              usernameController: _usernameController,
                              iconPulseCtrl: _iconPulseCtrl,
                              onSubmit: () => _submit(state),
                              onToggle: _toggleMode,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Floating particles painter
// ────────────────────────────────────────────────────────────────
class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter(this.t);
  final double t;

  static final _particles = List.generate(18, (i) {
    final rand = (i * 137.508) % 1.0; // deterministic pseudo-random
    return (
      x: (i * 73 % 100) / 100.0,
      speed: 0.04 + rand * 0.06,
      size: 2.0 + rand * 5,
      phase: rand,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final progress = (t * p.speed + p.phase) % 1.0;
      final opacity = progress < 0.1
          ? progress / 0.1
          : progress > 0.9
              ? (1 - progress) / 0.1
              : 1.0;

      canvas.drawCircle(
        Offset(p.x * size.width, size.height * (1 - progress)),
        p.size / 2,
        Paint()..color = const Color(0xFFFACC15).withValues(alpha: opacity * 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter old) => old.t != t;
}

// ────────────────────────────────────────────────────────────────
//  Login form widget
// ────────────────────────────────────────────────────────────────
class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.register,
    required this.state,
    required this.emailController,
    required this.passwordController,
    required this.usernameController,
    required this.iconPulseCtrl,
    required this.onSubmit,
    required this.onToggle,
  });

  final bool register;
  final AppState state;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController usernameController;
  final AnimationController iconPulseCtrl;
  final VoidCallback onSubmit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── pulsing icon ────────────────────────────────
            Center(
              child: AnimatedBuilder(
                animation: iconPulseCtrl,
                builder: (_, child) => Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFACC15).withValues(alpha: 0.12),
                    border: Border.all(
                      color: const Color(0xFFFACC15).withValues(
                        alpha: 0.3 + iconPulseCtrl.value * 0.4,
                      ),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFACC15).withValues(alpha: iconPulseCtrl.value * 0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: child,
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  size: 32,
                  color: Color(0xFFFACC15),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── title ───────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                register ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
                key: ValueKey(register),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            const SizedBox(height: 6),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                register ? 'قم بإنشاء حساب للمتابعة' : 'أدخل بياناتك للوصول إلى حسابك',
                key: ValueKey('sub_$register'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── fields ──────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              child: Column(
                children: [
                  if (register) ...[
                    _AnimatedField(
                      controller: usernameController,
                      label: 'اسم اللاعب',
                      icon: Icons.person_outline_rounded,
                      delay: 0,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _AnimatedField(
                    controller: emailController,
                    label: 'البريد الإلكتروني',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    delay: register ? 1 : 0,
                  ),
                  const SizedBox(height: 12),
                  _AnimatedField(
                    controller: passwordController,
                    label: 'كلمة المرور',
                    icon: Icons.lock_outline_rounded,
                    obscureText: true,
                    delay: register ? 2 : 1,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── main button ─────────────────────────────────
            NeonButton(
              label: register ? 'إنشاء الحساب' : 'دخول',
              icon: register ? Icons.person_add_alt_1_rounded : Icons.login_rounded,
              gold: true,
              onPressed: state.isBusy ? null : onSubmit,
            ),

            const SizedBox(height: 12),

            // ── Google button ───────────────────────────────
            _GoogleButton(state: state),

            const SizedBox(height: 10),

            // ── toggle ──────────────────────────────────────
            TextButton(
              onPressed: state.isBusy ? null : onToggle,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  register ? 'لديك حساب بالفعل؟ تسجيل الدخول' : 'ليس لديك حساب؟ إنشاء حساب',
                  key: ValueKey('toggle_$register'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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

// ────────────────────────────────────────────────────────────────
//  Field with staggered entrance animation
// ────────────────────────────────────────────────────────────────
class _AnimatedField extends StatefulWidget {
  const _AnimatedField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.delay,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int delay;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  State<_AnimatedField> createState() => _AnimatedFieldState();
}

class _AnimatedFieldState extends State<_AnimatedField> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(-0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(
      Duration(milliseconds: 100 + widget.delay * 80),
      () {
        if (mounted) _ctrl.forward();
      },
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          style: const TextStyle(fontSize: 17),
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: Icon(widget.icon),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Google sign-in button with hover effect
// ────────────────────────────────────────────────────────────────
class _GoogleButton extends StatefulWidget {
  const _GoogleButton({required this.state});
  final AppState state;

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: SizedBox(
          height: 56,
          child: OutlinedButton(
            onPressed: widget.state.isBusy
                ? null
                : () async {
                    try {
                      await widget.state.signInWithGoogle();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/ui/google.png', width: 24, height: 24),
                const SizedBox(width: 10),
                const Text(
                  'المتابعة بحساب Google',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
