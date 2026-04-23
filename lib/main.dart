import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'screens/auth/auth_gate.dart';
import 'services/auth_service.dart';
import 'services/native_bridge_service.dart';
import 'services/profile_service.dart'; // still needed by other screens
import 'services/iap_service.dart';
import 'services/room_service.dart';
import 'services/ad_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // إخفاء شريط الحالة وأزرار التنقل (الرجوع / Home) نهائياً في كل الشاشات
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  try {
    await Firebase.initializeApp();
  } catch (_) {
    // يسمح بفتح الواجهة حتى قبل تهيئة Firebase الكاملة.
  }

  final adService = AdService();
  await adService.initialize();

  runApp(MillionaireOnlineApp(adService: adService));
}

class MillionaireOnlineApp extends StatelessWidget {
  const MillionaireOnlineApp({super.key, required this.adService});

  final AdService adService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AdService>.value(value: adService),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<ProfileService>(create: (_) => ProfileService()),
        Provider<NativeBridgeService>(create: (_) => NativeBridgeService()),
        Provider<RoomService>(create: (_) => RoomService()),
        ChangeNotifierProvider<IapService>(
          create: (context) {
            final svc = IapService(context.read<NativeBridgeService>());
            svc.init();
            return svc;
          },
        ),
        ChangeNotifierProxyProvider2<AuthService, NativeBridgeService, AppState>(
          create: (context) => AppState(
            authService: context.read<AuthService>(),
            nativeBridgeService: context.read<NativeBridgeService>(),
          ),
          update: (context, auth, nativeBridge, previous) =>
              previous ??
              AppState(
                authService: auth,
                nativeBridgeService: nativeBridge,
              ),
        ),
      ],
      child: MaterialApp(
        title: 'تحدي المليون',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const <Locale>[Locale('ar')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          fontFamily: 'Baloo',
          scaffoldBackgroundColor: const Color(0xFF030712),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF7C3AED),
            secondary: Color(0xFF38BDF8),
            surface: Color(0xFF0B173F),
          ),
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF0B173F),
            contentTextStyle: TextStyle(color: Colors.white, fontSize: 15),
          ),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
            bodyLarge: TextStyle(color: Colors.white),
            titleMedium: TextStyle(color: Colors.white),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withValues(alpha:0.08),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIconColor: const Color(0xFF7DD3FC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.white.withValues(alpha:0.18)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.white.withValues(alpha:0.18)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFF7DD3FC), width: 1.8),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6D28D9),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha:0.22)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}
