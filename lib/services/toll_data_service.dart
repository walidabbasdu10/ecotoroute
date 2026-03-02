import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/toll_route.dart';
import '../models/toll_node.dart';
import '../models/optimized_route.dart';

class TollDataService {
  static final TollDataService _instance = TollDataService._internal();
  factory TollDataService() => _instance;
  TollDataService._internal();

  List<TollRoute> _routes = [];
  List<TollNode> _nodes = [];
  List<String> _locations = [];
  Map<String, TollNode> _nodesById = {};
  bool _isLoaded = false;

  Future<void> loadData() async {
    if (_isLoaded) return;

    try {
      // Charger les nœuds de péage
      final nodesData = await rootBundle.loadString('assets/toll_nodes.json');
      final List<dynamic> nodesJson = json.decode(nodesData);
      _nodes = nodesJson.map((json) => TollNode.fromJson(json)).toList();
      
      // Créer un index des nœuds par ID
      _nodesById = {for (var node in _nodes) node.id: node};

      // Charger les routes (tarifs)
      final routesData = await rootBundle.loadString('assets/toll_routes.json');
      final List<dynamic> routesJson = json.decode(routesData);
      _routes = routesJson.map((json) => TollRoute.fromJson(json)).toList();

      // Charger la liste des lieux (nettoyée)
      final locationsData = await rootBundle.loadString('assets/locations_clean.json');
      final List<dynamic> locationsJson = json.decode(locationsData);
      _locations = locationsJson.cast<String>().toList();
      _locations.sort();

      _isLoaded = true;
      print('✓ Données chargées: ${_nodes.length} nœuds, ${_routes.length} routes');
    } catch (e) {
      throw Exception('Erreur lors du chargement des données: $e');
    }
  }

  List<String> get locations => _locations;
  List<TollRoute> get routes => _routes;
  List<TollNode> get nodes => _nodes;
  
  // Récupérer un nœud par son ID
  TollNode? getNodeById(String id) => _nodesById[id];
  
  // Récupérer un nœud par son nom d'affichage
  TollNode? getNodeByDisplayName(String displayName) {
    return _nodes.firstWhere(
      (node) => node.displayName == displayName,
      orElse: () => _nodes.first,
    );
  }

  List<String> searchLocations(String query) {
    if (query.isEmpty) return _locations;
    
    final queryLower = query.toLowerCase();
    return _locations
        .where((loc) => loc.toLowerCase().contains(queryLower))
        .toList();
  }

  // Extraire et normaliser le nom de base d'un lieu
  String _getBaseName(String location) {
    // 1. Enlever les codes /A### à la fin
    String cleaned = location.replaceAll(RegExp(r'\s*/\s*A\d+$'), '').trim();
    
    // 2. Enlever les numéros entre parenthèses au début : (17) St-Gibrien -> St-Gibrien
    cleaned = cleaned.replaceAll(RegExp(r'^\(\d+\)\s*'), '').trim();
    
    // 3. Enlever les N° à la fin : LE HAVRE N°5 -> LE HAVRE
    cleaned = cleaned.replaceAll(RegExp(r'\s*N°\d+$'), '').trim();
    
    // 4. Normaliser : majuscules, remplacer tirets par espaces
    cleaned = cleaned.toUpperCase().replaceAll('-', ' ');
    
    // 5. Normaliser les espaces multiples
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return cleaned;
  }

  // Extraire le nom de ville sans direction (pour connexions inter-autoroutes)
  String _getCityName(String location) {
    String base = _getBaseName(location);
    
    // Enlever les directions : NORD, SUD, EST, OUEST, CENTRE
    base = base.replaceAll(RegExp(r'\s+(NORD|SUD|EST|OUEST|CENTRE)$'), '').trim();
    
    return base;
  }

  TollRoute? findRoute(String from, String to) {
    try {
      // Chercher d'abord une correspondance exacte
      final exactMatch = _routes.firstWhere(
        (route) => route.from == from && route.to == to,
        orElse: () => throw Exception(),
      );
      return exactMatch;
    } catch (e) {
      // Si pas de correspondance exacte, chercher par nom de base
      final fromBase = _getBaseName(from);
      final toBase = _getBaseName(to);
      
      try {
        return _routes.firstWhere(
          (route) => _getBaseName(route.from) == fromBase && 
                     _getBaseName(route.to) == toBase,
        );
      } catch (e) {
        return null;
      }
    }
  }

