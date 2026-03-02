/// Exemples pratiques d'utilisation du service OverpassApiService
/// 
/// Ce fichier contient des exemples concrets pour utiliser l'API Overpass
/// dans votre application Ecotoroute.

import '../services/overpass_api_service.dart';
import '../models/toll_gate.dart';
import '../services/openstreetmap_service.dart';

/// Exemple 1: Recherche simple de péages avec Query Builder
Future<void> exemple1_RechercheSimple() async {
  print('\n=== EXEMPLE 1: Recherche simple de péages ===\n');
  
  final apiService = OverpassApiService();
  
  // Utiliser le Query Builder pour chercher les péages en France
  final peages = await apiService
      .createQuery()
      .inCountry('FR')                          // Dans toute la France
      .addNode('barrier', 'toll_booth')         // Nœuds de type péage
      .timeout(30)                              // Timeout de 30 secondes
      .limit(20)                                // Maximum 20 résultats
      .execute();
  
  print('Trouvé ${peages.length} péages');
  
  // Afficher les premiers résultats
  for (var i = 0; i < peages.length && i < 5; i++) {
    final peage = peages[i];
    final tags = peage['tags'] as Map<String, dynamic>? ?? {};
    final name = tags['name'] ?? 'Sans nom';
    final lat = peage['lat'] ?? 'N/A';
    final lon = peage['lon'] ?? 'N/A';
    
    print('  ${i + 1}. $name');
    print('     Coordonnées: $lat, $lon');
  }
}

/// Exemple 2: Recherche dans une zone géographique (BBox)
Future<void> exemple2_RechercheZoneGeographique() async {
  print('\n=== EXEMPLE 2: Recherche dans une zone (Île-de-France) ===\n');
  
  final apiService = OverpassApiService();
  
  // Zone autour de Paris et Île-de-France
  // Format: minLat, minLon, maxLat, maxLon
  final peages = await apiService.getTollsInBoundingBox(
    48.5,  // Min latitude
    1.8,   // Min longitude
    49.2,  // Max latitude
    3.0,   // Max longitude
    maxResults: 30,
  );
  
  print('Péages trouvés en Île-de-France: ${peages.length}');
  
  // Grouper par autoroute
  final Map<String, int> parAutoroute = {};
  for (final peage in peages) {
    final tags = peage['tags'] as Map<String, dynamic>? ?? {};
    final ref = tags['ref'] as String? ?? 'Inconnu';
    parAutoroute[ref] = (parAutoroute[ref] ?? 0) + 1;
  }
  
  print('\nRépartition par autoroute:');
  parAutoroute.forEach((autoroute, nombre) {
    print('  $autoroute: $nombre péage(s)');
  });
}

/// Exemple 3: Recherche autour d'un point spécifique
Future<void> exemple3_RechercheAutourPoint() async {
  print('\n=== EXEMPLE 3: Recherche autour de Paris (50km) ===\n');
  
  final apiService = OverpassApiService();
  
  // Coordonnées de Paris
  final parisLat = 48.8566;
  final parisLon = 2.3522;
  
  // Chercher tous les péages dans un rayon de 50km
  final peages = await apiService.searchAroundPoint(
    parisLat,
    parisLon,
    50000,  // 50km en mètres
    tagKey: 'barrier',
    tagValue: 'toll_booth',
    maxResults: 25,
  );
  
  print('Péages dans un rayon de 50km autour de Paris: ${peages.length}');
  
  // Calculer la distance approximative et trier
  for (final peage in peages.take(10)) {
    final tags = peage['tags'] as Map<String, dynamic>? ?? {};
    final name = tags['name'] ?? 'Sans nom';
    final lat = peage['lat'] as double? ?? 0;
    final lon = peage['lon'] as double? ?? 0;
    
    // Distance approximative (formule simplifiée)
    final distanceKm = _calculerDistance(parisLat, parisLon, lat, lon);
    
    print('  • $name - ${distanceKm.toStringAsFixed(1)} km');
  }
}

