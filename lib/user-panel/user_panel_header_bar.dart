import 'package:flutter/material.dart';

class UserPanelHeaderBar extends StatelessWidget
    implements PreferredSizeWidget {
  const UserPanelHeaderBar({
    super.key,
    required this.title,
    this.onBackToMainPage,
    this.onViewProfile,
  });

  final String title;
  final VoidCallback? onBackToMainPage;
  final VoidCallback? onViewProfile;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      shape: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      leading: IconButton(
        tooltip: 'Main page',
        onPressed: onBackToMainPage ?? () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back),
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yooo.App',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      actions: [
        if (onViewProfile != null)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Tooltip(
              message: 'View profile',
              child: InkWell(
                onTap: onViewProfile,
                borderRadius: BorderRadius.circular(16),
                splashFactory: NoSplash.splashFactory,
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
