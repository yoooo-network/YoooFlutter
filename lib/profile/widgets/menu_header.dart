import 'package:flutter/material.dart';

class MenuHeaderDelegate extends SliverPersistentHeaderDelegate {
  MenuHeaderDelegate({required this.child});

  final Widget child;
  static const double height = 64;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant MenuHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class MenuChip extends StatelessWidget {
  const MenuChip({
    super.key,
    required this.label,
    this.icon,
    this.isActive = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF1D4ED8);
    final showLabel = label.trim().isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withOpacity(0.12)
                : const Color(0xFFF0F1F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? activeColor : const Color(0xFFE0E3F0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isActive ? activeColor : Colors.black87,
                ),
                if (showLabel) const SizedBox(width: 6),
              ],
              if (showLabel)
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive ? activeColor : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileMenuBar extends StatelessWidget {
  const ProfileMenuBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: MenuHeaderDelegate.height,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: MenuChip(
                label: 'About',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: MenuChip(
                label: 'Physique',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: MenuChip(
                label: '',
                icon: Icons.person,
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: MenuChip(
                label: 'Services',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: MenuChip(
                label: 'Price',
                isActive: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
