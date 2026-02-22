import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/toll_route.dart';

class TollDataService {
  static final TollDataService _instance = TollDataService._internal();
  factory TollDataService() => _instance;
  TollDataService._internal();

  List<TollRoute> _routes = [];
  List<String> _locations = [];
  bool _isLoaded = false;

  Future<void> loadData() async {
    if (_isLoaded) return;

    try {
      // Charger les données de trajets
      final routesData = await rootBundle.loadString('assets/toll_data_full.json');
      final List<dynamic> routesJson = json.decode(routesData);
      _routes = routesJson.map((json) => TollRoute.fromJson(json)).toList();

      // Charger la liste des lieux (nettoyée, sans codes A###)
      final locationsData = await rootBundle.loadString('assets/locations_clean.json');
      final List<dynamic> locationsJson = json.decode(locationsData);
      _locations = locationsJson.cast<String>().toList();
      _locations.sort();

      _isLoaded = true;
    } catch (e) {
      throw Exception('Erreur lors du chargement des données: $e');
    }
  }

  List<String> get locations => _locations;

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
}
