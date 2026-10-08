import 'package:flutter/material.dart';

class StarsLogo extends StatelessWidget {
  const StarsLogo({
    super.key,
    this.size = 64,
    this.iconSize,
    this.borderRadius = 0,
  });

  static const backgroundColor = Color(0xFF7C3AED);

  final double size;
  final double? iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(
          child: Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: iconSize ?? size * 0.5,
          ),
        ),
      ),
    );
  }
}