/// Exemple 4: Recherche complexe avec plusieurs critères
Future<void> exemple4_RechercheComplexe() async {
  print('\n=== EXEMPLE 4: Recherche avancée (péages + portiques) ===\n');
  
  final apiService = OverpassApiService();
  
  // Construction d'une requête complexe
  final query = '''
[out:json][timeout:30];
area["ISO3166-1"="FR"][admin_level=2];
(
  node["barrier"="toll_booth"]["name"](area);
  node["highway"="toll_gantry"]["name"](area);
);
out center 50;
''';
  
  final result = await apiService.executeQuery(query);
  final elements = result['elements'] as List<dynamic>? ?? [];
  
  print('Éléments trouvés: ${elements.length}');
  
  // Séparer par type
  var barrières = 0;
  var portiques = 0;
  
  for (final element in elements) {
    final tags = element['tags'] as Map<String, dynamic>? ?? {};
    if (tags['barrier'] == 'toll_booth') barrières++;
    if (tags['highway'] == 'toll_gantry') portiques++;
  }
  
  print('  - Barrières de péage: $barrières');
  print('  - Portiques télépéage: $portiques');
}

/// Exemple 5: Utilisation du Query Builder avancé
Future<void> exemple5_QueryBuilderAvance() async {
  print('\n=== EXEMPLE 5: Query Builder avec multiples conditions ===\n');
  
  final apiService = OverpassApiService();
  
  // Construire une requête étape par étape
  final builder = apiService
      .createQuery()
      .inCountry('FR')
      .addNode('barrier', 'toll_booth')
      .addWay('barrier', 'toll_booth')
      .timeout(35)
      .limit(100);
  
  // Voir la requête générée (pour debug)
  print('Requête générée:');
  print(builder.build());
  print('\n');
  
  // Exécuter la requête
  final results = await builder.execute();
  print('Résultats obtenus: ${results.length}');
  
  // Analyser les résultats
  var nodes = 0;
  var ways = 0;
  
  for (final result in results) {
    if (result['type'] == 'node') nodes++;
    if (result['type'] == 'way') ways++;
  }
  
  print('  - Nodes: $nodes');
  print('  - Ways: $ways');
}

/// Exemple 6: Intégration avec le service OSM existant
Future<void> exemple6_IntegrationOSMService() async {
  print('\n=== EXEMPLE 6: Combiner avec OpenStreetMapService ===\n');
  
  final osmService = OpenStreetMapService();
  final apiService = OverpassApiService();
  
  // 1. Chercher un péage avec le service OSM simple
  print('1. Recherche avec OSM Service...');
  final tollGatesOSM = await osmService.searchTollGates('Saint-Arnoult');
  print('   Trouvé ${tollGatesOSM.length} résultat(s) OSM');
  
  if (tollGatesOSM.isNotEmpty) {
    final premier = tollGatesOSM.first;
    print('   Premier: ${premier.name}');
    
    if (premier.hasCoordinates) {
      // 2. Utiliser l'API avancée pour chercher autour de ce péage
      print('\n2. Recherche autour du péage avec API avancée...');
      final autour = await apiService.searchAroundPoint(
        premier.latitude!,
        premier.longitude!,
        10000,  // 10km
        maxResults: 20,
      );
      
      print('   Trouvé ${autour.length} élément(s) dans un rayon de 10km');
      
      // Compter les types d'éléments
      final types = <String, int>{};
      for (final element in autour) {
        final tags = element['tags'] as Map<String, dynamic>? ?? {};
        final amenity = tags['amenity'] as String?;
        final barrier = tags['barrier'] as String?;
        final highway = tags['highway'] as String?;
        
        final type = amenity ?? barrier ?? highway ?? 'autre';
        types[type] = (types[type] ?? 0) + 1;
      }
      
      print('\n   Types d\'éléments trouvés:');
      types.forEach((type, count) {
        print('     - $type: $count');
      });
    }
  }
}

