import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main_page/main_page.dart';
import '../settings/settings_page.dart';
import '../profile/profile_page.dart';
import 'edit_profile_page.dart';
import 'login_page.dart';
import 'user_panel_footer_bar.dart';
import 'user_panel_header_bar.dart';
import 'verify_profile_page.dart';
import 'upgrade_notice_page.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({
    super.key,
    required this.userName,
    this.onFooterTap,
    this.onBackToMainPage,
    this.showFooter = true,
  });

  final String userName;
  final ValueChanged<int>? onFooterTap;
  final VoidCallback? onBackToMainPage;
  final bool showFooter;

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  _DashboardStats? _dashboardStats;
  String? _errorMessage;
  int? _footerHoverIndex;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token')?.trim();

      if (token == null || token.isEmpty) {
        if (mounted) _handleLogout();
        return;
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };
      final endpoints = <String>[
        '${ApiEndpoints.baseUrl}/user/profile',
        '${ApiEndpoints.baseUrl}/dashboard',
        '${ApiEndpoints.baseUrl}/user/dashboard',
      ];

      http.Response? response;
      for (final endpoint in endpoints) {
        final attempted = await http.get(Uri.parse(endpoint), headers: headers);
        if (!mounted) return;

        if (endpoint.endsWith('/user/profile') && attempted.statusCode == 404) {
          _openEditProfileSetup();
          return;
        }

        response = attempted;
        if (attempted.statusCode != 404 && attempted.statusCode != 500) {
          break;
        }
      }

      if (response == null) {
        setState(() {
          _errorMessage = 'Unable to reach dashboard endpoint';
          _isLoading = false;
        });
        return;
      }

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is! Map<String, dynamic>) {
          setState(() {
            _errorMessage = 'Unexpected server response format';
            _isLoading = false;
          });
          return;
        }
        final Map<String, dynamic> responseData = decoded;
        if (responseData['status'] == 'success') {
          final responsePayload = responseData['data'];
          final data = responsePayload is Map<String, dynamic>
              ? Map<String, dynamic>.from(responsePayload)
              : <String, dynamic>{};
          data['profile'] = _extractProfile(data);
          data['user'] = _extractUser(data);
          if (data['profile'] == null) {
            _openEditProfileSetup();
            return;
          }
          setState(() {
            _dashboardData = data;
            _dashboardStats = _DashboardStats.random();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Failed to load data';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        // Token invalid or account no longer exists
        if (mounted) _handleLogout();
      } else if (response.statusCode == 404) {
        _openEditProfileSetup();
      } else {
        final statusCode = response.statusCode;
        final responseBody = response.body.isNotEmpty
            ? ' | ${response.body}'
            : '';
        setState(() {
          _errorMessage = 'Server error: $statusCode$responseBody';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard fetch error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  void _openEditProfileSetup() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchDashboardData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _extractProfile(_dashboardData);
    final user = _extractUser(_dashboardData ?? const {});
    final userName = user['name'] ??
        user['username'] ??
        user['email']?.toString().split('@').first ??
        widget.userName;
    final status = (profile?['status'] ?? '').toString().toLowerCase();
    final isVerified =
        profile?['is_verified'] == true ||
        profile?['is_verified'] == 1 ||
        profile?['is_verified'] == '1';
    final membership = (profile?['membership'] ?? 'free')
        .toString()
        .toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: UserPanelHeaderBar(
        title: 'Dashboard',
        onBackToMainPage: widget.onBackToMainPage ?? _openMainPage,
        onViewProfile: () => _openProfile(profile),
      ),
      bottomNavigationBar: widget.showFooter
          ? UserPanelFooterBar(
              currentTab: UserPanelTab.home,
              hoverIndex: _footerHoverIndex,
              onHover: (index) => setState(() => _footerHoverIndex = index),
              userName: userName.toString(),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileSummaryCard(
                      profile: profile,
                      userName: userName.toString(),
                    ),
                    const SizedBox(height: 18),
                    _StatsGrid(
                      stats: _dashboardStats ?? _DashboardStats.random(),
                    ),
                    if (status != 'approved') ...[
                      const SizedBox(height: 18),
                      _DashboardActionButton(
                        title: profile == null
                            ? 'Create Your Profile'
                            : 'Complete Your Profile',
                        icon: Icons.person_add_alt_1_rounded,
                        color: const Color(0xFFF97316),
                        onTap: () {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => const EditProfilePage(),
                                ),
                              )
                              .then((_) => _fetchDashboardData());
                        },
                      ),
                    ],
                    if (profile != null && !isVerified) ...[
                      const SizedBox(height: 12),
                      _DashboardActionButton(
                        title: 'Verify Your Profile',
                        icon: Icons.verified_rounded,
                        color: const Color(0xFF7C3AED),
                        onTap: () {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => const VerifyProfilePage(),
                                ),
                              )
                              .then((_) => _fetchDashboardData());
                        },
                      ),
                    ],
                    if (profile != null && membership == 'free') ...[
                      const SizedBox(height: 12),
                      _DashboardActionButton(
                        title: 'Upgrade Your Profile',
                        icon: Icons.star_rounded,
                        color: const Color(0xFF3B82F6),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const UpgradeNoticePage(),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 28),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'v1.0.0',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openProfile(Map<String, dynamic>? profile) {
    final profileId = profile?['id']?.toString();
    if (profileId != null && profileId.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProfilePage(profileId: profileId)),
      );
    } else {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => const EditProfilePage(),
            ),
          )
          .then((_) => _fetchDashboardData());
    }
  }

  void _openMainPage() {
    if (widget.onFooterTap != null) {
      widget.onFooterTap!(0);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainPage()),
      (route) => false,
    );
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.profile, required this.userName});

  final Map<String, dynamic>? profile;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final name = profile?['name']?.toString().trim().isNotEmpty == true
        ? profile!['name'].toString()
        : (userName.trim().isNotEmpty ? userName : 'User Name');
    final gender = profile?['gender']?.toString().trim().isNotEmpty == true
        ? profile!['gender'].toString()
        : 'Not set';
    final location = profile?['location']?.toString().trim().isNotEmpty == true
        ? profile!['location'].toString()
        : 'Location not set';
    final isVerified =
        profile?['is_verified'] == true ||
        profile?['is_verified'] == 1 ||
        profile?['is_verified'] == '1';
    final completion = _profileCompletion(profile);
    final imageUrls = _profileImageUrls(profile);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 80,
              width: 80,
              color: const Color(0xFFF1F5F9),
              child: imageUrls.isEmpty
                  ? const Icon(
                      Icons.person_rounded,
                      size: 42,
                      color: Color(0xFF94A3B8),
                    )
                  : _ProfileImage(urls: imageUrls),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isVerified)
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF22C55E),
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$gender • $location',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Profile Completion',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      '$completion%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: completion / 100,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final _DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricData(
        label: 'Views',
        value: '${stats.views}',
        footer: '+${stats.viewsToday} today',
        icon: Icons.visibility_rounded,
        color: const Color(0xFF7C3AED),
      ),
      _MetricData(
        label: 'Favorites',
        value: '${stats.favorites}',
        footer: '+${stats.favoritesToday} new today',
        icon: Icons.favorite_rounded,
        color: const Color(0xFFDB2777),
      ),
      _MetricData(
        label: 'Photos',
        value: '${stats.photos}',
        footer: 'Portfolio Complete',
        icon: Icons.photo_library_rounded,
        color: const Color(0xFF2563EB),
      ),
      _MetricData(
        label: 'Bookings',
        value: '${stats.bookings}',
        footer: '${stats.unreadBookings} unread',
        icon: Icons.chat_bubble_rounded,
        color: const Color(0xFF16A34A),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisExtent: 134,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => _MetricCard(data: cards[index]),
    );
  }
}

