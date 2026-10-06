import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.hoverIndex,
    required this.onHover,
    required this.onTap,
  });

  final int currentIndex;
  final int? hoverIndex;
  final ValueChanged<int?> onHover;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItemData('Home', Icons.home_rounded),
      _NavItemData('Filter', Icons.filter_alt_rounded),
      _NavItemData('My Profile', Icons.person_rounded),
      _NavItemData('Settings', Icons.settings_rounded),
    ];
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isActive = currentIndex == index;
          final isHover = hoverIndex == index;
          final bgColor = (isActive || isHover)
              ? colorScheme.secondaryContainer
              : Colors.transparent;
          final fgColor = isActive
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurfaceVariant;

          return Expanded(
            child: MouseRegion(
              onEnter: (_) => onHover(index),
              onExit: (_) => onHover(null),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                splashFactory: NoSplash.splashFactory,
                overlayColor: const MaterialStatePropertyAll(Colors.transparent),
                onTap: () => onTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, color: fgColor),
                      const SizedBox(height: 6),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: fgColor,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData(this.label, this.icon);
  final String label;
  final IconData icon;
}