  double? calculateToll(String from, String to) {
    final route = findRoute(from, to);
    return route?.price;
  }

  // Obtenir tous les trajets disponibles depuis un point de départ
  List<TollRoute> getRoutesFrom(String from) {
    final fromBase = _getBaseName(from);
    return _routes.where((route) => _getBaseName(route.from) == fromBase).toList();
  }

  // Obtenir tous les points accessibles depuis un lieu
  List<String> getDestinationsFrom(String from) {
    final fromBase = _getBaseName(from);
    
    // Récupérer toutes les destinations uniques (en utilisant le nom de base)
    final destinations = <String>{};
    for (var route in _routes) {
      if (_getBaseName(route.from) == fromBase) {
        final toBase = _getBaseName(route.to);
        // Ne pas inclure les trajets vers soi-même
        if (toBase != fromBase) {
          destinations.add(toBase);
        }
      }
    }
    
    return destinations.toList()..sort();
  }

  // Vérifier si un trajet existe
  bool routeExists(String from, String to) {
    return findRoute(from, to) != null;
  }

  // Obtenir des statistiques
  Map<String, int> getStats() {
    final fromLocations = _routes.map((r) => r.from).toSet().length;
    final toLocations = _routes.map((r) => r.to).toSet().length;
    return {
      'totalRoutes': _routes.length,
      'totalLocations': _locations.length,
      'fromLocations': fromLocations,
      'toLocations': toLocations,
    };
  }

  // Trouver le trajet optimal (direct, avec 1 ou plusieurs segments)
  OptimizedRoute? findOptimalRoute(String from, String to) {
    try {
      final fromBase = _getBaseName(from);
      final toBase = _getBaseName(to);

      // 1. Chercher le trajet direct
      final directRoute = findRoute(from, to);
      double? directPrice = directRoute?.price;

      // Si trajet direct existe, le retourner immédiatement
      if (directPrice != null) {
        return OptimizedRoute(
          segments: [
            RouteSegment(from: from, to: to, price: directPrice),
          ],
          totalPrice: directPrice,
          isDirect: true,
        );
      }

      // 2. Si pas de trajet direct, chercher avec l'algorithme multi-segments
      return _findMultiSegmentRoute(fromBase, toBase);
      
    } catch (e) {
      print('❌ Erreur dans findOptimalRoute: $e');
      return null;
    }
  }

