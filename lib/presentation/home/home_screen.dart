import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/dns_service.dart';
import '../../core/providers/dns_provider.dart';
import '../widgets/connect_button.dart';
import '../widgets/profile_selector.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dnsService = DNSService();
  bool _isConnected = false;
  bool _isLoading = false;
  String _statusMessage = 'Disconnected';
  String _activeInterface = 'Detecting...';

  @override
  void initState() {
    super.initState();
    // Listen for status changes from native side (menu bar)
    DNSService.platform.setMethodCallHandler((call) async {
      if (call.method == 'onStatusChanged') {
        _checkStatus();
      }
    });

    Future.delayed(const Duration(milliseconds: 250), () {
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    final provider = context.read<DNSProvider>();
    if (!provider.isInitialized) return;

    final selectedServers = provider.selectedProfile?.servers ?? [];
    if (selectedServers.isEmpty) return;

    final isConnected = await _dnsService.getStatus(selectedServers);
    final interface = await _dnsService.getActiveInterface();

    if (mounted) {
      setState(() {
        _isConnected = isConnected;
        _activeInterface = interface;
        _statusMessage = isConnected ? 'Protection Active' : 'Disconnected';
      });
    }
  }

  Future<void> _toggleDNS({bool force = false}) async {
    final provider = context.read<DNSProvider>();
    final servers = provider.selectedProfile?.servers ?? [];

    if (servers.isEmpty) {
      _showError('Selected profile has no DNS servers');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isConnected) {
        await _dnsService.disconnect();
        setState(() {
          _isConnected = false;
          _statusMessage = 'Disconnected';
        });
      } else {
        await _dnsService.connect(servers, force: force);
        setState(() {
          _isConnected = true;
          _statusMessage = 'Protection Active';
        });
      }
    } on PlatformException catch (e) {
      if (e.code == 'VPN_ACTIVE') {
        _showVpnWarning();
      } else {
        _showError(e.message ?? 'Unknown error');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showVpnWarning() async {
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
      _toggleDNS(force: true);
    } else {
      setState(() => _statusMessage = 'Cancelled');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch for provider changes
    context.watch<DNSProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
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
                    : [
                        colorScheme.surfaceContainerHighest,
                        colorScheme.surface,
                        colorScheme.surfaceContainerHighest,
                      ],
              ),
            ),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 420,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withOpacity(
                        isDark ? 0.3 : 0.6,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'DNS Changer',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            _checkStatus();
                          },
                          child: Text(
                            _activeInterface,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _StatusIndicator(
                          isConnected: _isConnected,
                          message: _statusMessage,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 40),
                        ConnectButton(
                          isConnected: _isConnected,
                          isLoading: _isLoading,
                          onTap: _toggleDNS,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 40),
                        ProfileSelector(isConnected: _isConnected),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Made with ❤️ for the Open Source Community | github.com/samg-hub",
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withAlpha(70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final bool isConnected;
  final String message;
  final ColorScheme colorScheme;

  const _StatusIndicator({
    required this.isConnected,
    required this.message,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isConnected
            ? const Color(0xFF00C853).withOpacity(0.2)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected ? const Color(0xFF00C853) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isConnected
              ? const Color(0xFF00C853)
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
