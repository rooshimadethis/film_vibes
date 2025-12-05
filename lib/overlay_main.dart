import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


// overlayMain has been moved to main.dart

class OverlaySettings extends ChangeNotifier {
  double _baseOpacity = 0.25;
  double _grainOpacity = 0.40;
  double _tintOpacity = 0.10;

  double get baseOpacity => _baseOpacity;
  double get grainOpacity => _grainOpacity;
  double get tintOpacity => _tintOpacity;

  void update({double? base, double? grain, double? tint}) {
    bool changed = false;
    if (base != null && _baseOpacity != base) {
      _baseOpacity = base;
      changed = true;
    }
    if (grain != null && _grainOpacity != grain) {
      _grainOpacity = grain;
      changed = true;
    }
    if (tint != null && _tintOpacity != tint) {
      _tintOpacity = tint;
      changed = true;
    }
    
    if (changed) {
      print("OverlaySettings: notifying listeners. Base: $_baseOpacity, Grain: $_grainOpacity, Tint: $_tintOpacity");
      notifyListeners();
    } else {
      print("OverlaySettings: update called but no changes detected.");
    }
  }
}

class OverlayApp extends StatefulWidget {
  const OverlayApp({super.key});

  @override
  State<OverlayApp> createState() => _OverlayAppState();
}

class _OverlayAppState extends State<OverlayApp> {
  final OverlaySettings _settings = OverlaySettings();
  static const MethodChannel platform = MethodChannel('film_vibes/overlay_control');
  final String _instanceId = DateTime.now().toIso8601String();

  @override
  void initState() {
    super.initState();
    print("OverlayApp: initState for instance $_instanceId");
    platform.setMethodCallHandler(_handleMethodCall);
    
    // Add a direct listener that forces setState
    _settings.addListener(() {
      print("OverlayApp: _settings listener fired for instance $_instanceId! Calling setState.");
      print("OverlayApp: Lifecycle state: ${WidgetsBinding.instance.lifecycleState}");
      if (mounted) {
        setState(() {});
        // Force a frame
        WidgetsBinding.instance.scheduleFrame();
      } else {
        print("OverlayApp: Widget NOT mounted!");
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialSettings();
    });
  }

  Future<void> _fetchInitialSettings() async {
    try {
      final Map<dynamic, dynamic>? initialSettings = await platform.invokeMapMethod('getInitialSettings');
      if (initialSettings != null && mounted) {
        print("OverlayMain: Initial settings received: $initialSettings");
        _settings.update(
          base: initialSettings.containsKey('baseOpacity') ? (initialSettings['baseOpacity'] as num).toDouble() : null,
          grain: initialSettings.containsKey('grainOpacity') ? (initialSettings['grainOpacity'] as num).toDouble() : null,
          tint: initialSettings.containsKey('tintOpacity') ? (initialSettings['tintOpacity'] as num).toDouble() : null,
        );
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
        _settings.update(
          base: args.containsKey('baseOpacity') ? (args['baseOpacity'] as num).toDouble() : null,
          grain: args.containsKey('grainOpacity') ? (args['grainOpacity'] as num).toDouble() : null,
          tint: args.containsKey('tintOpacity') ? (args['tintOpacity'] as num).toDouble() : null,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print("OverlayApp: build called for instance $_instanceId at ${DateTime.now()}");
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        type: MaterialType.transparency,
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          removeBottom: true,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // TEST: Bright pink box that should ALWAYS be visible
              Positioned(
                top: 100,
                left: 100,
                child: Container(
                  width: 200,
                  height: 200,
                  color: const Color(0xFFFF00FF), // Bright magenta
                  child: const Center(
                    child: Text(
                      'TEST BOX',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              
              // Original overlay content
              IgnorePointer(
                ignoring: true,
                child: AnimatedBuilder(
                  animation: _settings,
                  builder: (context, child) {
                    final baseOpacity = _settings.baseOpacity;
                    final grainOpacity = _settings.grainOpacity;
                    final tintOpacity = _settings.tintOpacity;
                    print("OverlayApp: AnimatedBuilder rebuild - Base: $baseOpacity, Grain: $grainOpacity, Tint: $tintOpacity");
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1. Paper Base Tint (Flat)
                        Container(
                          // DEBUG: Use RED if opacity is high to verify updates
                          color: baseOpacity > 0.5 
                              ? Colors.red.withOpacity(baseOpacity) 
                              : const Color(0xFFF5E6D3).withOpacity(baseOpacity),
                        ),

                        // 2. Paper Texture / Grain
                        Opacity(
                          opacity: grainOpacity,
                          child: Image.asset(
                            'assets/film_grain.png', 
                            repeat: ImageRepeat.repeat,
                            fit: BoxFit.none,
                            errorBuilder: (context, error, stackTrace) {
                              print("OverlayApp: Error loading image: $error");
                              return const SizedBox();
                            },
                          ),
                        ),
                        
                        // 3. Warm Tint Overlay
                        Container(
                          color: const Color(0xFFF5E6D3).withOpacity(tintOpacity),
                        )
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