  // Algorithme de recherche de chemin multi-segments (Dijkstra simplifié)
  OptimizedRoute? _findMultiSegmentRoute(String fromBase, String toBase) {
    print('🚀 Recherche chemin: $fromBase -> $toBase');
    
    // Map des distances minimales depuis le départ
    final distances = <String, double>{fromBase: 0.0};
    
    // Map pour reconstruire le chemin optimal
    final previous = <String, String>{};
    
    // Map pour stocker les segments utilisés
    final segmentMap = <String, TollRoute>{};
    
    // Ensemble des nœuds à visiter
    final unvisited = <String>{};
    
    // Map: ville -> liste de péages dans cette ville (pour connexions inter-autoroutes)
    final cityNodes = <String, List<String>>{};
    
    // Map: nom de base -> nom de ville (pour recherche rapide)
    final nodeToCity = <String, String>{};
    
    // Initialiser tous les nœuds et grouper par ville
    for (var route in _routes) {
      final from = _getBaseName(route.from);
      final to = _getBaseName(route.to);
      
      if (!unvisited.contains(from)) {
        unvisited.add(from);
        // Grouper par ville
        final cityFrom = _getCityName(route.from);
        if (!cityNodes.containsKey(cityFrom)) cityNodes[cityFrom] = [];
        cityNodes[cityFrom]!.add(from);
        nodeToCity[from] = cityFrom;
      }
      if (!unvisited.contains(to)) {
        unvisited.add(to);
        final cityTo = _getCityName(route.to);
        if (!cityNodes.containsKey(cityTo)) cityNodes[cityTo] = [];
        cityNodes[cityTo]!.add(to);
        nodeToCity[to] = cityTo;
      }
      
      if (!distances.containsKey(from)) distances[from] = double.infinity;
      if (!distances.containsKey(to)) distances[to] = double.infinity;
    }
    
    // Compter les connexions inter-autoroutes disponibles
    final multiCityCount = cityNodes.values.where((nodes) => nodes.length > 1).length;
    print('📊 Graphe initialisé: ${unvisited.length} nœuds, $multiCityCount villes multi-péages');
    
    // Algorithme de Dijkstra
    int iterations = 0;
    while (unvisited.isNotEmpty) {  // Pas de limite, l'algo s'arrête naturellement
      iterations++;
      
      // Trouver le nœud non visité avec la plus petite distance
      String? current;
      double minDist = double.infinity;
      
      for (var node in unvisited) {
        final dist = distances[node] ?? double.infinity;
        if (dist < minDist) {
          minDist = dist;
          current = node;
        }
      }
      
      // Si aucun nœud accessible, on s'arrête
      if (current == null || minDist == double.infinity) {
        print('❌ Plus de nœud accessible après $iterations itérations');
        break;
      }
      
      // Si on a atteint la destination, on s'arrête
      if (current == toBase) {
        print('✅ Destination atteinte! ($iterations itérations, distance: ${distances[toBase]})');
        break;
      }
      
      unvisited.remove(current);
      
      if (iterations % 50 == 0) {
        print('⏳ Itération $iterations, nœuds restants: ${unvisited.length}');
      }
      
      // 1. Examiner tous les voisins directs (routes réelles)
      for (var route in _routes) {
        final routeFrom = _getBaseName(route.from);
        if (routeFrom != current) continue;
        
        final neighbor = _getBaseName(route.to);
        if (!unvisited.contains(neighbor)) continue;
        
        final newDist = (distances[current] ?? double.infinity) + route.price;
        
        if (newDist < (distances[neighbor] ?? double.infinity)) {
          distances[neighbor] = newDist;
          previous[neighbor] = current;
          segmentMap['$current->$neighbor'] = route;
        }
      }
      
      // 2. NOUVEAU: Connexions virtuelles entre péages de la même ville (coût = 0)
      // Permet de changer d'autoroute au même point géographique
      final currentCity = nodeToCity[current];
      
      if (currentCity != null && cityNodes.containsKey(currentCity)) {
        final sameCityNodes = cityNodes[currentCity]!;
        for (var neighbor in sameCityNodes) {
          if (neighbor == current || !unvisited.contains(neighbor)) continue;
          
          // Connexion locale gratuite (changement d'autoroute)
          final newDist = distances[current] ?? double.infinity;
          
          if (newDist < (distances[neighbor] ?? double.infinity)) {
            distances[neighbor] = newDist;
            previous[neighbor] = current;
            // Pas de segment réel pour les connexions locales
            // (on ne met rien dans segmentMap)
          }
        }
      }
    }
    
    // Si on n'a pas trouvé de chemin vers la destination
    if (!distances.containsKey(toBase) || distances[toBase] == double.infinity) {
      print('❌ Aucun chemin trouvé vers $toBase');
      print('   Les données ne contiennent pas d\'itinéraire connectant ces deux points.');
      print('   Points explorés: ${distances.length - unvisited.length}/${distances.length}');
      return null;
    }
    
    print('🔨 Reconstruction du chemin...');
    
    // Reconstruire le chemin
    final path = <String>[];
    String current = toBase;
    
    while (current != fromBase) {
      path.insert(0, current);
      final prev = previous[current];
      if (prev == null) {
        print('❌ Chemin incomplet (pas de previous pour $current)');
        return null; // Pas de chemin
      }
      current = prev;
    }
    path.insert(0, fromBase);
    
    print('🎯 Chemin trouvé: ${path.length} segments');
    for (int i = 0; i < path.length - 1; i++) {
      print('   Segment ${i+1}: ${path[i]} -> ${path[i+1]}');
    }
    
    // Construire les segments
    final segments = <RouteSegment>[];
    double totalPrice = 0.0;
    
    for (int i = 0; i < path.length - 1; i++) {
      final from = path[i];
      final to = path[i + 1];
      final segment = segmentMap['$from->$to'];
      
      if (segment != null) {
        // Segment réel avec péage
        segments.add(RouteSegment(
          from: segment.from,
          to: segment.to,
          price: segment.price,
        ));
        totalPrice += segment.price;
      } else {
        // Connexion virtuelle (changement d'autoroute dans la même ville)
        // Trouver les noms complets d'origine
        final fromRoute = _routes.firstWhere(
          (r) => _getBaseName(r.from) == from || _getBaseName(r.to) == from,
          orElse: () => _routes.first,
        );
        final toRoute = _routes.firstWhere(
          (r) => _getBaseName(r.from) == to || _getBaseName(r.to) == to,
          orElse: () => _routes.first,
        );
        
        final fromName = _getBaseName(fromRoute.from) == from ? fromRoute.from : fromRoute.to;
        final toName = _getBaseName(toRoute.from) == to ? toRoute.from : toRoute.to;
        
        // Ajouter un segment de connexion avec prix 0
        segments.add(RouteSegment(
          from: fromName,
          to: toName,
          price: 0.0,
        ));
        print('   🔄 Connexion locale: $fromName -> $toName (changement d\'autoroute)');
      }
    }
    
    if (segments.isEmpty) return null;
    
    return OptimizedRoute(
      segments: segments,
      totalPrice: totalPrice,
      isDirect: segments.length == 1,
    );
  }

