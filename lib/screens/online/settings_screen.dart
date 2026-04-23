import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../services/native_bridge_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  bool _sfx = true;
  bool _music = true;
  bool _haptic = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final bridge = context.read<NativeBridgeService>();
      final settings = await bridge.getSettings();
      if (!mounted) return;
      setState(() {
        _sfx    = settings['sfx']    ?? true;
        _music  = settings['music']  ?? true;
        _haptic = settings['haptic'] ?? true;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setSfx(bool value) async {
    setState(() => _sfx = value);
    await context.read<NativeBridgeService>().setSoundEnabled(value);
    if (_haptic) HapticFeedback.lightImpact();
  }

  Future<void> _setMusic(bool value) async {
    setState(() => _music = value);
    await context.read<NativeBridgeService>().setMusicEnabled(value);
    if (_haptic) HapticFeedback.lightImpact();
  }

  Future<void> _setHaptic(bool value) async {
    setState(() => _haptic = value);
    await context.read<NativeBridgeService>().setHapticEnabled(value);
    if (value) HapticFeedback.mediumImpact();
  }

  Future<void> _openNotifications() async {
    if (_haptic) HapticFeedback.lightImpact();
    await context.read<NativeBridgeService>().openNotificationSettings();
  }

  void _openLanguage() {
    if (_haptic) HapticFeedback.lightImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF152055),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        title: const Text(
          'اللغة',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'اللغة العربية محددة حالياً.\nسيتم إضافة دعم لغات أخرى في تحديث قادم.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'حسناً',
              style: TextStyle(color: Color(0xFF7DD3FC), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _openPrivacyPolicy() {
    if (_haptic) HapticFeedback.lightImpact();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF152055),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'سياسة الخصوصية',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'نجمع فقط البيانات الضرورية لتشغيل اللعبة، '
            'بما في ذلك اسم المستخدم وصورة الملف الشخصي وتقدم اللعبة.\n\n'
            'يتم تخزين بياناتك بأمان عبر Firebase ولا تُباع أو تُشارك '
            'مع أطراف ثالثة لأغراض إعلانية.\n\n'
            'يمكنك حذف حسابك وجميع البيانات المرتبطة به في أي وقت '
            'عن طريق التواصل معنا من خلال صفحة التطبيق في متجر التطبيقات.\n\n'
            'باستخدامك هذا التطبيق فإنك توافق على هذه الشروط.',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'إغلاق',
              style: TextStyle(color: Color(0xFF7DD3FC), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _restorePurchases() async {
    if (_haptic) HapticFeedback.lightImpact();
    final restored = await context.read<NativeBridgeService>().restorePurchases();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored ? 'تمت استعادة المشتريات بنجاح.' : 'لم يتم العثور على مشتريات لاستعادتها.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1640),
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      children: [
                        _TappableRow(
                          icon: Icons.language_rounded,
                          label: 'اللغة',
                          trailing: Container(
                            width: 38,
                            height: 26,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      color: const Color(0xFFB22234),
                                      child: Column(
                                        children: List.generate(
                                          7,
                                          (i) => Expanded(
                                            child: Container(
                                              color: i.isEven
                                                  ? const Color(0xFFB22234)
                                                  : Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 15,
                                    color: const Color(0xFF3C3B6E),
                                    child: const Center(
                                      child: Text(
                                        '★',
                                        style: TextStyle(color: Colors.white, fontSize: 6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          onTap: _openLanguage,
                        ),
                        const SizedBox(height: 6),
                        _ToggleRow(
                          icon: Icons.volume_up_rounded,
                          label: 'المؤثرات',
                          value: _sfx,
                          onChanged: _setSfx,
                        ),
                        const SizedBox(height: 6),
                        _ToggleRow(
                          icon: Icons.music_note_rounded,
                          label: 'الموسيقى',
                          value: _music,
                          onChanged: _setMusic,
                        ),
                        const SizedBox(height: 6),
                        _ToggleRow(
                          icon: Icons.vibration_rounded,
                          label: 'الاهتزاز',
                          value: _haptic,
                          onChanged: _setHaptic,
                        ),
                        const SizedBox(height: 6),
                        _TappableRow(
                          icon: Icons.notifications_rounded,
                          label: 'الإشعارات',
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white38,
                            size: 16,
                          ),
                          onTap: _openNotifications,
                        ),
                        const SizedBox(height: 16),
                        _SignOutRow(appState: appState),
                      ],
                    ),
            ),
            _BottomButtons(
              onPrivacyPolicy: _openPrivacyPolicy,
              onRestorePurchases: _restorePurchases,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Text(
            'الإعدادات',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tappable row (Language / Notifications) ──────────────────────────────────

class _TappableRow extends StatelessWidget {
  const _TappableRow({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _RowShell(icon: icon, label: label, trailing: trailing),
    );
  }
}

// ─── Toggle row ───────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _RowShell(
      icon: icon,
      label: label,
      trailing: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 52,
          height: 28,
          decoration: BoxDecoration(
            color: value ? const Color(0xFFFACC15) : const Color(0xFF374151),
            borderRadius: BorderRadius.circular(14),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sign-out row ─────────────────────────────────────────────────────────────

class _SignOutRow extends StatelessWidget {
  const _SignOutRow({required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return _RowShell(
      icon: Icons.logout_rounded,
      label: appState.user?.email ?? 'الحساب',
      trailing: GestureDetector(
        onTap: appState.isBusy
            ? null
            : () async {
                await context.read<AppState>().signOut();
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'تسجيل الخروج',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Row shell ────────────────────────────────────────────────────────────────

class _RowShell extends StatelessWidget {
  const _RowShell({
    required this.icon,
    required this.label,
    required this.trailing,
  });
  final IconData icon;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF152055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

// ─── Bottom buttons ───────────────────────────────────────────────────────────

class _BottomButtons extends StatelessWidget {
  const _BottomButtons({
    required this.onPrivacyPolicy,
    required this.onRestorePurchases,
  });
  final VoidCallback onPrivacyPolicy;
  final VoidCallback onRestorePurchases;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'سياسة\nالخصوصية',
              color: const Color(0xFF2563EB),
              onTap: onPrivacyPolicy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              label: 'استعادة\nالمشتريات',
              color: const Color(0xFF16A34A),
              onTap: onRestorePurchases,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.3,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
