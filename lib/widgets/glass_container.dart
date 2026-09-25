import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final double opacity;
  final Color? color;
  final Border? customBorder;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 8.0,
    this.opacity = 0.15,
    this.color,
    this.customBorder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = color ?? (isDark ? Colors.white : Colors.white);
    final borderRad = borderRadius ?? BorderRadius.circular(24);

    // In dark mode we use white with low opacity, in light mode white with higher opacity
    final fillOpacity = isDark ? opacity : (opacity * 3).clamp(0.0, 0.8);
    final borderColor =
        isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5);

    Widget container = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: defaultColor.withOpacity(fillOpacity),
        borderRadius: borderRad,
        border: customBorder ??
            Border.all(
              color: borderColor,
              width: 1.0,
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: -5,
          )
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      container = InkWell(
        onTap: onTap,
        borderRadius: borderRad,
        child: container,
      );
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: borderRad,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child:
              container, // we remove the margin from inside container to avoid clipping issues, wait padding is added outside
        ),
      ),
    );
  }
}