  // Ancienne méthode conservée pour compatibilité (maintenant simplifiée)
  OptimizedRoute? _findOptimalRouteOld(String from, String to) {
    try {
      final fromBase = _getBaseName(from);
      final toBase = _getBaseName(to);

      // 1. Chercher le trajet direct
      final directRoute = findRoute(from, to);
      double? directPrice = directRoute?.price;

      OptimizedRoute? bestRoute;

      // Si trajet direct existe, le considérer comme solution initiale
      if (directPrice != null) {
        bestRoute = OptimizedRoute(
          segments: [
            RouteSegment(from: from, to: to, price: directPrice),
          ],
          totalPrice: directPrice,
          isDirect: true,
        );
      }

      // 2. Optimisation : Récupérer seulement les destinations possibles depuis 'from'
      final possibleFromDest = <String>{};
      for (var route in _routes) {
        if (_getBaseName(route.from) == fromBase && _getBaseName(route.to) != fromBase) {
          possibleFromDest.add(_getBaseName(route.to));
        }
      }

      // 3. Récupérer seulement les origines possibles vers 'to'
      final possibleToOrigin = <String>{};
      for (var route in _routes) {
        if (_getBaseName(route.to) == toBase && _getBaseName(route.from) != toBase) {
          possibleToOrigin.add(_getBaseName(route.from));
        }
      }

      // 4. Les points intermédiaires valides sont l'intersection des deux ensembles
      final validIntermediates = possibleFromDest.intersection(possibleToOrigin);

      // 5. Pour chaque point intermédiaire valide
      for (final intermediateBase in validIntermediates) {
        // Trouver un lieu avec ce nom de base dans _routes
        TollRoute? segment1;
        TollRoute? segment2;

        // Chercher A → Intermédiaire
        for (var route in _routes) {
          if (_getBaseName(route.from) == fromBase && 
              _getBaseName(route.to) == intermediateBase) {
            segment1 = route;
            break;
          }
        }

        if (segment1 == null) continue;

        // Chercher Intermédiaire → B
        for (var route in _routes) {
          if (_getBaseName(route.from) == intermediateBase && 
              _getBaseName(route.to) == toBase) {
            segment2 = route;
            break;
          }
        }

        if (segment2 == null) continue;

        final totalPrice = segment1.price + segment2.price;

        // Si c'est moins cher que le meilleur trouvé jusqu'à présent
        if (bestRoute == null || totalPrice < bestRoute.totalPrice) {
          bestRoute = OptimizedRoute(
            segments: [
              RouteSegment(from: from, to: segment1.to, price: segment1.price),
              RouteSegment(from: segment2.from, to: to, price: segment2.price),
            ],
            totalPrice: totalPrice,
            isDirect: false,
          );
        }
      }

      return bestRoute;
    } catch (e) {
      print('❌ Erreur dans findOptimalRoute: $e');
      // En cas d'erreur, retourner le trajet direct s'il existe
      final directRoute = findRoute(from, to);
      if (directRoute != null) {
        return OptimizedRoute(
          segments: [
            RouteSegment(from: from, to: to, price: directRoute.price),
          ],
          totalPrice: directRoute.price,
          isDirect: true,
        );
      }
      return null;
    }
  }

  // Calculer l'économie réalisée
  double? calculateSavings(String from, String to) {
    final optimal = findOptimalRoute(from, to);
    if (optimal == null) return null;

    final direct = findRoute(from, to);
    if (direct == null || optimal.isDirect) return 0.0;

    return direct.price - optimal.totalPrice;
  }
}
