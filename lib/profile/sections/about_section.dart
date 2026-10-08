import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:yooo_profile_widgets/yooo_profile_widgets.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key, required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    List<String> sexualities = [];
    List<String> roles = [];
    List<String> languages = [];

    try {
      if (profile['sexuality'] != null) {
        final sexData = json.decode(profile['sexuality']);
        if (sexData['types'] != null) sexualities = List<String>.from(sexData['types']);
        if (sexData['roles'] != null) roles = List<String>.from(sexData['roles']);
      }
      if (profile['languages'] != null) {
        final langData = json.decode(profile['languages']);
        if (langData['selected'] != null) languages = List<String>.from(langData['selected']);
      }
    } catch (_) {}

    return Column(
      children: [
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _InfoList(
                rows: [
                  _InfoRow(
                    label: 'Gender',
                    valueWidget: TagWrap(
                      tags: [profile['gender'] ?? ''],
                      background: const Color(0xFFD1FAE5),
                      foreground: const Color(0xFF065F46),
                      showIcon: false,
                    ),
                  ),
                  if (sexualities.isNotEmpty)
                    _InfoRow(
                      label: 'Sexuality',
                      valueWidget: TagWrap(
                        tags: sexualities,
                        background: const Color(0xFFD1FAE5),
                        foreground: const Color(0xFF065F46),
                        showIcon: false,
                      ),
                    ),
                  if (roles.isNotEmpty)
                    _InfoRow(
                      label: 'Role',
                      valueWidget: TagWrap(
                        tags: roles,
                        background: const Color(0xFFD1FAE5),
                        foreground: const Color(0xFF065F46),
                        showIcon: false,
                      ),
                    ),
                  if (languages.isNotEmpty)
                    _InfoRow(
                      label: 'Languages',
                      valueWidget: TagWrap(
                        tags: languages,
                        background: const Color(0xFFD1FAE5),
                        foreground: const Color(0xFF065F46),
                        showIcon: false,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (profile['description'] != null && profile['description'].toString().isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  profile['description'],
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoList extends StatelessWidget {
  const _InfoList({required this.rows});
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          rows[i],
          if (i != rows.length - 1) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, this.value, this.valueWidget});
  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: valueWidget ??
              Text(
                value ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                  height: 1.35,
                ),
              ),
        ),
      ],
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
