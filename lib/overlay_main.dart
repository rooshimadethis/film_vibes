import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const OverlayApp());
}

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
                    // 1. Paper Base Tint & Vignette
                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.2,
                          colors: [
                            const Color(0xFFFDFBF7).withValues(alpha: 0.10), // Center: Clean Paper
                            const Color(0xFFE6D6BC).withValues(alpha: 0.30), // Edges: Aged Paper
                          ],
                          stops: const [0.2, 1.0],
                        ),
                      ),
                    ),

                    // 2. Paper Texture / Grain
                    Opacity(
                      opacity: 0.15,
                      child: Image.asset(
                        'assets/film_grain.png', 
                        repeat: ImageRepeat.repeat,
                        fit: BoxFit.none,
                      ),
                    ),
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
