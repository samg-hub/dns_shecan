import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/dns_profile.dart';
import '../../core/providers/dns_provider.dart';
import 'add_profile_dialog.dart';

class ProfileSelector extends StatelessWidget {
  final bool isConnected;

  const ProfileSelector({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DNSProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!provider.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DNS PROFILES',
              style: TextStyle(
                color: colorScheme.secondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded, size: 18),
              onPressed: isConnected
                  ? null
                  : () => _showAddDialog(context, provider),
              tooltip: 'Add Custom DNS',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.3),
            ),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.profiles.length,
            // separatorBuilder: (_, __) => Divider(
            //   height: 1,
            //   color: colorScheme.outlineVariant.withOpacity(0.1),
            // ),
            itemBuilder: (context, index) {
              final profile = provider.profiles[index];
              final isSelected = provider.selectedProfile?.id == profile.id;

              return ListTile(
                dense: true,
                selected: isSelected,
                leading: Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                  size: 18,
                ),
                title: Text(
                  profile.name,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  profile.servers.join(', '),
                  style: const TextStyle(fontSize: 10, fontFamily: 'Monospace'),
                ),
                onTap: isConnected
                    ? null
                    : () => provider.selectProfile(profile.id),
                trailing: profile.isPredefined
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            onPressed: isConnected
                                ? null
                                : () => _showEditDialog(
                                    context,
                                    provider,
                                    profile,
                                  ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_rounded, size: 16),
                            onPressed: isConnected
                                ? null
                                : () => provider.deleteProfile(profile.id),
                          ),
                        ],
                      ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context, DNSProvider provider) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const AddProfileDialog(),
    );
    if (result != null) {
      provider.addProfile(result['name'], List<String>.from(result['servers']));
    }
  }

  void _showEditDialog(
    BuildContext context,
    DNSProvider provider,
    DNSProfile profile,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AddProfileDialog(
        initialName: profile.name,
        initialPrimary: profile.servers.isNotEmpty ? profile.servers[0] : '',
        initialSecondary: profile.servers.length > 1 ? profile.servers[1] : '',
      ),
    );
    if (result != null) {
      provider.updateProfile(
        profile.id,
        result['name'],
        List<String>.from(result['servers']),
      );
    }
  }
}
