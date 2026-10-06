import 'package:flutter/material.dart';

class FilterData {
  const FilterData({
    this.statusVerified = false,
    this.premiumOnly = false,
    this.selectedServices = const {},
    this.priceRange = const RangeValues(2000, 15000),
  });

  final bool statusVerified;
  final bool premiumOnly;
  final Set<String> selectedServices;
  final RangeValues priceRange;

  FilterData copyWith({
    bool? statusVerified,
    bool? premiumOnly,
    Set<String>? selectedServices,
    RangeValues? priceRange,
  }) {
    return FilterData(
      statusVerified: statusVerified ?? this.statusVerified,
      premiumOnly: premiumOnly ?? this.premiumOnly,
      selectedServices: selectedServices ?? this.selectedServices,
      priceRange: priceRange ?? this.priceRange,
    );
  }
}

class FilterPage extends StatefulWidget {
  const FilterPage({
    super.key,
    required this.data,
    required this.onApply,
  });

  final FilterData data;
  final ValueChanged<FilterData> onApply;

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  late FilterData _data;

  final List<String> _serviceOptions = [
    'Giving Oral Sex', 'Receiving Oral Sex', 'Foreplay', 'Roleplay', 'Cuddling',
    'All Sex Positions', 'DFK (Deep French Kissing)', 'A-Level (Anal Sex)',
    'Anal Rimming (Licking Anus)', '69 (69 Sex Position)', 'Striptease / Lapdance',
    'Fingering / Handjob', 'Massage', 'GFE / BFE (Girlfriend / Boyfriend Experience)',
    'Threesome', 'BDSM', 'Sex Toys', 'Extraball (Multiple Sessions)',
    'Domination', 'LT (Long Time / Overnight)'
  ];

  @override
  void initState() {
    super.initState();
    _data = widget.data;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Text(
          'Filters',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Profile Status',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FilterChip(
                label: 'Verified Only',
                isSelected: _data.statusVerified,
                onSelected: (value) => setState(
                  () => _data = _data.copyWith(statusVerified: value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Membership',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FilterChip(
                label: 'Premium Only',
                isSelected: _data.premiumOnly,
                onSelected: (value) => setState(
                  () => _data = _data.copyWith(premiumOnly: value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Price Range (3-4 hrs)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₹${_data.priceRange.start.round()} - ₹${_data.priceRange.end.round()}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              RangeSlider(
                values: _data.priceRange,
                min: 500,
                max: 30000,
                divisions: 59,
                labels: RangeLabels(
                  '₹${_data.priceRange.start.round()}',
                  '₹${_data.priceRange.end.round()}',
                ),
                onChanged: (values) => setState(() => _data = _data.copyWith(priceRange: values)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Services',
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: _serviceOptions.map((service) {
                final isSelected = _data.selectedServices.contains(service);
                return CheckboxListTile(
                  title: Text(service, style: const TextStyle(fontSize: 14)),
                  value: isSelected,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  onChanged: (selected) {
                    final newSet = Set<String>.from(_data.selectedServices);
                    if (selected == true) {
                      newSet.add(service);
                    } else {
                      newSet.remove(service);
                    }
                    setState(() => _data = _data.copyWith(selectedServices: newSet));
                  },
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => widget.onApply(_data),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Apply filters'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: colorScheme.secondaryContainer,
      checkmarkColor: colorScheme.onSecondaryContainer,
      labelStyle: TextStyle(
        fontSize: 13,
        color: isSelected
            ? colorScheme.onSecondaryContainer
            : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
      ),
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
