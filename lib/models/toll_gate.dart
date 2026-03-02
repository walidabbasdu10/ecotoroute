class TollGate {
  final String name;
  final String? normalizedName;
  final double? latitude;
  final double? longitude;
  final String? highwayName;
  final String? highwayRef;
  final String? operator;
  final Map<String, dynamic>? osmData;

  TollGate({
    required this.name,
    this.normalizedName,
    this.latitude,
    this.longitude,
    this.highwayName,
    this.highwayRef,
    this.operator,
    this.osmData,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  factory TollGate.fromOsmJson(Map<String, dynamic> json) {
    final tags = json['tags'] as Map<String, dynamic>? ?? {};
    final lat = json['lat'] as double?;
    final lon = json['lon'] as double?;

    String? name = tags['name'] as String?;
    String? ref = tags['ref'] as String?;
    String? highway = tags['highway'] as String?;
    
    // Pour les ways, on prend le centre de la géométrie
    if (lat == null && json['center'] != null) {
      final center = json['center'] as Map<String, dynamic>;
      return TollGate(
        name: name ?? ref ?? 'Péage inconnu',
        latitude: center['lat'] as double?,
        longitude: center['lon'] as double?,
        highwayName: highway,
        highwayRef: ref,
        operator: tags['operator'] as String?,
        osmData: json,
      );
    }

    return TollGate(
      name: name ?? ref ?? 'Péage inconnu',
      latitude: lat,
      longitude: lon,
      highwayName: highway,
      highwayRef: ref,
      operator: tags['operator'] as String?,
      osmData: json,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'normalizedName': normalizedName,
    'latitude': latitude,
    'longitude': longitude,
    'highwayName': highwayName,
    'highwayRef': highwayRef,
    'operator': operator,
  };

  @override
  String toString() {
    final coords = hasCoordinates ? '($latitude, $longitude)' : 'Pas de coordonnées';
    final highway = highwayRef != null ? ' - $highwayRef' : '';
    return '$name$highway - $coords';
  }
}
