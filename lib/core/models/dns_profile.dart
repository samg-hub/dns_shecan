import 'dart:convert';

class DNSProfile {
  final String id;
  final String name;
  final List<String> servers;
  final bool isPredefined;

  DNSProfile({
    required this.id,
    required this.name,
    required this.servers,
    this.isPredefined = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'servers': servers,
      'isPredefined': isPredefined,
    };
  }

  factory DNSProfile.fromMap(Map<String, dynamic> map) {
    return DNSProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      servers: List<String>.from(map['servers'] ?? []),
      isPredefined: map['isPredefined'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory DNSProfile.fromJson(String source) =>
      DNSProfile.fromMap(json.decode(source));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DNSProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
