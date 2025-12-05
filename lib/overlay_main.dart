import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// overlayMain has been moved to main.dart

class OverlayApp extends StatefulWidget {
  const OverlayApp({super.key});

  @override
  State<OverlayApp> createState() => _OverlayAppState();
}

class _OverlayAppState extends State<OverlayApp> {
  // Default values
  double _baseOpacity = 0.25;
  double _grainOpacity = 0.40;
  double _tintOpacity = 0.10;

  static const MethodChannel platform = MethodChannel('film_vibes/overlay_control');

  @override
  void initState() {
    super.initState();
    platform.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'updateSettings') {
      final Map<dynamic, dynamic> args = call.arguments;
      if (mounted) {
        setState(() {
          if (args.containsKey('baseOpacity')) {
            _baseOpacity = (args['baseOpacity'] as num).toDouble();
          }
          if (args.containsKey('grainOpacity')) {
            _grainOpacity = (args['grainOpacity'] as num).toDouble();
          }
          if (args.containsKey('tintOpacity')) {
            _tintOpacity = (args['tintOpacity'] as num).toDouble();
          }
        });
      }
    }
  }

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
                      color: const Color(0xFFF5E6D3).withValues(alpha: _baseOpacity),
                    ),

                    // 2. Paper Texture / Grain
                    Opacity(
                      opacity: _grainOpacity,
                      child: Image.asset(
                        'assets/film_grain.png', 
                        repeat: ImageRepeat.repeat,
                        fit: BoxFit.none,
                      ),
                    ),
                    
                    // 3. Warm Tint Overlay
                    Container(
                      color: const Color(0xFFF5E6D3).withValues(alpha: _tintOpacity),
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
