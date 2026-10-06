import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'bottom_nav_bar.dart';
import 'header_bar.dart';
import '../filters/filter_page.dart';
import '../settings/settings_page.dart';
import '../profile/profile_page.dart';
import '../user-panel/login_page.dart';
import '../user-panel/dashboard_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key, this.intent, this.country, this.city});

  final String? intent;
  final String? country;
  final String? city;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _navIndex = 0;
  int? _hoverIndex;
  String? _intent;
  String? _country;
  String? _city;
  FilterData? _filters;
  bool _isLoggedIn = false;
  final String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _intent = widget.intent;
    _country = widget.country;
    _city = widget.city;
    _filters ??= const FilterData();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      setState(() {
        _isLoggedIn = true;
      });
    }
  }

  void _setHover(int? index) {
    if (_hoverIndex == index) return;
    setState(() => _hoverIndex = index);
  }

  void _onNavTap(int index) {
    if (index == 2 && !_isLoggedIn) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const LoginPage()))
          .then((_) => _checkLoginStatus());
      return;
    }
    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _navIndex == 2 && _isLoggedIn
          ? null // Hide header bar on dashboard
          : HeaderBar(intent: _intent, country: _country),
      body: _buildBody(),
      bottomNavigationBar: _navIndex == 2 && _isLoggedIn
          ? null
          : BottomNavBar(
              currentIndex: _navIndex,
              hoverIndex: _hoverIndex,
              onHover: _setHover,
              onTap: _onNavTap,
            ),
    );
  }

  Widget _buildBody() {
    if (_navIndex == 3) {
      return SettingsPage(
        category: _intent,
        country: _country,
        city: _city,
        onSave: (data) {
          setState(() {
            _intent = data.category;
            _country = data.country;
            _city = data.city;
            _navIndex = 0;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Settings saved')));
        },
      );
    }

    if (_navIndex == 1) {
      return FilterPage(
        data: _filters ?? const FilterData(),
        onApply: (data) {
          setState(() => _filters = data);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Filters applied')));
        },
      );
    }

    if (_navIndex == 2 && _isLoggedIn) {
      return UserDashboardPage(
        userName: _userName,
        onFooterTap: _onNavTap,
        onBackToMainPage: () => _onNavTap(0),
      );
    }

    return _HomeContent(
      intent: _intent,
      country: _country,
      city: _city,
      filters: _filters,
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent({
    required this.intent,
    required this.country,
    required this.city,
    this.filters,
  });

  final String? intent;
  final String? country;
  final String? city;
  final FilterData? filters;

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  List<dynamic> _profiles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  @override
  void didUpdateWidget(_HomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intent != widget.intent ||
        oldWidget.country != widget.country ||
        oldWidget.city != widget.city ||
        oldWidget.filters != widget.filters) {
      _fetchProfiles();
    }
  }

  String _mapIntentToGender(String? intent) {
    if (intent == null) return 'female';
    final lower = intent.toLowerCase();
    if (lower.contains('female')) return 'female';
    if (lower.contains('male') && !lower.contains('female')) return 'male';
    if (lower.contains('trans')) return 'trans';
    if (lower.contains('gay')) return 'gay';
    return 'female';
  }

  Future<void> _fetchProfiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final gender = _mapIntentToGender(widget.intent);
      final queryParams = {
        'gender': gender,
        if (widget.country != null) 'country': widget.country,
        if (widget.city != null) 'city': widget.city,
        if (widget.filters?.statusVerified == true) 'is_verified': '1',
        if (widget.filters?.premiumOnly == true) 'membership': 'premium',
        if (widget.filters?.selectedServices.isNotEmpty == true)
          'services': widget.filters!.selectedServices.join(','),
        'limit': '60',
      };

      final uri = Uri.parse(
        ApiEndpoints.profiles,
      ).replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _profiles = data['data'] != null
              ? data['data']['profiles']
              : (data['profiles'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load profiles: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchProfiles,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_profiles.isEmpty) {
      return const Center(child: Text('No profiles found for your selection.'));
    }

    // Filter profiles client-side for price (Backend doesn't support it yet)
    var filteredProfiles = List.from(_profiles);

    if (widget.filters != null) {
      final f = widget.filters!;

      // Filter by Price (Check pricing JSON)
      filteredProfiles = filteredProfiles.where((p) {
        final pricingJson = p['pricing'];
        if (pricingJson == null) return true;
        try {
          final Map<String, dynamic> pricing = json.decode(pricingJson);
          for (var entry in pricing.values) {
            final price = double.tryParse(entry.toString());
            if (price != null &&
                price >= f.priceRange.start &&
                price <= f.priceRange.end) {
              return true;
            }
          }
          return false;
        } catch (_) {
          return true;
        }
      }).toList();
    }

    // Sort profiles: premium first
    final sortedProfiles = List.from(filteredProfiles)
      ..sort((a, b) {
        bool isP(dynamic p) {
          final m = p['membership']?.toString().toLowerCase();
          return m == 'premium' || m == 'vip';
        }

        final aPremium = isP(a);
        final bPremium = isP(b);
        if (aPremium && !bPremium) return -1;
        if (!aPremium && bPremium) return 1;
        return 0;
      });

    final profileCards = sortedProfiles.map((p) {
      bool isP(dynamic p) {
        final m = p['membership']?.toString().toLowerCase();
        return m == 'premium' || m == 'vip';
      }

      final isPremium = isP(p);

      String? imageUrl;
      try {
        if (p['images'] != null) {
          final dynamic decoded = json.decode(p['images']);
          String? firstImage;
          if (decoded is List && decoded.isNotEmpty) {
            firstImage = decoded[0].toString();
          } else if (decoded is String && decoded.isNotEmpty) {
            firstImage = decoded;
          }

          if (firstImage != null && firstImage.isNotEmpty) {
            if (firstImage.startsWith('http')) {
              imageUrl = firstImage;
            } else {
              imageUrl = '${ApiEndpoints.cdnUrl}images/users/$firstImage';
            }
          }
        }
      } catch (_) {}

      return _ProfileCardData(
        id: p['id'].toString(),
        name: p['name'] ?? 'Unknown',
        location: p['location'] ?? widget.city ?? widget.country ?? '',
        imageUrl: imageUrl ?? 'https://www.yooo.app/images/yoooo-male.webp',
        isVerified:
            (p['is_verified'] == '1' ||
            p['is_verified'] == 1 ||
            p['is_verified'] == true),
        accent: isPremium ? const Color(0xFF1D4ED8) : const Color(0xFFBE123C),
        border: isPremium ? const Color(0xFFCBD5F5) : const Color(0xFFF5D0DA),
      );
    }).toList();

    return RefreshIndicator(
      onRefresh: _fetchProfiles,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          const SizedBox(height: 8),
          _ProfileGrid(items: profileCards),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ProfileGrid extends StatelessWidget {
  const _ProfileGrid({required this.items});

  final List<_ProfileCardData> items;

  int _crossAxisCount(double width) {
    if (width >= 1000) return 4;
    if (width >= 760) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _crossAxisCount(constraints.maxWidth);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemBuilder: (context, index) {
            return _ProfileCard(data: items[index]);
          },
        );
      },
    );
  }
}

class _ProfileCardData {
  const _ProfileCardData({
    required this.id,
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.isVerified,
    required this.accent,
    required this.border,
  });

  final String id;
  final String name;
  final String location;
  final String imageUrl;
  final bool isVerified;
  final Color accent;
  final Color border;
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.data});

  final _ProfileCardData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProfilePage(profileId: data.id)),
        );
      },
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: data.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                data.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image),
                  );
                },
              ),
              if (data.isVerified)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.verified, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        data.accent.withValues(alpha: 0.85),
                        data.accent.withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        data.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        data.location,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