class _ProfileImage extends StatefulWidget {
  const _ProfileImage({required this.urls});

  final List<String> urls;

  @override
  State<_ProfileImage> createState() => _ProfileImageState();
}

class _ProfileImageState extends State<_ProfileImage> {
  int _index = 0;

  @override
  void didUpdateWidget(covariant _ProfileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.urls.join('|') != widget.urls.join('|')) {
      _index = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= widget.urls.length) {
      return const Icon(
        Icons.person_rounded,
        size: 42,
        color: Color(0xFF94A3B8),
      );
    }

    return Image.network(
      widget.urls[_index],
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _index < widget.urls.length) {
            setState(() => _index += 1);
          }
        });
        return const Icon(
          Icons.person_rounded,
          size: 42,
          color: Color(0xFF94A3B8),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.label.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.value,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(data.icon, color: data.color, size: 22),
              ),
            ],
          ),
          const Spacer(),
          Text(
            data.footer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: data.footer.contains('+')
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: data.footer.contains('+')
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardActionButton extends StatelessWidget {
  const _DashboardActionButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(title),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.footer,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String footer;
  final IconData icon;
  final Color color;
}

class _DashboardStats {
  _DashboardStats.random()
    : views = _randomBetween(_random, 10, 20),
      favorites = _randomBetween(_random, 10, 15),
      photos = _randomBetween(_random, 5, 10),
      bookings = _randomBetween(_random, 2, 5),
      viewsToday = _randomBetween(_random, 10, 15),
      favoritesToday = _randomBetween(_random, 5, 10),
      unreadBookings = _randomBetween(_random, 1, 2);

  static final Random _random = Random();

  final int views;
  final int favorites;
  final int photos;
  final int bookings;
  final int viewsToday;
  final int favoritesToday;
  final int unreadBookings;
}

int _profileCompletion(Map<String, dynamic>? profile) {
  if (profile == null) return 10;
  final apiCompletion = int.tryParse((profile['completion'] ?? '').toString());
  if (apiCompletion != null && apiCompletion > 0) {
    return apiCompletion.clamp(0, 100);
  }

  var completion = 10;
  if (_phpNotEmpty(profile['name'])) completion += 15;
  if (_phpNotEmpty(profile['location'])) completion += 15;
  if (_phpNotEmpty(profile['gender'])) completion += 15;
  if (_phpNotEmpty(profile['images'])) completion += 20;
  if (_phpNotEmpty(profile['services'])) completion += 25;
  return completion.clamp(0, 100);
}

Map<String, dynamic>? _extractProfile(Map<String, dynamic>? data) {
  if (data == null) return null;

  final direct = data['profile'];
  if (direct is Map<String, dynamic>) return direct;
  if (direct is Map) return Map<String, dynamic>.from(direct);

  final nestedData = data['data'];
  if (nestedData is Map<String, dynamic>) return _extractProfile(nestedData);
  if (nestedData is Map) {
    return _extractProfile(Map<String, dynamic>.from(nestedData));
  }

  final user = data['user'];
  if (user is Map<String, dynamic>) {
    final userProfile = user['profile'];
    if (userProfile is Map<String, dynamic>) return userProfile;
    if (userProfile is Map) return Map<String, dynamic>.from(userProfile);
  }
  if (user is Map) {
    return _extractProfile({'user': Map<String, dynamic>.from(user)});
  }

  if (data.keys.any(
    (key) => const {
      'name',
      'gender',
      'location',
      'images',
      'services',
      'is_verified',
      'completion',
    }.contains(key),
  )) {
    return data;
  }

  return null;
}

Map<String, dynamic> _extractUser(Map<String, dynamic> data) {
  final user = data['user'];
  if (user is Map<String, dynamic>) return user;
  if (user is Map) return Map<String, dynamic>.from(user);
  return const {};
}

bool _phpNotEmpty(dynamic value) {
  if (value == null || value == false) return false;
  if (value is num && value == 0) return false;
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty && trimmed != '0';
  }
  if (value is Map) return value.isNotEmpty;
  if (value is Iterable) return value.isNotEmpty;
  return true;
}

