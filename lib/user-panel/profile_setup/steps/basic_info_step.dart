import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../settings/settings_page.dart';

class BasicInfoStep extends StatefulWidget {
  const BasicInfoStep({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onChanged;

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late TextEditingController _descriptionController;
  String? _selectedCountry;
  String? _selectedCity;
  List<dynamic> _countriesList = [];
  List<dynamic> _citiesList = [];
  bool _isLoadingCountries = true;
  bool _isLoadingCities = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['name']);
    _dobController = TextEditingController(text: widget.initialData['dob']);
    _descriptionController = TextEditingController(text: widget.initialData['description']);
    _selectedCountry = widget.initialData['country_id']?.toString();
    _selectedCity = widget.initialData['city_id']?.toString();
    _fetchCountries();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _update() {
    final countryName = _getCountryName(_selectedCountry);
    final cityName = _getCityName(_selectedCity);
    final location = (countryName != null && cityName != null) ? '$cityName, $countryName' : null;

    widget.onChanged({
      'name': _nameController.text,
      'dob': _dobController.text,
      'description': _descriptionController.text,
      'country_id': _selectedCountry,
      'city_id': _selectedCity,
      'location': location,
    });
  }

  String? _getCountryName(String? countryId) {
    if (countryId == null) return null;
    for (final c in _countriesList) {
      if (c['id']?.toString() == countryId) return c['name']?.toString();
    }
    return null;
  }

  String? _getCityName(String? cityId) {
    if (cityId == null) return null;
    for (final c in _citiesList) {
      if (c['id']?.toString() == cityId) return c['name']?.toString();
    }
    return null;
  }

  Future<void> _fetchCountries() async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.countries),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final countries = (data['data'] != null ? data['data']['countries'] : null) ?? [];
        String? nextCountry = _selectedCountry;
        String? preselectCityName;

        final location = widget.initialData['location']?.toString() ?? '';
        if (nextCountry == null && location.contains(',')) {
          final parts = location.split(',');
          preselectCityName = parts.first.trim();
          final countryName = parts.last.trim();
          final countryMatch = countries.cast<dynamic?>().firstWhere(
            (c) => c != null && c['name']?.toString() == countryName,
            orElse: () => null,
          );
          if (countryMatch != null) {
            nextCountry = countryMatch['id']?.toString();
          }
        }

        if (mounted) {
          setState(() {
            _countriesList = countries;
            _selectedCountry = nextCountry;
            _isLoadingCountries = false;
          });
          if (_selectedCountry != null) {
            _fetchCities(_selectedCountry!, preselectCityName: preselectCityName);
          }
        }
      } else if (mounted) {
        setState(() => _isLoadingCountries = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCountries = false);
    }
  }

  Future<void> _fetchCities(String countryId, {String? preselectCityName}) async {
    setState(() => _isLoadingCities = true);
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.cities(int.parse(countryId))),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final cities = (data['data'] != null ? data['data']['cities'] : null) ?? [];
        String? nextCity = _selectedCity;
        if (preselectCityName != null) {
          final cityMatch = cities.cast<dynamic?>().firstWhere(
            (c) => c != null && c['name']?.toString() == preselectCityName,
            orElse: () => null,
          );
          nextCity = cityMatch?['id']?.toString();
        }
        if (mounted) {
          setState(() {
            _citiesList = cities;
            _selectedCity = nextCity;
            _isLoadingCities = false;
          });
          _update();
        }
      } else if (mounted) {
        setState(() => _isLoadingCities = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCities = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.toLocal()}".split(' ')[0];
      });
      _update();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Enter your full name',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _update(),
          ),
          const SizedBox(height: 16),
          const Text('Date of Birth', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _dobController,
            decoration: const InputDecoration(
              hintText: 'YYYY-MM-DD',
              suffixIcon: Icon(Icons.calendar_today),
              border: OutlineInputBorder(),
            ),
            readOnly: true,
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 16),
          const Text('Country', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _isLoadingCountries
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  decoration: const InputDecoration(
                    hintText: 'Select Country',
                    border: OutlineInputBorder(),
                  ),
                  items: _countriesList.map<DropdownMenuItem<String>>((country) {
                    return DropdownMenuItem<String>(
                      value: country['id'].toString(),
                      child: Text(country['name'].toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCountry = value;
                      _selectedCity = null;
                      _citiesList = [];
                    });
                    _update();
                    if (value != null) {
                      _fetchCities(value);
                    }
                  },
                ),
          const SizedBox(height: 16),
          const Text('City', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _isLoadingCities
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: const InputDecoration(
                    hintText: 'Select City',
                    border: OutlineInputBorder(),
                  ),
                  items: _citiesList.map<DropdownMenuItem<String>>((city) {
                    return DropdownMenuItem<String>(
                      value: city['id'].toString(),
                      child: Text(city['name'].toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCity = value;
                    });
                    _update();
                  },
                ),
          const SizedBox(height: 16),
          const Text('About You', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Write a short description about yourself...',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _update(),
          ),
        ],
      ),
    );
  }
}
