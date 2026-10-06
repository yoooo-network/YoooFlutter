import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../main_page/main_page.dart';
import '../settings/settings_page.dart';
import 'profile_setup/steps/basic_info_step.dart';
import 'profile_setup/steps/contact_details_step.dart';
import 'profile_setup/steps/gender_sexuality_step.dart';
import 'profile_setup/steps/languages_step.dart';
import 'profile_setup/steps/physical_details_step.dart';
import 'profile_setup/steps/photos_step.dart';
import 'profile_setup/steps/pricing_step.dart';
import 'profile_setup/steps/services_step.dart';
import 'user_panel_footer_bar.dart';
import 'user_panel_header_bar.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> _profileData = {};
  int? _footerHoverIndex;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        if (mounted) Navigator.of(context).pop();
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final profile = data['data']?['profile'];
        if (data['status'] == 'success' && profile is Map) {
          _profileData = _normalizeProfileForUi(
            Map<String, dynamic>.from(profile),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateProfileData(Map<String, dynamic> newData) {
    _profileData = {..._profileData, ...newData};
  }

  Future<bool> _saveProfileData(Map<String, dynamic> sectionData) async {
    setState(() => _isSaving = true);
    try {
      _updateProfileData(sectionData);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/user/profile/update'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(_buildApiPayload(_profileData)),
      );

      final data = response.body.isNotEmpty ? json.decode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully.')),
          );
          await _fetchProfileData();
        }
        return true;
      }

      final errors = data['errors'];
      final message = errors is Map
          ? errors.entries.map((e) => '${e.key}: ${e.value}').join(', ')
          : data['message']?.toString();
      throw Exception(message ?? 'Failed to update profile');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _isFilled(dynamic value) {
    if (value is Map) return value.values.any(_isFilled);
    if (value is Iterable) return value.any(_isFilled);
    return (value ?? '').toString().trim().isNotEmpty;
  }

  bool _hasFields(List<String> fields) {
    return fields.every((field) => _isFilled(_profileData[field]));
  }

  bool _hasLanguages() => _isFilled(_profileData['languages']);

  bool _hasPricing() => _isFilled(_profileData['pricing']);

  bool _hasServices() => _isFilled(_profileData['services']);

  bool _hasPhotos() => _isFilled(_profileData['images']);

  bool _hasGender() {
    final sexuality = _profileData['sexuality'];
    final types = sexuality is Map ? sexuality['types'] : sexuality;
    final roles = sexuality is Map ? sexuality['roles'] : null;
    final needsRole =
        types is Iterable &&
        (types.contains('Homo') || types.contains('Bisexual'));
    return _isFilled(_profileData['gender']) &&
        _isFilled(types) &&
        (!needsRole || _isFilled(roles));
  }

  List<_EditProfileCardData> get _cards => [
    _EditProfileCardData(
      title: 'Basic Info',
      description: 'Name, location, and bio',
      icon: Icons.person_pin_rounded,
      color: const Color(0xFF7C3AED),
      complete: _hasFields(['name', 'dob', 'location', 'description']),
      builder: (data, onChanged) =>
          BasicInfoStep(initialData: data, onChanged: onChanged),
    ),
    _EditProfileCardData(
      title: 'Gender & Sexuality',
      description: 'Identity and orientation details',
      icon: Icons.transgender_rounded,
      color: const Color(0xFFDB2777),
      complete: _hasGender(),
      builder: (data, onChanged) =>
          GenderSexualityStep(initialData: data, onChanged: onChanged),
    ),
    _EditProfileCardData(
      title: 'Physical Details',
      description: 'Height, measurements, hair & eyes',
      icon: Icons.straighten_rounded,
      color: const Color(0xFF2563EB),
      complete: _hasFields([
        'height',
        'weight',
        'eye_color',
        'hair_type',
        'skin_color',
        'body_structure',
        'ethnicity',
      ]),
      builder: (data, onChanged) =>
          PhysicalDetailsStep(initialData: data, onChanged: onChanged),
    ),
    _EditProfileCardData(
      title: 'Contact Details',
      description: 'Phone, email, and social links',
      icon: Icons.phone_rounded,
      color: const Color(0xFF059669),
      complete: _isFilled(_profileData['phone']),
      builder: (data, onChanged) =>
          ContactDetailsStep(initialData: data, onChanged: onChanged),
    ),
    _EditProfileCardData(
      title: 'Language',
      description: 'Spoken and written languages',
      icon: Icons.translate_rounded,
      color: const Color(0xFFEA580C),
      complete: _hasLanguages(),
      builder: (data, onChanged) =>
          LanguagesStep(initialData: data, onChanged: onChanged),
    ),
    _EditProfileCardData(
      title: 'Pricing',
      description: 'Rates for different assignments',
      icon: Icons.local_offer_rounded,
      color: const Color(0xFFD97706),
      complete: _hasPricing(),
      builder: (data, onChanged) =>
          PricingStep(initialData: data, onChanged: onChanged),
    ),
    _EditProfileCardData(
      title: 'Services',
      description: 'Types of work offered',
      icon: Icons.work_rounded,
      color: const Color(0xFF0891B2),
      complete: _hasServices(),
      builder: (data, onChanged) =>
          ServicesStep(initialData: data, onChanged: onChanged),
    ),
    _EditProfileCardData(
      title: 'Upload Photos',
      description: 'Manage portfolio and gallery',
      icon: Icons.photo_library_rounded,
      color: const Color(0xFFC026D3),
      complete: _hasPhotos(),
      builder: (data, onChanged) =>
          PhotosStep(initialData: data, onChanged: onChanged),
    ),
  ];

  Future<void> _openForm(_EditProfileCardData card) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _ProfileFormPage(
          card: card,
          initialData: Map<String, dynamic>.from(_profileData),
          onSave: _saveProfileData,
        ),
      ),
    );
    if (result == true) {
      await _fetchProfileData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: UserPanelHeaderBar(
        title: 'Edit Profile',
        onBackToMainPage: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainPage()),
          (route) => false,
        ),
      ),
      bottomNavigationBar: UserPanelFooterBar(
        currentTab: UserPanelTab.edit,
        hoverIndex: _footerHoverIndex,
        onHover: (index) => setState(() => _footerHoverIndex = index),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProfileData,
        child: Stack(
          children: [
            GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 520,
                mainAxisExtent: 104,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return _EditProfileCard(
                  data: card,
                  onTap: () => _openForm(card),
                );
              },
            ),
            if (_isSaving)
              Container(
                color: Colors.black.withValues(alpha: 0.08),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileFormPage extends StatefulWidget {
  const _ProfileFormPage({
    required this.card,
    required this.initialData,
    required this.onSave,
  });

  final _EditProfileCardData card;
  final Map<String, dynamic> initialData;
  final Future<bool> Function(Map<String, dynamic>) onSave;

  @override
  State<_ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends State<_ProfileFormPage> {
  late Map<String, dynamic> _data;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.initialData);
  }

  void _onChanged(Map<String, dynamic> newData) {
    _data = {..._data, ...newData};
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final ok = await widget.onSave(_data);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.card.title),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(child: widget.card.builder(_data, _onChanged)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text('Save'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: widget.card.color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileCard extends StatelessWidget {
  const _EditProfileCard({required this.data, required this.onTap});

  final _EditProfileCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stateColor = data.complete
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);
    final background = data.complete
        ? const Color(0xFFF0FDF4)
        : const Color(0xFFFEF2F2);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: stateColor.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(data.icon, color: data.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: data.complete
                            ? const Color(0xFF14532D)
                            : const Color(0xFF7F1D1D),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: stateColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  data.complete
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: stateColor,
                  size: 22,
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditProfileCardData {
  const _EditProfileCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.complete,
    required this.builder,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool complete;
  final Widget Function(
    Map<String, dynamic> data,
    Function(Map<String, dynamic>) onChanged,
  )
  builder;
}

Map<String, dynamic> _normalizeProfileForUi(Map<String, dynamic> profile) {
  final normalized = Map<String, dynamic>.from(profile);

  final pricingRaw = normalized['pricing'];
  if (pricingRaw is String && pricingRaw.trim().isNotEmpty) {
    try {
      normalized['pricing'] = json.decode(pricingRaw);
    } catch (_) {}
  }
  final pricing = normalized['pricing'];
  if (pricing is Map) {
    if (pricing.containsKey('rates')) {
      normalized['pricing'] = {
        'currency': (normalized['currency'] ?? 'INR').toString(),
        'rates': Map<String, dynamic>.from(pricing['rates'] ?? const {}),
      };
    } else {
      final rates = <String, String>{};
      String currency = (normalized['currency'] ?? 'INR').toString();
      for (final key in ['1hr', '3hr', 'night', 'week', 'month']) {
        final val = pricing[key]?.toString() ?? '';
        final currencyMatch = RegExp(r'([A-Za-z]{3})$').firstMatch(val);
        if (currencyMatch != null) currency = currencyMatch.group(1)!;
        rates[key] =
            RegExp(r'^(\d+(?:\.\d+)?)').firstMatch(val)?.group(1) ?? '';
      }
      normalized['pricing'] = {'currency': currency, 'rates': rates};
    }
  }

  for (final key in ['services', 'languages', 'sexuality', 'images']) {
    final raw = normalized[key];
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        normalized[key] = json.decode(raw);
      } catch (_) {}
    }
  }

  final servicesRaw = normalized['services'];
  if (servicesRaw is Map && servicesRaw.containsKey('selected')) {
    normalized['services'] = {
      'list': List<String>.from(servicesRaw['selected'] ?? const []),
      'other': (servicesRaw['other'] ?? '').toString(),
    };
  }

  final languagesRaw = normalized['languages'];
  if (languagesRaw is Map) {
    normalized['languages'] = {
      'selected': List<String>.from(languagesRaw['selected'] ?? const []),
      'others': (languagesRaw['other'] ?? languagesRaw['others'] ?? '')
          .toString(),
    };
  }

  final sexualityRaw = normalized['sexuality'];
  if (sexualityRaw is Map) {
    normalized['sexuality'] = {
      'types': List<String>.from(sexualityRaw['types'] ?? const []),
      'roles': List<String>.from(sexualityRaw['roles'] ?? const []),
    };
  } else if (sexualityRaw is List) {
    final all = sexualityRaw.map((e) => e.toString()).toList();
    final typeSet = <String>{'Straight', 'Homo', 'Bisexual'};
    normalized['sexuality'] = {
      'types': all.where(typeSet.contains).toList(),
      'roles': all.where((s) => !typeSet.contains(s)).toList(),
    };
  }

  return normalized;
}

Map<String, dynamic> _buildApiPayload(Map<String, dynamic> source) {
  final payload = Map<String, dynamic>.from(source);

  final rawGender = (payload['gender'] ?? '').toString().trim().toLowerCase();
  if (rawGender.isNotEmpty) {
    payload['gender'] = switch (rawGender) {
      'male' => 'male',
      'female' => 'female',
      'other' || 'trans' => 'other',
      _ => rawGender,
    };
  }

  final pricing = payload['pricing'];
  if (pricing is Map) {
    final currency = (pricing['currency'] ?? payload['currency'] ?? 'INR')
        .toString()
        .toUpperCase();
    final ratesRaw = pricing['rates'];
    final rates = ratesRaw is Map
        ? Map<String, dynamic>.from(ratesRaw)
        : <String, dynamic>{};
    String normalizeRate(dynamic value) {
      final raw = (value ?? '').toString().trim();
      final numeric = RegExp(r'^(\d+(?:\.\d+)?)').firstMatch(raw)?.group(1);
      return numeric == null || numeric.isEmpty ? '' : '$numeric$currency';
    }

    payload['pricing'] = {
      '1hr': normalizeRate(rates['1hr']),
      '3hr': normalizeRate(rates['3hr']),
      'night': normalizeRate(rates['night']),
      'week': normalizeRate(rates['week']),
      'month': normalizeRate(rates['month']),
    };
  }

  final services = payload['services'];
  if (services is Map) {
    payload['services'] = {
      'selected': List<String>.from(services['list'] ?? const []),
      'other': (services['other'] ?? '').toString(),
    };
  }

  final languages = payload['languages'];
  if (languages is Map) {
    payload['languages'] = {
      'selected': List<String>.from(languages['selected'] ?? const []),
      'other': (languages['others'] ?? '').toString(),
    };
  }

  final sexuality = payload['sexuality'];
  if (sexuality is Map) {
    payload['sexuality'] = {
      'types': List<String>.from(sexuality['types'] ?? const []),
      'roles': List<String>.from(sexuality['roles'] ?? const []),
    };
  }

  return payload;
}
