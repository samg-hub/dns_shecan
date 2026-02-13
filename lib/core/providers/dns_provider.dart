import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dns_profile.dart';

class DNSProvider extends ChangeNotifier {
  static const String _profilesKey = 'dns_profiles';
  static const String _selectedProfileIdKey = 'selected_profile_id';

  List<DNSProfile> _profiles = [];
  String? _selectedProfileId;
  bool _initialized = false;

  DNSProvider() {
    _init();
  }

  bool get isInitialized => _initialized;
  List<DNSProfile> get profiles => [..._profiles];

  DNSProfile? get selectedProfile {
    if (_selectedProfileId == null) return _profiles.firstOrNull;
    return _profiles.firstWhere(
      (p) => p.id == _selectedProfileId,
      orElse: () => _profiles.first,
    );
  }

  final List<DNSProfile> _predefinedProfiles = [
    DNSProfile(
      id: 'shecan',
      name: 'Shecan',
      servers: ['178.22.122.101', '185.51.200.1'],
      isPredefined: true,
    ),
    DNSProfile(
      id: 'google',
      name: 'Google DNS',
      servers: ['8.8.8.8', '8.8.4.4'],
      isPredefined: true,
    ),
    DNSProfile(
      id: 'cloudflare',
      name: 'Cloudflare',
      servers: ['1.1.1.1', '1.0.0.1'],
      isPredefined: true,
    ),
  ];

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    // Load custom profiles
    final profilesJson = prefs.getStringList(_profilesKey) ?? [];
    final customProfiles = profilesJson
        .map((s) => DNSProfile.fromJson(s))
        .toList();

    _profiles = [..._predefinedProfiles, ...customProfiles];
    _selectedProfileId = prefs.getString(_selectedProfileIdKey);

    _initialized = true;
    notifyListeners();
  }

  Future<void> selectProfile(String id) async {
    _selectedProfileId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedProfileIdKey, id);
    notifyListeners();
  }

  Future<void> addProfile(String name, List<String> servers) async {
    final newProfile = DNSProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      servers: servers,
    );

    _profiles.add(newProfile);
    await _saveCustomProfiles();
    notifyListeners();
  }

  Future<void> updateProfile(
    String id,
    String name,
    List<String> servers,
  ) async {
    final index = _profiles.indexWhere((p) => p.id == id);
    if (index != -1 && !_profiles[index].isPredefined) {
      _profiles[index] = DNSProfile(id: id, name: name, servers: servers);
      await _saveCustomProfiles();
      notifyListeners();
    }
  }

  Future<void> deleteProfile(String id) async {
    final profile = _profiles.firstWhere((p) => p.id == id);
    if (!profile.isPredefined) {
      _profiles.removeWhere((p) => p.id == id);
      if (_selectedProfileId == id) {
        _selectedProfileId = _profiles.first.id;
      }
      await _saveCustomProfiles();
      notifyListeners();
    }
  }

  Future<void> _saveCustomProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final customProfiles = _profiles.where((p) => !p.isPredefined).toList();
    final profilesJson = customProfiles.map((p) => p.toJson()).toList();
    await prefs.setStringList(_profilesKey, profilesJson);
  }
}
