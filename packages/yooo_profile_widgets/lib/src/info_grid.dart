import 'package:flutter/material.dart';

class InfoGrid extends StatelessWidget {
  const InfoGrid({super.key, required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = columns;
        if (width < 520) {
          crossAxisCount = 2;
        } else if (width < 760) {
          crossAxisCount = columns > 2 ? 3 : columns;
        }
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.4,
          children: children,
        );
      },
    );
  }
}

