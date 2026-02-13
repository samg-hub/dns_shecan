import 'package:flutter/material.dart';

class ConnectButton extends StatelessWidget {
  final bool isConnected;
  final bool isLoading;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const ConnectButton({
    super.key,
    required this.isConnected,
    required this.isLoading,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
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
            colors: isConnected
                ? [
                    const Color(0xFF00C853), // Green 700
                    const Color(0xFF69F0AE), // Green Accent 200
                  ]
                : [
                    colorScheme.surfaceContainerHighest,
                    colorScheme.surfaceContainer,
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: isConnected
                  ? const Color(0xFF00C853).withOpacity(0.4)
                  : Colors.transparent,
              blurRadius: 40,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? CircularProgressIndicator(
                  color: isConnected ? Colors.white : colorScheme.onSurface,
                )
              : Icon(
                  Icons.power_settings_new_rounded,
                  size: 80,
                  color: isConnected ? Colors.white : colorScheme.outline,
                ),
        ),
      ),
    );
  }
}
