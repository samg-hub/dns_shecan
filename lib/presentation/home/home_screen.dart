import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/dns_service.dart';
import '../widgets/connect_button.dart';
import '../widgets/dns_server_row.dart';

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
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final isConnected = await _dnsService.getStatus();
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
    setState(() => _isLoading = true);

    try {
      if (_isConnected) {
        await _dnsService.disconnect();
        setState(() {
          _isConnected = false;
          _statusMessage = 'Disconnected';
        });
      } else {
        await _dnsService.connect(force: force);
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

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                width: 380,
                height: 550,
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(isDark ? 0.3 : 0.6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                    _StatusIndicator(
                      isConnected: _isConnected,
                      message: _statusMessage,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 50),
                    ConnectButton(
                      isConnected: _isConnected,
                      isLoading: _isLoading,
                      onTap: _toggleDNS,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 50),
                    _DnsInfoCard(colorScheme: colorScheme),
                  ],
                ),
              ),
            ),
          ),
        ),
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
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isConnected
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DnsInfoCard extends StatelessWidget {
  final ColorScheme colorScheme;

  const _DnsInfoCard({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
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
          DnsServerRow(ip: '178.22.122.101', colorScheme: colorScheme),
          const SizedBox(height: 8),
          DnsServerRow(ip: '185.51.200.1', colorScheme: colorScheme),
        ],
      ),
    );
  }
}
