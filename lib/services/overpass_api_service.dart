import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service avancé pour interagir directement avec l'API Overpass
/// Permet d'exécuter des requêtes personnalisées et d'explorer les données OSM
class OverpassApiService {
  static final OverpassApiService _instance = OverpassApiService._internal();
  factory OverpassApiService() => _instance;
  OverpassApiService._internal();

  // URLs des différents serveurs Overpass disponibles
  static const List<String> overpassServers = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.openstreetmap.ru/api/interpreter',
  ];

  String _currentServer = overpassServers[0];
  final Map<String, dynamic> _statsCache = {};

  /// Change le serveur Overpass utilisé
  void setServer(String serverUrl) {
    if (overpassServers.contains(serverUrl)) {
      _currentServer = serverUrl;
    }
  }

  String get currentServer => _currentServer;

  /// Exécute une requête Overpass brute et retourne le JSON
  Future<Map<String, dynamic>> executeQuery(
    String query, {
    int timeout = 25,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_currentServer),
        body: query,
        headers: {'Content-Type': 'text/plain; charset=utf-8'},
      ).timeout(Duration(seconds: timeout + 5));

      if (response.statusCode != 200) {
        throw OverpassApiException(
          'Erreur HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      if (e is OverpassApiException) rethrow;
      throw OverpassApiException('Erreur lors de l\'exécution de la requête: $e');
    }
  }

  /// Récupère tous les péages dans un rectangle géographique (bbox)
  /// bbox format: [minLat, minLon, maxLat, maxLon]
  Future<List<Map<String, dynamic>>> getTollsInBoundingBox(
    double minLat,
    double minLon,
    double maxLat,
    double maxLon, {
    int maxResults = 100,
  }) async {
    final query = '''
[out:json][timeout:25];
(
  node["barrier"="toll_booth"]($minLat,$minLon,$maxLat,$maxLon);
  node["highway"="toll_gantry"]($minLat,$minLon,$maxLat,$maxLon);
  way["barrier"="toll_booth"]($minLat,$minLon,$maxLat,$maxLon);
);
out center $maxResults;
''';

    final result = await executeQuery(query);
    return List<Map<String, dynamic>>.from(result['elements'] ?? []);
  }

  /// Récupère tous les éléments avec un tag spécifique dans une zone
  Future<List<Map<String, dynamic>>> getElementsWithTag(
    String key,
    String value, {
    String? country = 'FR',
    int maxResults = 100,
  }) async {
    final areaQuery = country != null 
        ? 'area["ISO3166-1"="$country"][admin_level=2];' 
        : '';
    
    final query = '''
[out:json][timeout:25];
$areaQuery
(
  node["$key"="$value"](area);
  way["$key"="$value"](area);
  relation["$key"="$value"](area);
);
out center $maxResults;
''';

    final result = await executeQuery(query);
    return List<Map<String, dynamic>>.from(result['elements'] ?? []);
  }

  /// Recherche d'éléments autour d'un point (rayon en mètres)
  Future<List<Map<String, dynamic>>> searchAroundPoint(
    double lat,
    double lon,
    double radiusMeters, {
    String? tagKey,
    String? tagValue,
    int maxResults = 50,
  }) async {
    final tagFilter = tagKey != null && tagValue != null 
        ? '["$tagKey"="$tagValue"]' 
        : '';

    final query = '''
[out:json][timeout:25];
(
  node$tagFilter(around:$radiusMeters,$lat,$lon);
  way$tagFilter(around:$radiusMeters,$lat,$lon);
);
out center $maxResults;
''';

    final result = await executeQuery(query);
    return List<Map<String, dynamic>>.from(result['elements'] ?? []);
  }

  /// Récupère les statistiques sur les péages en France
  Future<Map<String, dynamic>> getFrenchTollStatistics() async {
    // Vérifier le cache
    if (_statsCache.containsKey('french_tolls')) {
      return _statsCache['french_tolls'] as Map<String, dynamic>;
    }

    final query = '''
[out:json][timeout:30];
area["ISO3166-1"="FR"][admin_level=2];
(
  node["barrier"="toll_booth"](area);
  node["highway"="toll_gantry"](area);
  way["barrier"="toll_booth"](area);
);
out count;
''';

    try {
      final result = await executeQuery(query);
      final elements = result['elements'] as List<dynamic>? ?? [];
      
      final stats = {
        'total_tolls': elements.length,
        'query_timestamp': DateTime.now().toIso8601String(),
        'server_used': _currentServer,
      };

      _statsCache['french_tolls'] = stats;
      return stats;
    } catch (e) {
      return {
        'error': e.toString(),
        'query_timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Recherche d'autoroutes en France avec leurs péages
  Future<Map<String, List<Map<String, dynamic>>>> getHighwaysWithTolls() async {
    // Requête pour obtenir les autoroutes et leurs péages
    final query = '''
[out:json][timeout:60];
area["ISO3166-1"="FR"][admin_level=2];
(
  way["highway"="motorway"]["ref"](area);
  node["barrier"="toll_booth"](area);
);
out body;
>;
out skel qt;
''';

    final result = await executeQuery(query);
    final elements = List<Map<String, dynamic>>.from(result['elements'] ?? []);

    // Grouper les péages par autoroute
    final Map<String, List<Map<String, dynamic>>> highwayTolls = {};
    
    for (final element in elements) {
      final tags = element['tags'] as Map<String, dynamic>? ?? {};
      if (element['type'] == 'node' && tags['barrier'] == 'toll_booth') {
        final ref = tags['ref'] as String? ?? 'Inconnu';
        highwayTolls.putIfAbsent(ref, () => []);
        highwayTolls[ref]!.add(element);
      }
    }

    return highwayTolls;
  }

  /// Récupère des informations détaillées sur un élément OSM par son ID
  Future<Map<String, dynamic>?> getElementDetails(
    String elementType,
    int elementId,
  ) async {
    if (!['node', 'way', 'relation'].contains(elementType)) {
      throw ArgumentError('Type doit être: node, way, ou relation');
    }

    final query = '''
[out:json][timeout:15];
$elementType($elementId);
out body;
>;
out skel qt;
''';

    final result = await executeQuery(query);
    final elements = result['elements'] as List<dynamic>? ?? [];
    
    if (elements.isEmpty) return null;
    return elements[0] as Map<String, dynamic>;
  }

  /// Requête personnalisée avec construction facile
  OverpassQueryBuilder createQuery() {
    return OverpassQueryBuilder(this);
  }

  /// Test de connectivité avec le serveur Overpass
  Future<bool> testConnection() async {
    try {
      final query = '[out:json][timeout:5];node(0);out;';
      await executeQuery(query, timeout: 10);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Obtient le statut du serveur Overpass
  Future<Map<String, dynamic>> getServerStatus() async {
    try {
      final statusUrl = _currentServer.replaceAll('/interpreter', '/status');
      final response = await http.get(Uri.parse(statusUrl));
      
      return {
        'server': _currentServer,
        'status_code': response.statusCode,
        'available': response.statusCode == 200,
        'response_time_ms': response.headers['x-response-time'],
      };
    } catch (e) {
      return {
        'server': _currentServer,
        'available': false,
        'error': e.toString(),
      };
    }
  }

  void clearCache() {
    _statsCache.clear();
  }
}

/// Builder pour construire des requêtes Overpass facilement
class OverpassQueryBuilder {
  final OverpassApiService _service;
  final List<String> _elements = [];
  String _area = '';
  int _timeout = 25;
  int _maxResults = 100;

  OverpassQueryBuilder(this._service);

  /// Définit la zone de recherche (pays)
  OverpassQueryBuilder inCountry(String countryCode) {
    _area = 'area["ISO3166-1"="$countryCode"][admin_level=2];';
    return this;
  }

  /// Définit la zone de recherche (bbox)
  OverpassQueryBuilder inBoundingBox(
    double minLat,
    double minLon,
    double maxLat,
    double maxLon,
  ) {
    _area = '($minLat,$minLon,$maxLat,$maxLon)';
    return this;
  }

  /// Ajoute un filtre pour les nodes avec un tag
  OverpassQueryBuilder addNode(String key, String value) {
    _elements.add('node["$key"="$value"]${_area.isEmpty ? '' : '(area)'}');
    return this;
  }

  /// Ajoute un filtre pour les ways avec un tag
  OverpassQueryBuilder addWay(String key, String value) {
    _elements.add('way["$key"="$value"]${_area.isEmpty ? '' : '(area)'}');
    return this;
  }

  /// Définit le timeout
  OverpassQueryBuilder timeout(int seconds) {
    _timeout = seconds;
    return this;
  }

  /// Définit le nombre maximum de résultats
  OverpassQueryBuilder limit(int max) {
    _maxResults = max;
    return this;
  }

  /// Construit la requête
  String build() {
    if (_elements.isEmpty) {
      throw StateError('Aucun élément ajouté à la requête');
    }

    final elementsStr = _elements.join(';\n  ');
    
    return '''
[out:json][timeout:$_timeout];
${_area.isNotEmpty && !_area.startsWith('(') ? _area : ''}
(
  $elementsStr;
);
out center $_maxResults;
''';
  }

  /// Exécute la requête
  Future<List<Map<String, dynamic>>> execute() async {
    final query = build();
    final result = await _service.executeQuery(query, timeout: _timeout);
    return List<Map<String, dynamic>>.from(result['elements'] ?? []);
  }
}

/// Exception personnalisée pour les erreurs de l'API Overpass
class OverpassApiException implements Exception {
  final String message;
  final int? statusCode;

  OverpassApiException(this.message, {this.statusCode});

  @override
  String toString() => 'OverpassApiException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}
