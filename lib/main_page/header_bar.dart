import 'package:flutter/material.dart';

class HeaderBar extends StatelessWidget implements PreferredSizeWidget {
  const HeaderBar({
    super.key,
    required this.intent,
    required this.country,
  });

  final String? intent;
  final String? country;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      shape: Border(
        bottom: BorderSide(color: colorScheme.outlineVariant),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yooo.App',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            _subtitleText(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none),
        ),
      ],
    );
  }

  String _subtitleText() {
    final hasIntent = intent != null && intent!.trim().isNotEmpty;
    final hasCountry = country != null && country!.trim().isNotEmpty;
    if (hasIntent && hasCountry) {
      return '${intent!} - ${country!}';
    }
    if (hasIntent) {
      return intent!;
    }
    if (hasCountry) {
      return country!;
    }
    return 'Welcome';
  }
}
