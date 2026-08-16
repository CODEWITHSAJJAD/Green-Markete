import 'package:flutter/material.dart';

import 'brand_logo.dart';

/// The official MandiRoznamcha brand mark.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 72, this.radius});

  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return BrandLogo(
      size: size,
      isDarkBackground: true,
    );
  }
}