/// Exemple 7: Statistiques sur les péages français
Future<void> exemple7_Statistiques() async {
  print('\n=== EXEMPLE 7: Statistiques des péages en France ===\n');
  
  final apiService = OverpassApiService();
  
  print('Récupération des statistiques...');
  final stats = await apiService.getFrenchTollStatistics();
  
  print('Total de péages: ${stats['total_tolls']}');
  print('Date de la requête: ${stats['query_timestamp']}');
  print('Serveur utilisé: ${stats['server_used']}');
}

/// Exemple 8: Test de connectivité et changement de serveur
Future<void> exemple8_GestionServeurs() async {
  print('\n=== EXEMPLE 8: Gestion des serveurs Overpass ===\n');
  
  final apiService = OverpassApiService();
  
  print('Serveurs disponibles:');
  for (var i = 0; i < OverpassApiService.overpassServers.length; i++) {
    print('  ${i + 1}. ${OverpassApiService.overpassServers[i]}');
  }
  
  print('\nServeur actuel: ${apiService.currentServer}');
  
  print('\nTest de connexion...');
  final isConnected = await apiService.testConnection();
  print('Connexion: ${isConnected ? "✓ OK" : "✗ Échec"}');
  
  if (isConnected) {
    print('\nStatut du serveur...');
    final status = await apiService.getServerStatus();
    print('Disponible: ${status['available']}');
    print('Code HTTP: ${status['status_code']}');
  }
  
  // Changer de serveur
  if (OverpassApiService.overpassServers.length > 1) {
    print('\n--- Changement de serveur ---');
    apiService.setServer(OverpassApiService.overpassServers[1]);
    print('Nouveau serveur: ${apiService.currentServer}');
  }
}

/// Exemple 9: Recherche de péages sur une autoroute spécifique
Future<void> exemple9_PeagesParAutoroute() async {
  print('\n=== EXEMPLE 9: Tous les péages de l\'A1 ===\n');
  
  final apiService = OverpassApiService();
  
  // Rechercher tous les éléments avec tag ref=A1
  final elements = await apiService.getElementsWithTag(
    'ref',
    'A1',
    country: 'FR',
    maxResults: 100,
  );
  
  print('Éléments trouvés avec ref=A1: ${elements.length}');
  
  // Filtrer uniquement les péages
  final peagesA1 = elements.where((element) {
    final tags = element['tags'] as Map<String, dynamic>? ?? {};
    return tags['barrier'] == 'toll_booth' || tags['highway'] == 'toll_gantry';
  }).toList();
  
  print('Péages sur l\'A1: ${peagesA1.length}');
  
  for (var i = 0; i < peagesA1.length && i < 10; i++) {
    final peage = peagesA1[i];
    final tags = peage['tags'] as Map<String, dynamic>? ?? {};
    final name = tags['name'] ?? 'Sans nom';
    print('  ${i + 1}. $name');
  }
}

/// Exemple 10: Gestion des erreurs
Future<void> exemple10_GestionErreurs() async {
  print('\n=== EXEMPLE 10: Gestion des erreurs ===\n');
  
  final apiService = OverpassApiService();
  
  try {
    // Requête incorrecte intentionnellement
    final query = '''
[out:json][timeout:5];
(
  node["invalid_tag"=""](this-will-fail);
);
out;
''';
    
    await apiService.executeQuery(query, timeout: 10);
    print('Requête réussie');
    
  } on OverpassApiException catch (e) {
    print('Erreur Overpass API:');
    print('  Message: ${e.message}');
    if (e.statusCode != null) {
      print('  Code HTTP: ${e.statusCode}');
    }
    
    // Gérer différents types d'erreurs
    if (e.statusCode == 429) {
      print('  → Rate limit atteint. Attendez avant de réessayer.');
    } else if (e.statusCode == 504) {
      print('  → Timeout. Essayez une requête plus simple.');
    } else {
      print('  → Erreur API. Vérifiez votre requête.');
    }
    
  } catch (e) {
    print('Erreur inattendue: $e');
  }
}

