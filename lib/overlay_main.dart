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
    _fetchInitialSettings();
  }

  Future<void> _fetchInitialSettings() async {
    try {
      final Map<dynamic, dynamic>? initialSettings = await platform.invokeMapMethod('getInitialSettings');
      if (initialSettings != null && mounted) {
        print("OverlayMain: Initial settings received: $initialSettings");
        setState(() {
          if (initialSettings.containsKey('baseOpacity')) {
            _baseOpacity = (initialSettings['baseOpacity'] as num).toDouble();
          }
          if (initialSettings.containsKey('grainOpacity')) {
            _grainOpacity = (initialSettings['grainOpacity'] as num).toDouble();
          }
          if (initialSettings.containsKey('tintOpacity')) {
            _tintOpacity = (initialSettings['tintOpacity'] as num).toDouble();
          }
        });
      }
    } catch (e) {
      print("OverlayMain: Error fetching initial settings: $e");
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    print("OverlayMain: Received method call ${call.method}");
    if (call.method == 'updateSettings') {
      final Map<dynamic, dynamic> args = call.arguments;
      print("OverlayMain: Args: $args");
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
    print("OverlayApp: build called. Base: $_baseOpacity, Grain: $_grainOpacity, Tint: $_tintOpacity");
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
                      color: const Color(0xFFF5E6D3).withOpacity(_baseOpacity),
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
                      color: const Color(0xFFF5E6D3).withOpacity(_tintOpacity),
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
