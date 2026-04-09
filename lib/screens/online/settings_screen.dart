import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _sfx = true;
  bool _music = true;
  bool _haptic = true;
  bool _notifications = false;
  bool _performance = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1640),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            _Header(onBack: () => Navigator.of(context).pop()),

            // ── Settings rows ─────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  _LanguageRow(),
                  const SizedBox(height: 6),
                  _ToggleRow(
                    icon: Icons.volume_up_rounded,
                    label: 'SFX',
                    value: _sfx,
                    onChanged: (v) => setState(() => _sfx = v),
                  ),
                  const SizedBox(height: 6),
                  _ToggleRow(
                    icon: Icons.music_note_rounded,
                    label: 'Music',
                    value: _music,
                    onChanged: (v) => setState(() => _music = v),
                  ),
                  const SizedBox(height: 6),
                  _ToggleRow(
                    icon: Icons.vibration_rounded,
                    label: 'Haptic',
                    value: _haptic,
                    onChanged: (v) => setState(() => _haptic = v),
                  ),
                  const SizedBox(height: 6),
                  _ToggleRow(
                    icon: Icons.notifications_rounded,
                    label: 'Notifications',
                    value: _notifications,
                    onChanged: (v) => setState(() => _notifications = v),
                  ),
                  const SizedBox(height: 6),
                  _ToggleRow(
                    icon: Icons.bolt_rounded,
                    label: 'Performance',
                    value: _performance,
                    onChanged: (v) => setState(() => _performance = v),
                  ),
                  const SizedBox(height: 16),
                  // Sign-out row
                  _SignOutRow(appState: appState),
                ],
              ),
            ),

            // ── Bottom buttons ────────────────────────────────────────
            _BottomButtons(appState: appState),
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
            'Settings',
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

// ─── Language row ─────────────────────────────────────────────────────────────

class _LanguageRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _RowShell(
      icon: Icons.language_rounded,
      label: 'Language',
      trailing: Container(
        width: 38,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          // US flag using color blocks as placeholder
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
      label: appState.user?.email ?? 'Account',
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
            'Sign Out',
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
  const _BottomButtons({required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'PRIVACY\nPOLICY',
              color: const Color(0xFF2563EB),
              onTap: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              label: 'RESTORE\nPURCHASES',
              color: const Color(0xFF16A34A),
              onTap: () {},
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