/// Fonction utilitaire pour calculer la distance approximative
double _calculerDistance(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371; // km
  
  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lon2 - lon1);
  
  final a = 
      (dLat / 2).abs() * (dLat / 2).abs() +
      lat1 * lat2 * (dLon / 2).abs() * (dLon / 2).abs();
  
  final c = 2 * (a.abs());
  return earthRadius * c;
}

double _degToRad(double deg) {
  return deg * (3.141592653589793 / 180);
}

/// FONCTION PRINCIPALE - Exécuter tous les exemples
Future<void> executerTousLesExemples() async {
  print('╔════════════════════════════════════════════════════════╗');
  print('║  EXEMPLES D\'UTILISATION - OVERPASS API SERVICE        ║');
  print('╚════════════════════════════════════════════════════════╝');
  
  try {
    await exemple1_RechercheSimple();
    await Future.delayed(Duration(seconds: 2)); // Pause entre requêtes
    
    await exemple2_RechercheZoneGeographique();
    await Future.delayed(Duration(seconds: 2));
    
    await exemple3_RechercheAutourPoint();
    await Future.delayed(Duration(seconds: 2));
    
    await exemple4_RechercheComplexe();
    await Future.delayed(Duration(seconds: 2));
    
    await exemple5_QueryBuilderAvance();
    await Future.delayed(Duration(seconds: 2));
    
    await exemple6_IntegrationOSMService();
    await Future.delayed(Duration(seconds: 2));
    
    await exemple7_Statistiques();
    await Future.delayed(Duration(seconds: 2));
    
    await exemple8_GestionServeurs();
    await Future.delayed(Duration(seconds: 2));
    
    await exemple9_PeagesParAutoroute();
    await Future.delayed(Duration(seconds: 2));
    
    await exemple10_GestionErreurs();
    
    print('\n╔════════════════════════════════════════════════════════╗');
    print('║  TOUS LES EXEMPLES TERMINÉS !                          ║');
    print('╚════════════════════════════════════════════════════════╝\n');
    
  } catch (e) {
    print('\n❌ Erreur lors de l\'exécution des exemples: $e');
  }
}

/// Exemple spécifique pour intégrer dans votre application
class OverpassApiHelper {
  final OverpassApiService _apiService = OverpassApiService();
  
  /// Chercher les péages près d'un trajet (de départ à arrivée)
  Future<List<Map<String, dynamic>>> chercherPeagesSurTrajet(
    String departure,
    String arrival,
  ) async {
    // Ceci est un exemple simplifié
    // Dans la vraie vie, vous devriez utiliser les coordonnées du trajet
    
    final osmService = OpenStreetMapService();
    
    // Normaliser les noms
    final depClean = osmService.normalizeName(departure);
    final arrClean = osmService.normalizeName(arrival);
    
    print('Recherche de péages entre $depClean et $arrClean...');
    
    // Rechercher les péages dans toute la France
    // (vous pourriez affiner en utilisant une bbox calculée depuis le trajet)
    final peages = await _apiService
        .createQuery()
        .inCountry('FR')
        .addNode('barrier', 'toll_booth')
        .limit(100)
        .execute();
    
    return peages;
  }
  
  /// Obtenir les détails complets d'un péage par son nom
  Future<TollGate?> obtenirDetailsPeage(String nomPeage) async {
    final osmService = OpenStreetMapService();
    final result = await osmService.findTollGateByName(nomPeage);
    return result;
  }
  
  /// Lister tous les péages d'une autoroute
  Future<List<TollGate>> listerPeagesAutoroute(String autoroute) async {
    final osmService = OpenStreetMapService();
    final results = await osmService.searchTollGatesByHighway(autoroute);
    return results;
  }
}
