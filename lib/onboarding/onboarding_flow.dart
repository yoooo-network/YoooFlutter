import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../main_page/main_page.dart';
import '../update/update_dialog.dart';
import '../update/update_service.dart';
import 'intent_screen.dart';
import 'location_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _controller = PageController();
  final UpdateService _updateService = UpdateService();
  int _step = 0;
  String? _intent;
  String? _country;
  String? _city;
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    if (!mounted) return;
    setState(() => _isCheckingUpdate = true);
    final update = await _updateService.checkForUpdate();
    if (!mounted) return;
    setState(() => _isCheckingUpdate = false);

    if (update == null) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: !update.forceUpdate,
      builder: (context) {
        final navigator = Navigator.of(context);
        return UpdateDialog(
          update: update,
          onUpdate: () async {
            final didOpen = await _updateService.openUpdateUrl(update.apkUrl);
            if (!mounted) return;
            if (didOpen && !update.forceUpdate) {
              navigator.pop();
            }
          },
        );
      },
    );
  }

  void _next() {
    if (_step < 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _goToMain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(YoooApp.onboardingCompleteKey, true);

    // Persist onboarding selections so preferences survive app relaunch.
    if (_intent != null) {
      await prefs.setString(YoooApp.onboardingIntentKey, _intent!);
    } else {
      await prefs.remove(YoooApp.onboardingIntentKey);
    }
    if (_country != null) {
      await prefs.setString(YoooApp.onboardingCountryKey, _country!);
    } else {
      await prefs.remove(YoooApp.onboardingCountryKey);
    }
    if (_city != null) {
      await prefs.setString(YoooApp.onboardingCityKey, _city!);
    } else {
      await prefs.remove(YoooApp.onboardingCityKey);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainPage(
          intent: _intent,
          country: _country,
          city: _city,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF8FAFC), Color(0xFFE2F2EF)],
              ),
            ),
            child: SafeArea(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) => setState(() => _step = index),
                children: [
                  IntentScreen(
                    step: _step,
                    selected: _intent,
                    onSelect: (value) => setState(() => _intent = value),
                    onNext: _next,
                  ),
                  LocationScreen(
                    step: _step,
                    onContinue: (country, city) async {
                      setState(() {
                        _country = country;
                        _city = city;
                      });
                      await _goToMain();
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_isCheckingUpdate)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
