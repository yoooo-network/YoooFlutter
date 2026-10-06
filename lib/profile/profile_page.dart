import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../settings/settings_page.dart';
import 'sections/about_section.dart';
import 'sections/physic_section.dart';
import 'sections/pricing_section.dart';
import 'sections/services_section.dart';
import 'widgets/menu_header.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.profileId});

  final String profileId;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final PageController _pageController;
  int _currentIndex = 2;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/profile/${widget.profileId}'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _profile = data['data']['profile'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showBookingForm() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final messageController = TextEditingController();
    var isSubmitting = false;
    String? submitError;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Book ${_profile?['name'] ?? 'profile'}'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (submitError != null) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(submitError!, style: const TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 100,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) => (value?.trim().length ?? 0) < 2
                          ? 'Enter your name (at least 2 characters)'
                          : null,
                    ),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 40,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      validator: (value) => (value?.trim().length ?? 0) < 5
                          ? 'Enter a valid phone number'
                          : null,
                    ),
                    TextFormField(
                      controller: messageController,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        hintText: 'Mention place, time and requirements',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) => (value?.trim().length ?? 0) < 5
                          ? 'Enter a message (at least 5 characters)'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        isSubmitting = true;
                        submitError = null;
                      });
                      try {
                        final response = await http.post(
                          Uri.parse('${ApiEndpoints.baseUrl}/profile/${Uri.encodeComponent(widget.profileId)}/book'),
                          headers: {'Accept': 'application/json'},
                          body: {
                            'name': nameController.text.trim(),
                            'phone': phoneController.text.trim(),
                            'message': messageController.text.trim(),
                          },
                        );
                        final decoded = json.decode(response.body);
                        final responseMap = decoded is Map<String, dynamic>
                            ? decoded
                            : <String, dynamic>{};
                        if ((response.statusCode == 200 || response.statusCode == 201) &&
                            responseMap['status'] == 'success') {
                          if (dialogContext.mounted) {
                            Navigator.pop(
                              dialogContext,
                              responseMap['message']?.toString() ?? 'Your booking request has been sent.',
                            );
                          }
                        } else {
                          final apiErrors = responseMap['errors'];
                          final details = apiErrors is Map
                              ? apiErrors.values.map((value) => value.toString()).join('\n')
                              : null;
                          setDialogState(() {
                            submitError = details?.isNotEmpty == true
                                ? details
                                : (responseMap['message']?.toString() ?? 'Could not send your booking request.');
                            isSubmitting = false;
                          });
                        }
                      } catch (_) {
                        setDialogState(() {
                          submitError = 'Connection error. Please try again.';
                          isSubmitting = false;
                        });
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Book Now'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    phoneController.dispose();
    messageController.dispose();
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onMenuTap(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  int _calculateAge(String? dob) {
    if (dob == null) return 0;
    try {
      final birthDate = DateTime.parse(dob);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _profile == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Profile not found'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchProfile, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final String name = _profile!['name'] ?? 'Unknown';
    final String location = _profile!['location'] ?? '';
    final int age = _calculateAge(_profile!['dob']);
    final String height = _profile!['height'] ?? '';
    final String weight = _profile!['weight'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        age > 0 ? '$age yrs' : '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${height}cm • ${weight}kg',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: const Color(0xFFE5E7EB),
            ),
            ProfileMenuBar(
              currentIndex: _currentIndex,
              onTap: _onMenuTap,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) =>
                    setState(() => _currentIndex = index),
                children: [
                  _AboutPage(profile: _profile!),
                  _PhysiquePage(profile: _profile!),
                  _HomePage(profile: _profile!),
                  _ServicesPage(profile: _profile!),
                  _PricePage(profile: _profile!),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: _showBookingForm,
              child: const Text('Book Now'),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: child,
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({required this.profile});

  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    List<String> images = [];
    try {
      if (profile['images'] != null) {
        final decoded = json.decode(profile['images']);
        if (decoded is List) {
          images = decoded.map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}

    if (images.isEmpty) {
      images = ['https://www.yooo.app/images/yoooo-male.webp'];
    }

    return SizedBox.expand(
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          final img = images[index];
          final url = img.startsWith('http') ? img : '${ApiEndpoints.cdnUrl}images/users/$img';
          
          return Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AboutPage extends StatelessWidget {
  const _AboutPage({required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      child: Column(
        children: [
          AboutSection(profile: profile),
        ],
      ),
    );
  }
}

class _PhysiquePage extends StatelessWidget {
  const _PhysiquePage({required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      child: Column(
        children: [
          PhysicSection(profile: profile),
        ],
      ),
    );
  }
}

class _ServicesPage extends StatelessWidget {
  const _ServicesPage({required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      child: Column(
        children: [
          ServicesSection(profile: profile),
        ],
      ),
    );
  }
}

class _PricePage extends StatelessWidget {
  const _PricePage({required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      child: Column(
        children: [
          PricingSection(profile: profile),
        ],
      ),
    );
  }
}
