import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/settings_page.dart';
import 'profile_setup/steps/verify_step.dart';

class VerifyProfilePage extends StatefulWidget {
  const VerifyProfilePage({super.key});

  @override
  State<VerifyProfilePage> createState() => _VerifyProfilePageState();
}

class _VerifyProfilePageState extends State<VerifyProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic> _profileData = {};

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) return;

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
          _profileData = Map<String, dynamic>.from(profile);
        }
      }
    } catch (e) {
      debugPrint('Verification profile fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateProfileData(Map<String, dynamic> newData) {
    setState(() => _profileData = {..._profileData, ...newData});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Verify Profile'),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : VerifyStep(
              initialData: _profileData,
              onChanged: _updateProfileData,
            ),
    );
  }
}
