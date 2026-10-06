import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'http_overrides_stub.dart' if (dart.library.io) 'http_overrides_io.dart';
import 'main_page/main_page.dart';
import 'onboarding/onboarding_flow.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setHttpOverrides();
  runApp(const YoooApp());
}

class YoooApp extends StatelessWidget {
  const YoooApp({super.key});

  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String onboardingIntentKey = 'onboarding_intent';
  static const String onboardingCountryKey = 'onboarding_country';
  static const String onboardingCityKey = 'onboarding_city';

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0F766E);
    return MaterialApp(
      title: 'Yooo.App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Use a system-safe font to avoid web runtime fetches from fonts.gstatic.
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
      home: const _AppEntryGate(),
    );
  }
}

class _AppEntryGate extends StatefulWidget {
  const _AppEntryGate();

  @override
  State<_AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<_AppEntryGate> {
  bool? _onboardingComplete;
  String? _intent;
  String? _country;
  String? _city;

  @override
  void initState() {
    super.initState();
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(YoooApp.onboardingCompleteKey) ?? false;
    final intent = prefs.getString(YoooApp.onboardingIntentKey);
    final country = prefs.getString(YoooApp.onboardingCountryKey);
    final city = prefs.getString(YoooApp.onboardingCityKey);
    if (!mounted) return;
    setState(() {
      _onboardingComplete = completed;
      _intent = intent;
      _country = country;
      _city = city;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingComplete == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_onboardingComplete == true) {
      return MainPage(
        intent: _intent,
        country: _country,
        city: _city,
      );
    }
    return const OnboardingFlow();
  }
}
