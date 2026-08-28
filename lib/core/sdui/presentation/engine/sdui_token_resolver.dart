import 'package:flutter/material.dart';

class SduiTokenResolver {
  static const primary = Color(0xFF1565C0);
  static const background = Color(0xFFF4F7FB);
  static const surface = Colors.white;

  static Color color(String? token) {
    switch (token) {
      case 'brand.primary':
        return primary;
      case 'neutral.background':
        return background;
      default:
        if (token != null && token.startsWith('#')) {
          return _hex(token);
        }
        return background;
    }
  }

  static double spacing(dynamic token) {
    if (token is num) return token.toDouble();
    switch ('$token') {
      case 'spacing.xs':
        return 8;
      case 'spacing.md':
        return 16;
      case 'spacing.lg':
        return 20;
      case 'spacing.xl':
        return 24;
      default:
        return 0;
    }
  }

  static EdgeInsets padding(dynamic token) {
    final v = spacing(token);
    return EdgeInsets.all(v);
  }

  static Color _hex(String hex) {
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  }

  static TextStyle textStyle(String? style, BuildContext context) {
    final theme = Theme.of(context).textTheme;
    switch (style) {
      case 'headline':
        return theme.headlineSmall?.copyWith(fontWeight: FontWeight.w700) ??
            const TextStyle(fontSize: 24, fontWeight: FontWeight.w700);
      case 'caption':
        return theme.bodySmall ?? const TextStyle(fontSize: 12);
      case 'link':
        return (theme.bodyMedium ?? const TextStyle()).copyWith(color: primary);
      default:
        return theme.bodyMedium ?? const TextStyle(fontSize: 16);
    }
  }
}
