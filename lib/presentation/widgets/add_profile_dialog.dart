import 'package:flutter/material.dart';

class AddProfileDialog extends StatefulWidget {
  final String? initialName;
  final String? initialPrimary;
  final String? initialSecondary;

  const AddProfileDialog({
    super.key,
    this.initialName,
    this.initialPrimary,
    this.initialSecondary,
  });

  @override
  State<AddProfileDialog> createState() => _AddProfileDialogState();
}

class _AddProfileDialogState extends State<AddProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _primaryController;
  late TextEditingController _secondaryController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _primaryController = TextEditingController(text: widget.initialPrimary);
    _secondaryController = TextEditingController(text: widget.initialSecondary);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _primaryController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  String? _validateIP(String? value) {
    if (value == null || value.isEmpty) return 'Enter an IP address';
    final regExp = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    if (!regExp.hasMatch(value)) return 'Invalid IPv4 address';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        widget.initialName == null ? 'Add DNS Profile' : 'Edit Profile',
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Profile Name'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _primaryController,
              decoration: const InputDecoration(
                labelText: 'Primary DNS (IPv4)',
              ),
              validator: _validateIP,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _secondaryController,
              decoration: const InputDecoration(
                labelText: 'Secondary DNS (IPv4)',
              ),
              validator: _validateIP,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text,
                'servers': [_primaryController.text, _secondaryController.text],
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
