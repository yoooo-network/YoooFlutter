import 'package:flutter/material.dart';

import '../widgets/info_grid.dart';
import '../widgets/stat_tile.dart';

class PhysicSection extends StatelessWidget {
  const PhysicSection({super.key, required this.profile});
  final Map<String, dynamic> profile;

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
    final age = _calculateAge(profile['dob']);
    return _SectionCard(
      child: InfoGrid(
        columns: 4,
        children: [
          StatTile(label: 'Age', value: age > 0 ? age.toString() : '-'),
          StatTile(label: 'Height', value: profile['height']?.toString() ?? '-'),
          StatTile(label: 'Weight', value: profile['weight']?.toString() ?? '-'),
          StatTile(label: 'Eye Color', value: profile['eye_color']?.toString() ?? '-'),
          StatTile(label: 'Hair Type', value: profile['hair_type']?.toString() ?? '-'),
          StatTile(label: 'Skin Color', value: profile['skin_color']?.toString() ?? '-'),
          StatTile(label: 'Body Structure', value: profile['body_structure']?.toString() ?? '-'),
          StatTile(label: 'Ethnicity', value: profile['ethnicity']?.toString() ?? '-'),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E6F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
