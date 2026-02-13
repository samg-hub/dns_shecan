import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const DNSApp());
}

class DNSApp extends StatelessWidget {
  const DNSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shecan DNS',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1E2E), // Dark background
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00C8FF), // Cyan accent
          secondary: Color(0xFF8888AA),
        ),
        fontFamily: 'SF Pro Display', // System font usually available on Mac
        useMaterial3: true,
      ),
      home: const DNSHomePage(),
    );
  }
}

class DNSHomePage extends StatefulWidget {
  const DNSHomePage({super.key});

  @override
  State<DNSHomePage> createState() => _DNSHomePageState();
}

class _DNSHomePageState extends State<DNSHomePage>
    with SingleTickerProviderStateMixin {
  static const platform = MethodChannel('com.shecan.dns/control');

  bool _isConnected = false;
  bool _isLoading = false;
  String _statusMessage = 'Disconnected';
  String _activeInterface = 'Detecting...'; // Placeholder

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final bool result = await platform.invokeMethod('getStatus');
      final String interface = await platform.invokeMethod(
        'getActiveInterface',
      );
      setState(() {
        _isConnected = result;
        _activeInterface = interface;
        _statusMessage = result ? 'Protection Active' : 'Disconnected';
      });
    } on PlatformException catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.message}';
      });
    }
  }

  Future<void> _toggleDNS({bool force = false}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isConnected) {
        await platform.invokeMethod('disconnect');
        setState(() {
          _isConnected = false;
          _statusMessage = 'Disconnected';
        });
      } else {
        await platform.invokeMethod('connect', {'force': force});
        setState(() {
          _isConnected = true;
          _statusMessage = 'Protection Active';
        });
      }
    } on PlatformException catch (e) {
      if (e.code == 'VPN_ACTIVE') {
        if (mounted) {
          // Show VPN Warning Dialog
          final shouldProceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E), // Match app theme
              title: const Text(
                'VPN is Active',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'A VPN connection is active. DNS changes may not apply while the VPN is connected.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'Proceed',
                    style: TextStyle(color: Color(0xFF00FF94)),
                  ),
                ),
              ],
            ),
          );

          if (shouldProceed == true) {
            // Retry with force
            await _toggleDNS(force: true);
          } else {
            setState(() {
              _statusMessage = 'Cancelled';
            });
          }
        }
      } else {
        setState(() {
          _statusMessage = 'Failed: ${e.message}';
        });
        // Show generic error dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              title: const Text('Error', style: TextStyle(color: Colors.white)),
              content: Text(
                e.message ?? 'Unknown error occurred',
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F2027),
                  Color(0xFF203A43),
                  Color(0xFF2C5364),
                ],
              ),
            ),
          ),

          // Glassmorphism Content
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 350,
                  height: 500,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Mac DNS Controller',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _activeInterface, // Now used
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 16,
                          color: _isConnected
                              ? Colors.greenAccent
                              : Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 60),

                      // Toggle Button
                      GestureDetector(
                        onTap: _isLoading ? null : _toggleDNS,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isConnected
                                ? const Color(0xFF00FF94).withOpacity(0.2)
                                : Colors.redAccent.withOpacity(0.1),
                            border: Border.all(
                              color: _isConnected
                                  ? const Color(0xFF00FF94)
                                  : Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _isConnected
                                    ? const Color(0xFF00FF94).withOpacity(0.4)
                                    : Colors.transparent,
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Icon(
                                    _isConnected
                                        ? Icons.power_settings_new
                                        : Icons.power_off,
                                    size: 60,
                                    color: _isConnected
                                        ? const Color(0xFF00FF94)
                                        : Colors.white70,
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 60),

                      // DNS Info
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'TARGET DNS SERVERS',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _DnsRow(ip: '178.22.122.101'),
                            const SizedBox(height: 4),
                            _DnsRow(ip: '185.51.200.1'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DnsRow extends StatelessWidget {
  final String ip;
  const _DnsRow({required this.ip});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.dns, size: 14, color: Colors.cyanAccent),
        const SizedBox(width: 8),
        Text(
          ip,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: 'Monospace',
          ),
        ),
      ],
    );
  }
}
