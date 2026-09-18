import 'package:flutter/material.dart';

class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // In light mode, we use very soft pastels. In dark mode, deep vibrant colors.
    final bgColor = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFFAFAFA);
    
    final blob1Color = isDark 
        ? Theme.of(context).colorScheme.primary.withOpacity(0.15) 
        : Theme.of(context).colorScheme.primary.withOpacity(0.08);
        
    final blob2Color = isDark 
        ? Theme.of(context).colorScheme.secondary.withOpacity(0.15) 
        : Theme.of(context).colorScheme.secondary.withOpacity(0.08);

    return Stack(
      children: [
        // Base Background Color
        Container(
          color: bgColor,
          width: double.infinity,
          height: double.infinity,
        ),
        
        // Blob 1 (Top Right)
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: blob2Color,
              boxShadow: [
                BoxShadow(
                  color: blob2Color,
                  blurRadius: 100,
                  spreadRadius: 50,
                ),
              ],
            ),
          ),
        ),
        
        // Blob 2 (Bottom Left)
        Positioned(
          bottom: -50,
          left: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: blob1Color,
              boxShadow: [
                BoxShadow(
                  color: blob1Color,
                  blurRadius: 120,
                  spreadRadius: 60,
                ),
              ],
            ),
          ),
        ),

        // The content on top
        child,
      ],
    );
  }
}
