import 'package:flutter/material.dart';

class DnsServerRow extends StatelessWidget {
  final String ip;
  final ColorScheme colorScheme;

  const DnsServerRow({super.key, required this.ip, required this.colorScheme});

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
