import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiEndpoints {
  static const String baseUrl = 'https://api.yooo.app/api/v1';
  static const String cdnUrl = 'https://cdn.yooo.app/';
  static const String countries = '$baseUrl/countries';
  static const String profiles = '$baseUrl/profiles';
  static String cities(int countryId) => '$baseUrl/cities?country_id=$countryId';
}

class SettingsData {
  const SettingsData({
    this.category,
    this.country,
    this.city,
  });

  final String? category;
  final String? country;
  final String? city;
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.category,
    required this.country,
    required this.city,
    required this.onSave,
  });

  final String? category;
  final String? country;
  final String? city;
  final ValueChanged<SettingsData> onSave;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _categories = [
    'Male escort',
    'Female escort',
    'Trans escort',
    'Gay escort',
  ];

  late String? _category;
  late String? _country;
  late String? _city;

  List<dynamic> _countriesList = [];
  List<dynamic> _citiesList = [];
  bool _isLoadingCountries = true;
  bool _isLoadingCities = false;

  @override
  void initState() {
    super.initState();
    _category = widget.category;
    _country = widget.country;
    _city = widget.city;
    
    _fetchCountries().then((_) {
      if (_country != null) {
        final cId = _getCountryId(_country);
        if (cId != null) {
          _fetchCities(cId);
        }
      }
    });
  }

  int? _getCountryId(String? countryName) {
    if (countryName == null) return null;
    try {
      final country = _countriesList.firstWhere((c) => c['name'] == countryName);
      return int.tryParse(country['id'].toString());
    } catch (e) {
      return null;
    }
  }

  Future<void> _fetchCountries() async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.countries),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _countriesList = (data['data'] != null ? data['data']['countries'] : null) ?? [];
          _isLoadingCountries = false;
          
          // Ensure current selected country is in the list
          if (_country != null && !_countriesList.any((c) => c['name'] == _country)) {
            _country = null;
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load countries: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      print('Error fetching countries: $e');
      setState(() => _isLoadingCountries = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')),
        );
      }
    }
  }

  Future<void> _fetchCities(int countryId) async {
    setState(() => _isLoadingCities = true);
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.cities(countryId)),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _citiesList = (data['data'] != null ? data['data']['cities'] : null) ?? [];
          _isLoadingCities = false;
          
          // Ensure current selected city is in the list
          if (_city != null && !_citiesList.any((c) => c['name'] == _city)) {
            _city = null;
          }
        });
      }
    } catch (e) {
      setState(() => _isLoadingCities = false);
    }
  }

  void _onCountryChanged(String? newCountry) {
    setState(() {
      _country = newCountry;
      _city = null;
      _citiesList = [];
    });
    
    final cId = _getCountryId(newCountry);
    if (cId != null) {
      _fetchCities(cId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final countryItems = _countriesList.map<String>((c) => c['name'].toString()).toList();
    final cityItems = _citiesList.map<String>((c) => c['name'].toString()).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Update your preferences anytime.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 20),
        _FieldGroup(
          label: 'Select category',
          child: _buildDropdown(
            context,
            value: _category,
            items: _categories,
            hint: 'Choose category',
            onChanged: (value) => setState(() => _category = value),
          ),
        ),
        const SizedBox(height: 14),
        _FieldGroup(
          label: 'Select country',
          child: _isLoadingCountries
              ? const Center(child: CircularProgressIndicator())
              : _buildDropdown(
                  context,
                  value: _country,
                  items: countryItems,
                  hint: 'Choose country',
                  onChanged: _onCountryChanged,
                ),
        ),
        const SizedBox(height: 14),
        _FieldGroup(
          label: 'Select city (Optional)',
          child: _isLoadingCities
              ? const Center(child: CircularProgressIndicator())
              : _buildDropdown(
                  context,
                  value: _city,
                  items: cityItems,
                  hint: _country == null ? 'Select a country first' : 'Choose city',
                  onChanged: (value) => setState(() => _city = value),
                ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: (_category != null && _country != null)
              ? () async {
                  final data = SettingsData(
                    category: _category,
                    country: _country,
                    city: _city,
                  );

                  // Persist as onboarding preferences so they are restored on next launch.
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('onboarding_complete', true);
                  await prefs.setString('onboarding_intent', data.category!);
                  await prefs.setString('onboarding_country', data.country!);
                  if (data.city != null && data.city!.isNotEmpty) {
                    await prefs.setString('onboarding_city', data.city!);
                  } else {
                    await prefs.remove('onboarding_city');
                  }

                  widget.onSave(data);
                }
              : null,
          child: const Text('Save settings'),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    // Ensure value exists in items or is null
    final validValue = (value != null && items.contains(value)) ? value : null;
    
    return DropdownButtonFormField<String>(
      value: validValue,
      isExpanded: true,
      decoration: _inputDecoration(context, hintText: hint),
      items: items
          .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hintText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
    );
  }
}

class _FieldGroup extends StatelessWidget {
  const _FieldGroup({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

