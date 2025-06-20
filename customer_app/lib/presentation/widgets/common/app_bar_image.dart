import 'package:flutter/material.dart';

class AppBarImage extends StatelessWidget {
  final String imagePath;
  final VoidCallback? onTap;

  const AppBarImage({
    super.key,
    required this.imagePath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          imagePath,
          height: 24,
          width: 24,
        ),
      ),
    );
  }
} 