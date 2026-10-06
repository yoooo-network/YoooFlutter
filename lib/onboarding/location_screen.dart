import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../settings/settings_page.dart';
import 'onboarding_shared.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({
    super.key,
    required this.step,
    required this.onContinue,
  });

  final int step;
  final Function(String? country, String? city) onContinue;

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String? _country;
  String? _city;
  List<dynamic> _countriesList = [];
  List<dynamic> _citiesList = [];
  bool _isLoadingCountries = true;
  bool _isLoadingCities = false;

  @override
  void initState() {
    super.initState();
    _fetchCountries();
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
        });
      } else {
        setState(() => _isLoadingCountries = false);
      }
    } catch (e) {
      setState(() => _isLoadingCountries = false);
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
        });
      }
    } catch (e) {
      setState(() => _isLoadingCities = false);
    }
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
    final countryItems = _countriesList.map<String>((c) => c['name'].toString()).toList();
    final cityItems = _citiesList.map<String>((c) => c['name'].toString()).toList();

    return OnboardingScaffold(
      step: widget.step,
      title: 'Select Location',
      subtitle: 'Choose your country and city to find escorts near you.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _FieldLabel(label: 'Country'),
          const SizedBox(height: 8),
          _isLoadingCountries
              ? const Center(child: CircularProgressIndicator())
              : _buildDropdown(
                  context,
                  value: _country,
                  items: countryItems,
                  hint: 'Choose country',
                  onChanged: _onCountryChanged,
                ),
          const SizedBox(height: 20),
          _FieldLabel(label: 'City (Optional)'),
          const SizedBox(height: 8),
          _isLoadingCities
              ? const Center(child: CircularProgressIndicator())
              : _buildDropdown(
                  context,
                  value: _city,
                  items: cityItems,
                  hint: _country == null ? 'Select a country first' : 'Choose city',
                  onChanged: (value) => setState(() => _city = value),
                ),
        ],
      ),
      bottom: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _country == null
              ? null
              : () => widget.onContinue(_country, _city),
          child: const Text('Continue'),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final validValue = (value != null && items.contains(value)) ? value : null;

    return DropdownButtonFormField<String>(
      value: validValue,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
