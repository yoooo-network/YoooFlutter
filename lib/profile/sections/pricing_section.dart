import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:yooo_profile_widgets/yooo_profile_widgets.dart';

class PricingSection extends StatelessWidget {
  const PricingSection({super.key, required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    List<PriceRow> rows = [];
    try {
      if (profile['pricing'] != null) {
        final data = json.decode(profile['pricing']);
        
        void addRow(String label, String? val) {
          if (val != null && val.isNotEmpty && val.toLowerCase() != 'inr') {
            // Extract numeric part and unit
            final numeric = val.replaceAll(RegExp(r'[^0-9]'), '');
            final unit = val.replaceAll(RegExp(r'[0-9]'), '');
            if (numeric.isNotEmpty) {
              rows.add(PriceRow(duration: label, rate: numeric, unit: unit.isEmpty ? 'INR' : unit));
            }
          }
        }

        addRow('1 Hour', data['1hr']);
        addRow('3 Hours', data['3hr']);
        addRow('Full Night', data['night']);
        addRow('Full Week', data['week']);
        addRow('Full Month', data['month']);
      }
    } catch (_) {}

    if (rows.isEmpty) {
      return const _SectionCard(
        child: Center(child: Text('Pricing not specified')),
      );
    }

    return _SectionCard(
      child: PricingTable(rows: rows),
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
