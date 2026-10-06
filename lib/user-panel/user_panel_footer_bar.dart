import 'package:flutter/material.dart';

import 'bookings_page.dart';
import 'dashboard_page.dart';
import 'edit_profile_page.dart';
import 'user_settings_page.dart';

enum UserPanelTab { home, edit, bookings, settings }

class UserPanelFooterBar extends StatelessWidget {
  const UserPanelFooterBar({
    super.key,
    required this.currentTab,
    required this.hoverIndex,
    required this.onHover,
    this.userName = 'User',
  });

  final UserPanelTab currentTab;
  final int? hoverIndex;
  final ValueChanged<int?> onHover;
  final String userName;

  @override
  Widget build(BuildContext context) {
    const items = [
      _FooterItemData('Home', Icons.home_rounded, UserPanelTab.home),
      _FooterItemData('Edit', Icons.edit_rounded, UserPanelTab.edit),
      _FooterItemData(
        'Bookings',
        Icons.event_available_rounded,
        UserPanelTab.bookings,
      ),
      _FooterItemData(
        'Settings',
        Icons.settings_rounded,
        UserPanelTab.settings,
      ),
    ];
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isActive = item.tab == currentTab;
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
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                onTap: () => _openTab(context, item.tab),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: fgColor,
                          fontSize: 12,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
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

  void _openTab(BuildContext context, UserPanelTab tab) {
    if (tab == currentTab) return;

    final Widget page = switch (tab) {
      UserPanelTab.home => UserDashboardPage(userName: userName),
      UserPanelTab.edit => const EditProfilePage(),
      UserPanelTab.bookings => const BookingsPage(),
      UserPanelTab.settings => const UserSettingsPage(),
    };

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }
}

class _FooterItemData {
  const _FooterItemData(this.label, this.icon, this.tab);

  final String label;
  final IconData icon;
  final UserPanelTab tab;
}
