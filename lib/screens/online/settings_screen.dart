import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_settings.dart';
import '../../core/app_state.dart';
import '../../services/ad_service.dart';
import '../legal/privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _feedback([AppSettings? settings]) async {
    final appSettings = settings ?? context.read<AppSettings>();
    if (appSettings.haptic) {
      await HapticFeedback.lightImpact();
    }
  }

  String _text(AppSettings settings, String ar, String en) {
    return settings.isArabic ? ar : en;
  }

  Future<void> _setLanguage(String code) async {
    final settings = context.read<AppSettings>();
    await _feedback(settings);
    await settings.setLanguage(code);
  }

  Future<void> _toggleSfx(bool value) async {
    final settings = context.read<AppSettings>();
    await settings.setSfx(value);
    await _feedback(settings);
  }

  Future<void> _toggleMusic(bool value) async {
    final settings = context.read<AppSettings>();
    await settings.setMusic(value);
    await _feedback(settings);
  }

  Future<void> _toggleHaptic(bool value) async {
    final settings = context.read<AppSettings>();
    await settings.setHaptic(value);
    if (value) {
      await HapticFeedback.mediumImpact();
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final settings = context.read<AppSettings>();
    await _feedback(settings);
    await settings.setNotifications(value);
    if (!mounted) return;
    if (value && !settings.systemNotifications) {
      _showSnack(
        settings,
        'تم تفعيل التذكير داخل اللعبة، لكن إشعارات النظام تحتاج سماحاً من إعدادات الهاتف.',
        'Game reminders are enabled, but system notifications still need phone permission.',
      );
    }
  }

  Future<void> _toggleDialogs(bool value) async {
    final settings = context.read<AppSettings>();
    await settings.setDialogs(value);
    await _feedback(settings);
  }

  Future<void> _openNotificationSettings() async {
    final settings = context.read<AppSettings>();
    await _feedback(settings);
    await settings.openNotificationSettings();
  }

  void _openPrivacyPolicy() {
    _feedback();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  Future<void> _openAdPrivacyOptions() async {
    final settings = context.read<AppSettings>();
    final adService = context.read<AdService>();
    await _feedback(settings);
    final error = await adService.showPrivacyOptionsForm();
    if (!mounted || error == null) return;
    _showSnack(
      settings,
      error.message.trim().isNotEmpty
          ? error.message.trim()
          : 'تعذر فتح خيارات خصوصية الإعلانات الآن.',
      error.message.trim().isNotEmpty
          ? error.message.trim()
          : 'Could not open ad privacy options right now.',
      error: true,
    );
  }

  Future<void> _signOut() async {
    final settings = context.read<AppSettings>();
    final appState = context.read<AppState>();
    await _feedback(settings);
    await appState.signOut();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _deleteAccount() async {
    final settings = context.read<AppSettings>();
    final appState = context.read<AppState>();
    if (settings.haptic) {
      await HapticFeedback.heavyImpact();
    }

    final user = appState.user;
    if (user == null) return;

    final providerIds = user.providerData
        .map((info) => info.providerId)
        .whereType<String>()
        .toSet();
    final requiresPassword = providerIds.contains('password');
    final password = await _showDeleteAccountDialog(
      email: user.email ?? '',
      requiresPassword: requiresPassword,
    );
    if (password == null || !mounted) return;

    try {
      await appState.deleteAccount(
        password: requiresPassword ? password : null,
      );
      if (!mounted) return;
      _showSnack(
        settings,
        'تم حذف الحساب وبياناته المحلية بنجاح.',
        'Account and local data deleted successfully.',
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      _showSnack(settings, error.toString(), error.toString(), error: true);
    }
  }

  void _showSnack(
    AppSettings settings,
    String ar,
    String en, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_text(settings, ar, en)),
        backgroundColor:
            error ? const Color(0xFFB91C1C) : const Color(0xFF0F766E),
      ),
    );
  }

  Future<String?> _showDeleteAccountDialog({
    required String email,
    required bool requiresPassword,
  }) {
    final controller = TextEditingController();
    String? validationMessage;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        final settings = context.watch<AppSettings>();
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF081328),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: Row(
                children: <Widget>[
                  const Icon(
                    Icons.delete_forever_rounded,
                    color: Color(0xFFF87171),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _text(
                        settings,
                        'حذف الحساب نهائياً',
                        'Delete Account',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    requiresPassword
                        ? _text(
                            settings,
                            'سيتم حذف الحساب المرتبط بـ $email وكل بياناته. أدخل كلمة المرور الحالية للتأكيد.',
                            'The account linked to $email and its data will be deleted. Enter your current password to confirm.',
                          )
                        : _text(
                            settings,
                            'سيتم حذف حسابك وكل بياناته من اللعبة نهائياً.',
                            'Your account and all game data will be permanently deleted.',
                          ),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.76),
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (requiresPassword) ...<Widget>[
                    const SizedBox(height: 14),
                    TextField(
                      controller: controller,
                      obscureText: true,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: _text(
                          settings,
                          'كلمة المرور الحالية',
                          'Current password',
                        ),
                        errorText: validationMessage,
                      ),
                      onChanged: (_) {
                        if (validationMessage != null) {
                          setState(() => validationMessage = null);
                        }
                      },
                    ),
                  ],
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: Text(
                    _text(settings, 'إلغاء', 'Cancel'),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    final password = controller.text.trim();
                    if (requiresPassword && password.isEmpty) {
                      setState(() {
                        validationMessage = _text(
                          settings,
                          'أدخل كلمة المرور للتأكيد.',
                          'Enter the password to confirm.',
                        );
                      });
                      return;
                    }
                    Navigator.of(ctx).pop(password);
                  },
                  child: Text(
                    _text(settings, 'حذف نهائي', 'Delete'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final appState = context.watch<AppState>();
    final adService = context.watch<AdService>();

    return Directionality(
      textDirection: settings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF071126),
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Image.asset('assets/ui/bg_main.png', fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      const Color(0xFF030712).withValues(alpha: 0.58),
                      const Color(0xFF071126).withValues(alpha: 0.94),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: <Widget>[
                  _Header(
                    title: _text(settings, 'الإعدادات', 'Settings'),
                    subtitle: _text(
                      settings,
                      'تحكم فعلي بالصوت، اللغة، التذكيرات وتجربة اللعب',
                      'Real controls for sound, language, reminders, and gameplay',
                    ),
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: settings.loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFACC15),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final compact = constraints.maxHeight < 300 ||
                                  constraints.maxWidth < 880;
                              final gap = compact ? 8.0 : 12.0;
                              return Padding(
                                padding: EdgeInsets.fromLTRB(
                                  compact ? 10 : 16,
                                  0,
                                  compact ? 10 : 16,
                                  compact ? 10 : 14,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      flex: 3,
                                      child: _LanguagePanel(
                                        settings: settings,
                                        compact: compact,
                                        onLanguage: _setLanguage,
                                        onOpenNotifications:
                                            _openNotificationSettings,
                                      ),
                                    ),
                                    SizedBox(width: gap),
                                    Expanded(
                                      flex: 5,
                                      child: _SwitchBoard(
                                        settings: settings,
                                        compact: compact,
                                        gap: gap,
                                        onSfx: _toggleSfx,
                                        onMusic: _toggleMusic,
                                        onHaptic: _toggleHaptic,
                                        onNotifications: _toggleNotifications,
                                        onDialogs: _toggleDialogs,
                                      ),
                                    ),
                                    SizedBox(width: gap),
                                    Expanded(
                                      flex: 3,
                                      child: _ActionsPanel(
                                        settings: settings,
                                        appState: appState,
                                        showAdPrivacy:
                                            adService.privacyOptionsRequired,
                                        compact: compact,
                                        onPrivacy: _openPrivacyPolicy,
                                        onAdPrivacy: _openAdPrivacyOptions,
                                        onSignOut: _signOut,
                                        onDeleteAccount: _deleteAccount,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.white,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguagePanel extends StatelessWidget {
  const _LanguagePanel({
    required this.settings,
    required this.compact,
    required this.onLanguage,
    required this.onOpenNotifications,
  });

  final AppSettings settings;
  final bool compact;
  final ValueChanged<String> onLanguage;
  final VoidCallback onOpenNotifications;

  String _t(String ar, String en) => settings.isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: _panelDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final needsScroll =
              constraints.hasBoundedHeight && constraints.maxHeight < 220;
          final topChildren = <Widget>[
            _PanelTitle(
              icon: Icons.language_rounded,
              title: _t('لغة الواجهة', 'Interface Language'),
              subtitle: _t(
                'تتغير فوراً في واجهة Flutter وتحفظ للعبة الأصلية.',
                'Applies immediately in Flutter and is saved for the native game.',
              ),
              compact: compact,
            ),
            SizedBox(height: compact ? 8 : 12),
            _LanguageSegment(
              value: settings.languageCode,
              onChanged: onLanguage,
              compact: compact,
            ),
            SizedBox(height: compact ? 8 : 12),
            _StatusBox(
              icon: Icons.notifications_active_rounded,
              color: settings.notifications && settings.systemNotifications
                  ? const Color(0xFF34D399)
                  : const Color(0xFFF59E0B),
              title: _t('حالة الإشعارات', 'Notification Status'),
              value: settings.notifications
                  ? settings.systemNotifications
                      ? _t('مفعلة', 'Enabled')
                      : _t('تحتاج سماح النظام', 'Needs permission')
                  : _t('متوقفة', 'Off'),
              compact: compact,
            ),
          ];
          final action = _ActionLineButton(
            icon: Icons.settings_applications_rounded,
            label:
                _t('فتح إعدادات إشعارات الهاتف', 'Phone Notification Settings'),
            color: const Color(0xFF38BDF8),
            onTap: onOpenNotifications,
            compact: compact,
          );

          if (needsScroll) {
            return ListView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              children: <Widget>[
                ...topChildren,
                SizedBox(height: compact ? 8 : 12),
                action,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ...topChildren,
              const Spacer(),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _SwitchBoard extends StatelessWidget {
  const _SwitchBoard({
    required this.settings,
    required this.compact,
    required this.gap,
    required this.onSfx,
    required this.onMusic,
    required this.onHaptic,
    required this.onNotifications,
    required this.onDialogs,
  });

  final AppSettings settings;
  final bool compact;
  final double gap;
  final ValueChanged<bool> onSfx;
  final ValueChanged<bool> onMusic;
  final ValueChanged<bool> onHaptic;
  final ValueChanged<bool> onNotifications;
  final ValueChanged<bool> onDialogs;

  String _t(String ar, String en) => settings.isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    final items = <_ToggleData>[
      _ToggleData(
        icon: Icons.volume_up_rounded,
        color: const Color(0xFF38BDF8),
        title: _t('المؤثرات', 'Sound Effects'),
        subtitle: _t('الإجابات، العد التنازلي، الأصوات القصيرة',
            'Answers, timer beeps, short cues'),
        value: settings.sfx,
        onChanged: onSfx,
      ),
      _ToggleData(
        icon: Icons.music_note_rounded,
        color: const Color(0xFFFACC15),
        title: _t('الموسيقى', 'Music'),
        subtitle: _t('الثيمات والخلفيات الصوتية داخل المباراة',
            'Themes and background tracks in matches'),
        value: settings.music,
        onChanged: onMusic,
      ),
      _ToggleData(
        icon: Icons.vibration_rounded,
        color: const Color(0xFFEC4899),
        title: _t('الاهتزاز', 'Haptics'),
        subtitle: _t('لمسات الأزرار، الإجابة، التأكيدات',
            'Buttons, answers, confirmations'),
        value: settings.haptic,
        onChanged: onHaptic,
      ),
      _ToggleData(
        icon: Icons.notifications_rounded,
        color: const Color(0xFFFB923C),
        title: _t('الإشعارات', 'Notifications'),
        subtitle: _t('تذكير يومي بالمكافأة وسلسلة الدخول',
            'Daily reward and streak reminder'),
        value: settings.notifications,
        onChanged: onNotifications,
      ),
      _ToggleData(
        icon: Icons.record_voice_over_rounded,
        color: const Color(0xFF34D399),
        title: _t('تأكيدات اللعب', 'Game Confirmations'),
        subtitle: _t('حوار بدء لعبة جديدة والخروج في اللعب الأصلي',
            'New game and exit confirmations in native play'),
        value: settings.dialogs,
        onChanged: onDialogs,
      ),
    ];

    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: _panelDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final needsScroll =
              constraints.hasBoundedHeight && constraints.maxHeight < 250;

          final title = _PanelTitle(
            icon: Icons.tune_rounded,
            title: _t('مفاتيح اللعب', 'Gameplay Controls'),
            subtitle: _t(
              'كل خيار هنا محفوظ ويُقرأ داخل اللعب الفعلي.',
              'Every option here is saved and read by gameplay.',
            ),
            compact: compact,
          );

          if (needsScroll) {
            return ListView.separated(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              itemCount: items.length + 1,
              separatorBuilder: (_, __) => SizedBox(height: compact ? 7 : 9),
              itemBuilder: (context, index) {
                if (index == 0) return title;
                return SizedBox(
                  height: compact ? 58 : 66,
                  child: _ToggleTile(
                    data: items[index - 1],
                    compact: compact,
                  ),
                );
              },
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              title,
              SizedBox(height: compact ? 8 : 10),
              Expanded(
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child:
                                _ToggleTile(data: items[0], compact: compact),
                          ),
                          SizedBox(width: gap),
                          Expanded(
                            child:
                                _ToggleTile(data: items[1], compact: compact),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: gap),
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child:
                                _ToggleTile(data: items[2], compact: compact),
                          ),
                          SizedBox(width: gap),
                          Expanded(
                            child:
                                _ToggleTile(data: items[3], compact: compact),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: gap),
                    Expanded(
                      child: _ToggleTile(data: items[4], compact: compact),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionsPanel extends StatelessWidget {
  const _ActionsPanel({
    required this.settings,
    required this.appState,
    required this.showAdPrivacy,
    required this.compact,
    required this.onPrivacy,
    required this.onAdPrivacy,
    required this.onSignOut,
    required this.onDeleteAccount,
  });

  final AppSettings settings;
  final AppState appState;
  final bool showAdPrivacy;
  final bool compact;
  final VoidCallback onPrivacy;
  final VoidCallback onAdPrivacy;
  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccount;

  String _t(String ar, String en) => settings.isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    final email = appState.user?.email ?? _t('حساب لاعب', 'Player Account');

    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: _panelDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final needsScroll =
              constraints.hasBoundedHeight && constraints.maxHeight < 220;
          final topChildren = <Widget>[
            _PanelTitle(
              icon: Icons.manage_accounts_rounded,
              title: _t('الحساب والخصوصية', 'Account & Privacy'),
              subtitle: email,
              compact: compact,
            ),
            SizedBox(height: compact ? 8 : 10),
            _ActionLineButton(
              icon: Icons.privacy_tip_rounded,
              label: _t('سياسة الخصوصية', 'Privacy Policy'),
              color: const Color(0xFF38BDF8),
              onTap: onPrivacy,
              compact: compact,
            ),
            if (showAdPrivacy) ...<Widget>[
              SizedBox(height: compact ? 6 : 8),
              _ActionLineButton(
                icon: Icons.shield_rounded,
                label: _t('خصوصية الإعلانات', 'Ad Privacy'),
                color: const Color(0xFFA78BFA),
                onTap: onAdPrivacy,
                compact: compact,
              ),
            ],
          ];
          final bottomChildren = <Widget>[
            _ActionLineButton(
              icon: Icons.logout_rounded,
              label: _t('تسجيل الخروج', 'Sign Out'),
              color: const Color(0xFFF59E0B),
              onTap: appState.isBusy ? null : onSignOut,
              compact: compact,
            ),
            SizedBox(height: compact ? 6 : 8),
            _ActionLineButton(
              icon: Icons.delete_forever_rounded,
              label: _t('حذف الحساب', 'Delete Account'),
              color: const Color(0xFFF87171),
              onTap: onDeleteAccount,
              compact: compact,
            ),
          ];

          if (needsScroll) {
            return ListView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              children: <Widget>[
                ...topChildren,
                SizedBox(height: compact ? 8 : 10),
                ...bottomChildren,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ...topChildren,
              const Spacer(),
              ...bottomChildren,
            ],
          );
        },
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.compact,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: compact ? 34 : 40,
          height: compact ? 34 : 40,
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.28),
            ),
          ),
          child: Icon(icon,
              color: const Color(0xFF38BDF8), size: compact ? 18 : 21),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 13 : 15,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.56),
                  fontSize: compact ? 8 : 9,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LanguageSegment extends StatelessWidget {
  const _LanguageSegment({
    required this.value,
    required this.onChanged,
    required this.compact,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 42 : 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _LanguageChoice(
              label: 'العربية',
              selected: value == 'ar',
              onTap: () => onChanged('ar'),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _LanguageChoice(
              label: 'English',
              selected: value == 'en',
              onTap: () => onChanged('en'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageChoice extends StatelessWidget {
  const _LanguageChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFACC15) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF111827) : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({required this.data, required this.compact});

  final _ToggleData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: _panelDecoration(accent: data.color, subtle: true),
      child: Row(
        children: <Widget>[
          Icon(data.icon, color: data.color, size: compact ? 20 : 24),
          SizedBox(width: compact ? 7 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  data.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: compact ? 3 : 5),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: compact ? 8 : 9,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _ProSwitch(
            value: data.value,
            color: data.color,
            onChanged: data.onChanged,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _ProSwitch extends StatelessWidget {
  const _ProSwitch({
    required this.value,
    required this.color,
    required this.onChanged,
    required this.compact,
  });

  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: compact ? 42 : 48,
        height: compact ? 24 : 27,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color:
              value ? color.withValues(alpha: 0.95) : const Color(0xFF293548),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                value ? Colors.white.withValues(alpha: 0.22) : Colors.white12,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: compact ? 18 : 21,
            height: compact ? 18 : 21,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  const _StatusBox({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.compact,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: _panelDecoration(accent: color, subtle: true),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color, size: compact ? 18 : 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionLineButton extends StatelessWidget {
  const _ActionLineButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 10,
            vertical: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: color, size: compact ? 16 : 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleData {
  const _ToggleData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
}

BoxDecoration _panelDecoration({
  Color? accent,
  bool subtle = false,
}) {
  final borderColor = accent == null
      ? Colors.white.withValues(alpha: 0.12)
      : accent.withValues(alpha: subtle ? 0.26 : 0.34);

  return BoxDecoration(
    color: const Color(0xFF081328).withValues(alpha: subtle ? 0.80 : 0.88),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: borderColor),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: subtle ? 0.14 : 0.22),
        blurRadius: subtle ? 8 : 14,
        offset: const Offset(0, 6),
      ),
    ],
  );
}
