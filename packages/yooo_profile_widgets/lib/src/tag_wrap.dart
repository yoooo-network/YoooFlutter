import 'package:flutter/material.dart';

class TagWrap extends StatelessWidget {
  const TagWrap({
    super.key,
    required this.tags,
    required this.background,
    required this.foreground,
    this.showIcon = true,
  });

  final List<String> tags;
  final Color background;
  final Color foreground;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: tags
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showIcon) ...[
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: foreground,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    tag,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

