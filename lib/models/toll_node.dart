class TollNode {
  final String id;
  final String nom;
  final String autoroute;
  final String reseau;
  final String? ville;
  final double? latitude;
  final double? longitude;

  TollNode({
    required this.id,
    required this.nom,
    required this.autoroute,
    required this.reseau,
    this.ville,
    this.latitude,
    this.longitude,
  });

  factory TollNode.fromJson(Map<String, dynamic> json) {
    double? parseCoordinate(dynamic value) {
      if (value == null || value == '') return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return null;
        return double.tryParse(trimmed);
      }
      return null;
    }

    return TollNode(
      id: json['id'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      autoroute: json['autoroute'] as String? ?? '',
      reseau: json['reseau'] as String? ?? '',
      ville: json['ville'] as String?,
      latitude: parseCoordinate(json['latitude']),
      longitude: parseCoordinate(json['longitude']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'autoroute': autoroute,
      'reseau': reseau,
      if (ville != null) 'ville': ville,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  // Nom complet pour l'affichage (format: "NOM / AUTOROUTE")
  String get displayName => '$nom / $autoroute';

  @override
  String toString() => displayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TollNode && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
