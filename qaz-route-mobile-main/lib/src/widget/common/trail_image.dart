import 'package:flutter/material.dart';
import 'package:qaz_route_mobile/src/core/app_assets.dart';
import 'package:qaz_route_mobile/src/core/app_colors.dart';

/// Shows a trail photo from the app bundle ("assets/...") or from the web
/// ("https://..."). If it cannot be loaded, shows a grey placeholder.
class TrailImage extends StatelessWidget {
  const TrailImage(
    this.source, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String source;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget placeholder(BuildContext context, Object error, StackTrace? stack) {
      return Container(
        width: width,
        height: height,
        color: AppColors.neutral100,
        alignment: Alignment.center,
        child: Image.asset(AppAssets.empty, width: 32, height: 32),
      );
    }

    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: placeholder,
      );
    }
    return Image.network(
      source,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: placeholder,
    );
  }
}
