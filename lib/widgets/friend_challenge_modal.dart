import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_state.dart';

class FriendChallengeModal extends StatefulWidget {
  const FriendChallengeModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (context) => const FriendChallengeModal(),
    );
  }

  @override
  State<FriendChallengeModal> createState() => _FriendChallengeModalState();
}

class _FriendChallengeModalState extends State<FriendChallengeModal> {
  final TextEditingController _friendCodeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkClipboardAutoFill());
  }

  @override
  void dispose() {
    _friendCodeController.dispose();
    super.dispose();
  }

  String _extractCode(String text) {
    if (text.isEmpty) return '';
    final trimmed = text.trim();
    if (RegExp(r'^[A-Za-z0-9]{4,15}$').hasMatch(trimmed)) {
      return trimmed.toUpperCase();
    }
    final match = RegExp(r'(?:كود التحدي(?: الخاص بي)?|رمز الغرفة|كود|code)[:\s\n]*([A-Za-z0-9]{4,15})', caseSensitive: false).firstMatch(text);
    if (match != null && match.group(1) != null) {
      return match.group(1)!.trim().toUpperCase();
    }
    final cleanWords = text.replaceAll(RegExp(r'https?://[^\s]+'), '').split(RegExp(r'\s+'));
    for (final word in cleanWords) {
      final clean = word.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
      if (clean.length >= 6 && clean.length <= 12) {
        return clean.toUpperCase();
      }
    }
    return trimmed.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
  }

  Future<void> _checkClipboardAutoFill() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && data!.text!.trim().isNotEmpty && mounted) {
        final extracted = _extractCode(data.text!);
        final myCode = context.read<AppState>().friendCode;
        if (extracted.isNotEmpty && extracted != myCode && _friendCodeController.text.isEmpty) {
          setState(() {
            _friendCodeController.text = extracted;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && data!.text!.trim().isNotEmpty) {
        final extracted = _extractCode(data.text!);
        if (extracted.isNotEmpty) {
          setState(() {
            _friendCodeController.text = extracted;
            _errorMessage = null;
          });
          HapticFeedback.selectionClick();
        }
      }
    } catch (_) {}
  }

  Future<void> _copyMyCode(String code) async {
    if (code.isEmpty) return;
    try {
      await Clipboard.setData(ClipboardData(text: code));
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399)),
              const SizedBox(width: 8),
              Text('تم نسخ كود التحدي: $code'),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {}
  }

  Future<void> _shareOnlyCode(String code) async {
    if (code.isEmpty) return;
    try {
      await Share.share(code, subject: 'كود التحدي في تحدي المليون');
    } catch (_) {}
  }

  Future<void> _shareMyCode(String code) async {
    if (code.isEmpty) return;
    try {
      final shareText =
          '⚔️ *تحداني الآن في لعبة تحدي المليون (Million Challenge)!*\n\n'
          '🔑 *كود التحدي:*\n`$code`\n\n'
          '📲 *رابط تحميل وفتح اللعبة مباشرة (Google Play):*\n'
          'https://play.google.com/store/apps/details?id=com.Qi7bali.millionchallengeonline\n\n'
          '🎮 بعد فتح اللعبة، اختر "تحدي صديق" والصق الكود للعب ضدي مباشرة!';
      await Share.share(shareText, subject: 'تحدي 1 ضد 1 في تحدي المليون');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح نافذة المشاركة على هذا الجهاز.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _startFriendChallenge() async {
    final rawCode = _friendCodeController.text.trim().toUpperCase();
    final cleanCode = rawCode.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');

    if (cleanCode.isEmpty) {
      setState(() {
        _errorMessage = 'يرجى إدخال كود الصديق';
      });
      return;
    }

    final appState = context.read<AppState>();
    final myCode = appState.friendCode;

    if (cleanCode == myCode && myCode.isNotEmpty) {
      setState(() {
        _errorMessage = 'لا يمكنك تحدي نفسك! أدخل كود صديقك';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Navigator.of(context).pop(); // Close modal
      await appState.openFriendChallenge(cleanCode);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'تعذر بدء التحدي: $e';
        });
      }
    }
  }

  Future<void> _startRandomMatch() async {
    Navigator.of(context).pop();
    await context.read<AppState>().openSpeedBattle();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final myCode = appState.friendCode;
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final maxWidth = isLandscape ? 620.0 : 420.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F1E4A),
                  Color(0xFF080D24),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sports_esports_rounded,
                          color: Color(0xFF070E24),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تحدي صديق (1 ضد 1)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'شارك كودك أو أدخل كود صديقك لبدء المواجهة',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        tooltip: 'إغلاق',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Card 1: My Code ────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF132252).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.vpn_key_rounded,
                              color: Color(0xFF38BDF8),
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'كود التحدي الخاص بك',
                              style: TextStyle(
                                color: Color(0xFF93C5FD),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF070F28),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  myCode.isNotEmpty ? myCode : '---',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Copy button
                            ElevatedButton.icon(
                              onPressed: myCode.isNotEmpty ? () => _copyMyCode(myCode) : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              label: const Text(
                                'نسخ الكود',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Full invite share
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: myCode.isNotEmpty ? () => _shareMyCode(myCode) : null,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF38BDF8),
                                  side: BorderSide(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.share_rounded, size: 15),
                                label: const Text(
                                  'مشاركة الدعوة كاملة',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Share only code
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: myCode.isNotEmpty ? () => _shareOnlyCode(myCode) : null,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFFFD700),
                                  side: BorderSide(
                                    color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.send_rounded, size: 15),
                                label: const Text(
                                  'إرسال الكود فقط',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Card 2: Enter Friend Code ──────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF132252).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.person_search_rounded,
                              color: Color(0xFFFFD700),
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'أدخل كود صديقك للعب ضده',
                              style: TextStyle(
                                color: Color(0xFFFDE68A),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _friendCodeController,
                                textCapitalization: TextCapitalization.characters,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'أدخل كود صديقك هنا...',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 13,
                                    letterSpacing: 0,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF070F28),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFFFD700),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                onChanged: (_) {
                                  if (_errorMessage != null) {
                                    setState(() => _errorMessage = null);
                                  }
                                },
                                onSubmitted: (_) => _startFriendChallenge(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Paste button
                            ElevatedButton.icon(
                              onPressed: _pasteFromClipboard,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF334155),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.paste_rounded, size: 16),
                              label: const Text(
                                'لصق',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFEF4444),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Start Challenge Button
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFFD700),
                                  Color(0xFFF59E0B),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _startFriendChallenge,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: const Color(0xFF0B1437),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF0B1437),
                                      ),
                                    )
                                  : const Icon(Icons.flash_on_rounded, size: 20),
                              label: Text(
                                _isLoading ? 'جاري بدء التحدي...' : 'بدء التحدي ضد الصديق',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Quick Match Option ─────────────────────────────
                  OutlinedButton.icon(
                    onPressed: _startRandomMatch,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF38BDF8),
                      side: BorderSide(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.shuffle_rounded, size: 18),
                    label: const Text(
                      'أو ابحث عن منافس عشوائي أونلاين',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
