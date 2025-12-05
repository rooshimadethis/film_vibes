import 'package:flutter/material.dart';

// overlayMain has been moved to main.dart

class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        type: MaterialType.transparency,
        child: Builder(
          builder: (context) {
            return MediaQuery.removePadding(
              context: context,
              removeTop: true,
              removeBottom: true,
              child: IgnorePointer(
                ignoring: true,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Paper Base Tint (Flat)
                    Container(
                      color: const Color(0xFFF5E6D3).withValues(alpha: 0.25),
                    ),

                    // 2. Paper Texture / Grain
                    Opacity(
                      opacity: 0.40, // Increased opacity significantly
                      child: Image.asset(
                        'assets/film_grain.png', 
                        repeat: ImageRepeat.repeat,
                        fit: BoxFit.none,
                      ),
                    ),
                    
                    // 3. Warm Tint Overlay
                    Container(
                      color: const Color(0xFFF5E6D3).withValues(alpha: 0.10),
                    )
                  ],
                ),
              ),
            );
          }
        ),
      ),
    );
  }
}
