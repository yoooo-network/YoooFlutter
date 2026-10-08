import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../main_page/main_page.dart';
import '../settings/settings_page.dart';
import 'user_panel_footer_bar.dart';
import 'user_panel_header_bar.dart';
import 'upgrade_notice_page.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  int? _footerHoverIndex;
  bool _isLoadingProfile = true;
  bool _isPremium = false;
  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _fetchProfileMembership();
  }

  Future<void> _fetchProfileMembership() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token')?.trim();
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
        final payload = data is Map ? data['data'] : null;
        final profile = payload is Map ? payload['profile'] : null;
        final membership = profile is Map
            ? profile['membership']?.toString().toLowerCase()
            : null;
        _isPremium = membership == 'premium' || membership == 'vip';
      }

      final bookingsResponse = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/user/bookings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (bookingsResponse.statusCode == 200) {
        final bookingsData = json.decode(bookingsResponse.body);
        final bookingsPayload = bookingsData is Map ? bookingsData['data'] : null;
        final rawBookings = bookingsPayload is Map ? bookingsPayload['bookings'] : null;
        if (rawBookings is List) {
          _bookings = rawBookings
              .whereType<Map>()
              .map((booking) => Map<String, dynamic>.from(booking))
              .where((booking) =>
                  booking['status']?.toString().trim().toLowerCase() == 'approved')
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Bookings profile fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: UserPanelHeaderBar(
        title: 'Bookings',
        onBackToMainPage: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainPage()),
          (route) => false,
        ),
      ),
      bottomNavigationBar: UserPanelFooterBar(
        currentTab: UserPanelTab.bookings,
        hoverIndex: _footerHoverIndex,
        onHover: (index) => setState(() => _footerHoverIndex = index),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _isLoadingProfile
                ? const SizedBox(
                    height: 48,
                    width: 48,
                    child: CircularProgressIndicator(),
                  )
                : _bookings.isNotEmpty
                ? _ApprovedBookings(bookings: _bookings)
                : _isPremium
                ? const _PremiumEmptyState()
                : _FreeEmptyState(),
          ),
        ),
        ),
      ),
    );
  }
}

class _ApprovedBookings extends StatelessWidget {
  const _ApprovedBookings({required this.bookings});

  final List<Map<String, dynamic>> bookings;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final createdAt = DateTime.tryParse(booking['created_at']?.toString() ?? '');
        final received = createdAt == null
            ? null
            : '${createdAt.toLocal().month}/${createdAt.toLocal().day}/${createdAt.toLocal().year}';
        final phone = booking['phone']?.toString() ?? '';
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(
                    booking['name']?.toString() ?? 'Booking',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                  ),
                ),
                const Text('Approved', style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.w700)),
              ]),
              if (received != null) ...[
                const SizedBox(height: 4),
                Text('Received $received', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              ],
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Phone: $phone', style: const TextStyle(color: Color(0xFF334155))),
              ],
              if ((booking['message']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(booking['message'].toString(), style: const TextStyle(color: Color(0xFF334155), height: 1.4)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PremiumEmptyState extends StatelessWidget {
  const _PremiumEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'No bookings found',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'We get most of the bookings on Saturday and Sunday, so wait for a couple of days.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
      ],
    );
  }
}

class _FreeEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'No bookings found',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please upgrade your profile to start getting bookings.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UpgradeNoticePage()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
          child: const Text(
            'Upgrade Now',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
