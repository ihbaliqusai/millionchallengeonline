import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../widgets/game_shell.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return GameShell(
      title: 'الإعدادات',
      subtitle: 'إدارة تفضيلات الحساب والوصول السريع لإجراءات اللاعب.',
      action: IconButton.filledTonal(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close_rounded),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 5,
                child: GlassPanel(
                  radius: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'عام',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 16),
                      const _SettingsTile(
                        icon: Icons.volume_up_rounded,
                        title: 'الصوت',
                        subtitle: 'التحكم في مستوى الصوت والمؤثرات داخل اللعبة.',
                      ),
                      const SizedBox(height: 12),
                      const _SettingsTile(
                        icon: Icons.language_rounded,
                        title: 'اللغة',
                        subtitle: 'عرض النصوص بنفس لغة الواجهة الأساسية للتطبيق.',
                      ),
                      const SizedBox(height: 12),
                      const _SettingsTile(
                        icon: Icons.shield_rounded,
                        title: 'الخصوصية',
                        subtitle: 'راجع معلومات الحساب والخصوصية بسرعة من هنا.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 4,
                child: GlassPanel(
                  radius: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'الحساب',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        appState.user?.email ?? 'Signed in',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: NeonButton(
                          label: 'تسجيل الخروج',
                          icon: Icons.logout_rounded,
                          compact: true,
                          onPressed: appState.isBusy
                              ? null
                              : () async {
                                  await context.read<AppState>().signOut();
                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();
                                },
                        ),
                      ),
                    ],
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF2D3FFF), Color(0xFF14B8FF)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 13,
                    height: 1.35,
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
