import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

void main() {
  runApp(const DNSApp());
}

class DNSApp extends StatelessWidget {
  const DNSApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize Theme
    const materialTheme = MaterialTheme(TextTheme());

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shecan DNS',
      theme: materialTheme.light(),
      darkTheme: materialTheme.dark(),
      themeMode: ThemeMode.light, // Follow system appearance
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
  String _activeInterface = 'Detecting...';

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
          final shouldProceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('VPN is Active'),
              content: const Text(
                'A VPN connection is active. DNS changes may not apply while the VPN is connected.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Proceed'),
                ),
              ],
            ),
          );

          if (shouldProceed == true) {
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
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Error'),
              content: Text(e.message ?? 'Unknown error occurred'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by Container
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    colorScheme.surfaceContainerLowest,
                    colorScheme.surfaceContainer,
                    colorScheme.surfaceContainerHigh,
                  ]
                : [Colors.white, Colors.white, Colors.white],
          ),
        ),
        child: Stack(
          children: [
            // Standard MacOS Traffic Lights Area Placeholder
            // We left them enabled in Swift, so we just avoid drawing over them at top-left
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  24,
                ), // Modern rounded corners
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 380,
                    height: 550,
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withOpacity(
                        isDark ? 0.3 : 0.6,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Spacer for traffic lights if the card was full screen,
                        // but here it is a centered card, so no need for top padding relative to screen.
                        Text(
                          'Shecan DNS',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _activeInterface,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Status Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _isConnected
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusMessage,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _isConnected
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),

                        const SizedBox(height: 50),

                        // Toggle Button
                        GestureDetector(
                          onTap: _isLoading ? null : () => _toggleDNS(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutBack,
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: _isConnected
                                    ? [
                                        const Color(0xFF00C853), // Green 700
                                        const Color.fromARGB(
                                          255,
                                          7,
                                          168,
                                          90,
                                        ), // Green Accent 200
                                      ]
                                    : [
                                        colorScheme.surfaceContainerHighest,
                                        colorScheme.surfaceContainer,
                                      ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _isConnected
                                      ? const Color(0xFF00C853).withOpacity(0.4)
                                      : Colors.transparent,
                                  blurRadius: 40,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isLoading
                                  ? CircularProgressIndicator(
                                      color: _isConnected
                                          ? Colors.white
                                          : colorScheme.onSurface,
                                    )
                                  : Icon(
                                      Icons.power_settings_new_rounded,
                                      size: 80,
                                      color: _isConnected
                                          ? Colors.white
                                          : colorScheme.outline,
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 50),

                        // DNS Info Card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow.withOpacity(
                              0.5,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withOpacity(
                                0.3,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'DNS SERVERS',
                                style: TextStyle(
                                  color: colorScheme.secondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _DnsRow(
                                ip: '178.22.122.101',
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(height: 8),
                              _DnsRow(
                                ip: '185.51.200.1',
                                colorScheme: colorScheme,
                              ),
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
      ),
    );
  }
}

class _DnsRow extends StatelessWidget {
  final String ip;
  final ColorScheme colorScheme;

  const _DnsRow({required this.ip, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.dns_rounded, size: 16, color: colorScheme.primary),
        const SizedBox(width: 10),
        Text(
          ip,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontFamily: 'Monospace',
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