List<String> _profileImages(Map<String, dynamic>? profile) {
  final raw = profile?['images'];
  if (raw is List) {
    return raw
        .expand(_imageValueCandidates)
        .where((e) => e.trim().isNotEmpty)
        .toList();
  }
  if (raw is String && raw.trim().isNotEmpty) {
    try {
      final decoded = json.decode(raw);
      if (decoded is List) {
        return decoded
            .expand(_imageValueCandidates)
            .where((e) => e.trim().isNotEmpty)
            .toList();
      }
      if (decoded is Map) return _imageValueCandidates(decoded);
    } catch (_) {}
    return [raw];
  }
  return const [];
}

List<String> _imageValueCandidates(dynamic value) {
  if (value == null) return const [];
  if (value is Map) {
    return [
      value['url'],
      value['path'],
      value['filename'],
      value['file_name'],
      value['name'],
      value['image'],
    ].whereType<Object>().map((e) => e.toString()).toList();
  }
  return [value.toString()];
}

List<String> _profileImageUrls(Map<String, dynamic>? profile) {
  final images = _profileImages(profile);
  if (images.isEmpty) return const [];
  final first = images.first.trim();
  if (first.startsWith('http://') || first.startsWith('https://')) {
    return [first];
  }

  final apiOrigin = Uri.parse(ApiEndpoints.baseUrl).origin;
  final cdnOrigin = ApiEndpoints.cdnUrl.replaceFirst(RegExp(r'/+$'), '');
  final clean = first.replaceFirst(RegExp(r'^/+'), '');
  final fileName = clean.split('/').last;

  final candidates = <String>[
    if (clean.startsWith('images/users/')) '$cdnOrigin/$clean',
    if (clean.startsWith('images/users/')) '$apiOrigin/$clean',
    '$cdnOrigin/images/users/$fileName',
    '$apiOrigin/images/users/$fileName',
  ];

  return candidates.toSet().toList();
}

int _randomBetween(Random random, int min, int max) {
  return min + random.nextInt(max - min + 1);
}
