import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../widgets/game_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _register = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppState state) async {
    try {
      if (_register) {
        await state.register(
          _emailController.text,
          _passwordController.text,
          _usernameController.text,
        );
      } else {
        await state.signIn(_emailController.text, _passwordController.text);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(image: AssetImage('assets/ui/bg_login.png'), fit: BoxFit.cover),
          ),
          child: SafeArea(
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          const Color(0xFF08112F).withOpacity(0.74),
                          const Color(0xFF060C24).withOpacity(0.92),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 18,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.18,
                      child: Image.asset('assets/ui/person_welcome.png', height: 290),
                    ),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 880;
                          final branding = _BrandingPanel(register: _register);
                          final form = _LoginForm(
                            register: _register,
                            state: state,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            usernameController: _usernameController,
                            onSubmit: () => _submit(state),
                            onToggle: () => setState(() => _register = !_register),
                          );

                          if (!wide) {
                            return Column(
                              children: <Widget>[
                                branding,
                                const SizedBox(height: 16),
                                form,
                              ],
                            );
                          }

                          return Row(
                            children: <Widget>[
                              Expanded(child: branding),
                              const SizedBox(width: 18),
                              Expanded(child: form),
                            ],
                          );
                        },
                      ),
                    ),
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

class _BrandingPanel extends StatelessWidget {
  const _BrandingPanel({required this.register});

  final bool register;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Image.asset('assets/ui/logo.png', height: 82),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Million Challenge Online',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            register
                ? 'أنشئ حسابك مرة واحدة ليتم حفظ اسم اللاعب وصورته والتقدم الخاص به داخل اللعبة.'
                : 'سجّل الدخول بحسابك ليتم عرض اسمك الحقيقي مباشرة داخل الشاشة الرئيسية للعبة.',
            style: TextStyle(color: Colors.white.withOpacity(0.82), fontSize: 16, height: 1.35),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const <Widget>[
              _FeatureChip(icon: Icons.flash_on_rounded, text: 'مواجهة سريعة'),
              _FeatureChip(icon: Icons.groups_rounded, text: 'حساب موحّد'),
              _FeatureChip(icon: Icons.verified_user_rounded, text: 'مزامنة آمنة'),
              _FeatureChip(icon: Icons.person_add_alt_1_rounded, text: 'هوية لاعب ثابتة'),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.verified_user_rounded, color: Color(0xFFFACC15), size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'بعد تسجيل الدخول سيتم مزامنة اسم اللاعب والصورة الشخصية تلقائيًا مع الشاشة الرئيسية الأصلية للعبة.',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.register,
    required this.state,
    required this.emailController,
    required this.passwordController,
    required this.usernameController,
    required this.onSubmit,
    required this.onToggle,
  });

  final bool register;
  final AppState state;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController usernameController;
  final VoidCallback onSubmit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(register ? 'إنشاء حساب جديد' : 'تسجيل الدخول', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          if (register) ...<Widget>[
            _GameInput(controller: usernameController, label: 'اسم اللاعب', icon: Icons.person_outline_rounded),
            const SizedBox(height: 12),
          ],
          _GameInput(
            controller: emailController,
            label: 'البريد الإلكتروني',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _GameInput(
            controller: passwordController,
            label: 'كلمة المرور',
            icon: Icons.lock_outline_rounded,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          NeonButton(
            label: register ? 'إنشاء الحساب' : 'دخول',
            icon: register ? Icons.person_add_alt_1_rounded : Icons.login_rounded,
            gold: true,
            onPressed: state.isBusy ? null : onSubmit,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 58,
            child: OutlinedButton(
              onPressed: state.isBusy
                  ? null
                  : () async {
                      try {
                        await state.signInWithGoogle();
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset('assets/ui/google.png', width: 26, height: 26),
                  const SizedBox(width: 12),
                  const Text('المتابعة باستخدام Google', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: state.isBusy ? null : onToggle,
            child: Text(
              register ? 'لديك حساب بالفعل؟ تسجيل الدخول' : 'ليس لديك حساب؟ إنشاء حساب',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameInput extends StatelessWidget {
  const _GameInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 17),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: const Color(0xFF7DD3FC)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
