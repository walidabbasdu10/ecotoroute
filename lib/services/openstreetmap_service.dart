import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/toll_gate.dart';

class OpenStreetMapService {
  static final OpenStreetMapService _instance = OpenStreetMapService._internal();
  factory OpenStreetMapService() => _instance;
  OpenStreetMapService._internal();

  // URL de l'API Overpass
  static const String overpassUrl = 'https://overpass-api.de/api/interpreter';
  
  // Cache des péages déjà recherchés
  final Map<String, List<TollGate>> _cache = {};

  /// Recherche les péages en France via l'API Overpass d'OpenStreetMap
  /// Récupère les coordonnées GPS, le nom et l'autoroute
  Future<List<TollGate>> searchTollGates(String searchQuery, {
    String country = 'FR',
    int maxResults = 50,
  }) async {
    // Vérifier le cache
    final cacheKey = '$searchQuery-$country';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      // Requête Overpass pour chercher les péages (toll booths et toll gates)
      // On cherche dans toute la France si pas de coordonnées spécifiques
      final query = '''
[out:json][timeout:25];
area["ISO3166-1"="$country"][admin_level=2];
(
  node["barrier"="toll_booth"]["name"~"$searchQuery",i](area);
  node["highway"="toll_gantry"]["name"~"$searchQuery",i](area);
  way["barrier"="toll_booth"]["name"~"$searchQuery",i](area);
);
out center $maxResults;
''';

      final response = await http.post(
        Uri.parse(overpassUrl),
        body: query,
        headers: {'Content-Type': 'text/plain; charset=utf-8'},
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur API Overpass: ${response.statusCode}');
      }

      final data = json.decode(utf8.decode(response.bodyBytes));
      final elements = data['elements'] as List<dynamic>? ?? [];

      final tollGates = elements
          .map((element) => TollGate.fromOsmJson(element as Map<String, dynamic>))
          .toList();

      // Mettre en cache
      _cache[cacheKey] = tollGates;

      return tollGates;
    } catch (e) {
      throw Exception('Erreur lors de la recherche de péages: $e');
    }
  }

  /// Recherche tous les péages sur une autoroute spécifique (ex: A1, A6, etc.)
  Future<List<TollGate>> searchTollGatesByHighway(String highwayRef, {
    String country = 'FR',
  }) async {
    final cacheKey = 'highway-$highwayRef-$country';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final query = '''
[out:json][timeout:25];
area["ISO3166-1"="$country"][admin_level=2];
(
  node["barrier"="toll_booth"]["ref"~"$highwayRef",i](area);
  node["highway"="toll_gantry"]["ref"~"$highwayRef",i](area);
  way["barrier"="toll_booth"]["ref"~"$highwayRef",i](area);
);
out center 100;
''';

      final response = await http.post(
        Uri.parse(overpassUrl),
        body: query,
        headers: {'Content-Type': 'text/plain; charset=utf-8'},
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur API Overpass: ${response.statusCode}');
      }

      final data = json.decode(utf8.decode(response.bodyBytes));
      final elements = data['elements'] as List<dynamic>? ?? [];

      final tollGates = elements
          .map((element) => TollGate.fromOsmJson(element as Map<String, dynamic>))
          .toList();

      _cache[cacheKey] = tollGates;

      return tollGates;
    } catch (e) {
      throw Exception('Erreur lors de la recherche de péages: $e');
    }
  }

  /// Recherche un péage par nom exact dans une zone géographique
  Future<TollGate?> findTollGateByName(String name, {
    double? centerLat,
    double? centerLon,
    double radiusKm = 50,
  }) async {
    try {
      String areaQuery;
      if (centerLat != null && centerLon != null) {
        // Recherche dans un rayon autour d'un point
        final radiusMeters = radiusKm * 1000;
        areaQuery = '(around:$radiusMeters,$centerLat,$centerLon)';
      } else {
        // Recherche dans toute la France
        areaQuery = '(area)';
      }

      final query = '''
[out:json][timeout:25];
${centerLat == null ? 'area["ISO3166-1"="FR"][admin_level=2];' : ''}
(
  node["barrier"="toll_booth"]["name"="$name"]$areaQuery;
  node["highway"="toll_gantry"]["name"="$name"]$areaQuery;
  way["barrier"="toll_booth"]["name"="$name"]$areaQuery;
);
out center 1;
''';

      final response = await http.post(
        Uri.parse(overpassUrl),
        body: query,
        headers: {'Content-Type': 'text/plain; charset=utf-8'},
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(utf8.decode(response.bodyBytes));
      final elements = data['elements'] as List<dynamic>? ?? [];

      if (elements.isEmpty) return null;

      return TollGate.fromOsmJson(elements[0] as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Récupère tous les péages de France (attention: requête lourde)
  Future<List<TollGate>> getAllFrenchTollGates() async {
    const cacheKey = 'all-france';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final query = '''
[out:json][timeout:60];
area["ISO3166-1"="FR"][admin_level=2];
(
  node["barrier"="toll_booth"](area);
  node["highway"="toll_gantry"](area);
  way["barrier"="toll_booth"](area);
);
out center 500;
''';

      final response = await http.post(
        Uri.parse(overpassUrl),
        body: query,
        headers: {'Content-Type': 'text/plain; charset=utf-8'},
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur API Overpass: ${response.statusCode}');
      }

      final data = json.decode(utf8.decode(response.bodyBytes));
      final elements = data['elements'] as List<dynamic>? ?? [];

      final tollGates = elements
          .map((element) => TollGate.fromOsmJson(element as Map<String, dynamic>))
          .toList();

      _cache[cacheKey] = tollGates;

      return tollGates;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des péages: $e');
    }
  }

  /// Normalise un nom de lieu pour la recherche
  String normalizeName(String name) {
    String cleaned = name.trim();
    
    // Enlever les codes /A### à la fin
    cleaned = cleaned.replaceAll(RegExp(r'\s*/\s*A\d+$'), '').trim();
    
    // Enlever les codes (##) au début
    cleaned = cleaned.replaceAll(RegExp(r'^\(\d+\)\s*'), '').trim();
    
    // Enlever les N°### à la fin
    cleaned = cleaned.replaceAll(RegExp(r'\s*N°\d+$'), '').trim();
    
    return cleaned;
  }

  /// Vide le cache
  void clearCache() {
    _cache.clear();
  }
}
