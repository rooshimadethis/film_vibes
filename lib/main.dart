import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'overlay_main.dart'; // Import the overlay entry point

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const OverlayApp());
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static const platform = MethodChannel('paper_vibes/overlay');
  bool _isOverlayGranted = false;
  bool _isBatteryOptimizationDisabled = false;
  bool _isOverlayRunning = false;
  
  // Overlay Settings
  double _baseOpacity = 0.08;
  double _grainOpacity = 0.19;
  double _tintOpacity = 0.0;

  Future<void> _updateOverlaySettings() async {
    if (!_isOverlayRunning) return;
    try {
      await platform.invokeMethod('updateOverlaySettings', {
        'baseOpacity': _baseOpacity,
        'grainOpacity': _grainOpacity,
        'tintOpacity': _tintOpacity,
      });
    } catch (e) {
      debugPrint('Error updating settings: $e');
    }
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${(value * 100).toInt()}%'),
          Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final bool granted = await platform.invokeMethod('checkPermission');
      setState(() {
        _isOverlayGranted = granted;
      });
      _checkBatteryOptimization();
    } catch (e) {
      debugPrint('Error checking permission: $e');
    }
  }

  Future<void> _requestPermission() async {
    try {
      final bool granted = await platform.invokeMethod('requestPermission');
      setState(() {
        _isOverlayGranted = granted;
      });
    } catch (e) {
      debugPrint('Error requesting permission: $e');
    }
  }

  Future<void> _checkBatteryOptimization() async {
    try {
      final bool disabled = await platform.invokeMethod('checkBatteryOptimization');
      setState(() {
        _isBatteryOptimizationDisabled = disabled;
      });
    } catch (e) {
      debugPrint('Error checking battery optimization: $e');
    }
  }

  Future<void> _requestBatteryOptimization() async {
    try {
      await platform.invokeMethod('requestBatteryOptimization');
      // The user will be taken to settings, so we can't know immediately if they granted it.
      // We rely on lifecycle resume to check again.
    } catch (e) {
      debugPrint('Error requesting battery optimization: $e');
    }
  }

  Future<void> _startOverlay() async {
    try {
      await platform.invokeMethod('startOverlay', {
        'baseOpacity': _baseOpacity,
        'grainOpacity': _grainOpacity,
        'tintOpacity': _tintOpacity,
      });
      setState(() {
        _isOverlayRunning = true;
      });
    } catch (e) {
      debugPrint('Error starting overlay: $e');
    }
  }

  Future<void> _stopOverlay() async {
    try {
      await platform.invokeMethod('stopOverlay');
      setState(() {
        _isOverlayRunning = false;
      });
    } catch (e) {
      debugPrint('Error stopping overlay: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paper Vibes',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Paper Vibes Setup'),
          actions: [
            IconButton(
              onPressed: _checkPermissions,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Test Image
              Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    image: AssetImage('assets/test_pattern.png'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
              ),

              // Color Swatches
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSwatch(Colors.red),
                    _buildSwatch(Colors.green),
                    _buildSwatch(Colors.blue),
                    _buildSwatch(Colors.cyan),
                    _buildSwatch(const Color(0xFFFF00FF)), // Magenta

                    _buildSwatch(Colors.yellow),
                    _buildSwatch(Colors.white),
                    _buildSwatch(Colors.black),
                  ],
                ),
              ),
              const Divider(height: 30),
            
              Text('Overlay Permission: ${_isOverlayGranted ? "Granted" : "Denied"}'),
              const SizedBox(height: 20),
              if (!_isOverlayGranted)
                ElevatedButton(
                  onPressed: _requestPermission,
                  child: const Text('Request Permission'),
                ),
              if (_isOverlayGranted && !_isBatteryOptimizationDisabled)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ElevatedButton(
                    onPressed: _requestBatteryOptimization,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('Disable Battery Optimization (Recommended)', style: TextStyle(color: Colors.white)),
                  ),
                ),
              if (_isOverlayGranted) ...[
                ElevatedButton(
                  onPressed: _isOverlayRunning ? null : _startOverlay,
                  child: const Text('Start Paper Overlay'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isOverlayRunning ? _stopOverlay : null,
                  child: const Text('Stop Overlay'),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const Text('Adjust Overlay Style', style: TextStyle(fontWeight: FontWeight.bold)),
                _buildSlider('Base Opacity', _baseOpacity, (val) {
                  setState(() => _baseOpacity = val);
                  _updateOverlaySettings();
                }),
                _buildSlider('Grain Opacity', _grainOpacity, (val) {
                  setState(() => _grainOpacity = val);
                  _updateOverlaySettings();
                }),
                _buildSlider('Tint Opacity', _tintOpacity, (val) {
                  setState(() => _tintOpacity = val);
                  _updateOverlaySettings();
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwatch(Color color) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
