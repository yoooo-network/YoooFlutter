import 'package:flutter/material.dart';

import 'onboarding_shared.dart';

class IntentScreen extends StatelessWidget {
  const IntentScreen({
    super.key,
    required this.step,
    required this.selected,
    required this.onSelect,
    required this.onNext,
  });

  final int step;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final intents = [
      _IntentOption('Male escort', Icons.male),
      _IntentOption('Female escort', Icons.female),
      _IntentOption('Trans escort', Icons.transgender),
      _IntentOption('Gay escort', Icons.diversity_3),
    ];

    return OnboardingScaffold(
      step: step,
      title: 'What do you want?',
      subtitle: 'Pick one option to personalize your experience.',
      child: ListView.separated(
        itemCount: intents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final option = intents[index];
          final isSelected = selected == option.label;
          return _SelectableCard(
            label: option.label,
            icon: option.icon,
            isSelected: isSelected,
            onTap: () => onSelect(option.label),
          );
        },
      ),
      bottom: FilledButton(
        onPressed: selected == null ? null : onNext,
        child: const Text('Continue'),
      ),
    );
  }
}

class _IntentOption {
  const _IntentOption(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? const Color(0xFF0F766E) : Colors.grey.shade200,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0F766E)
                      : const Color(0xFFE2F2EF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : const Color(0xFF0F766E),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Color(0xFF0F766E)),
            ],
          ),
        ),
      ),
    );
  }
}
