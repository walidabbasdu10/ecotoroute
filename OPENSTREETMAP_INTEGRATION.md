# Fonctionnalité OpenStreetMap

## Vue d'ensemble

Cette fonctionnalité permet de rechercher et visualiser les péages autoroutiers français en temps réel à partir des données d'OpenStreetMap.

## Caractéristiques

### 1. Récupération des données de péages

Le service `OpenStreetMapService` utilise l'API Overpass d'OpenStreetMap pour récupérer :
- **Coordonnées GPS** (latitude/longitude) de chaque péage
- **Nom du péage**
- **Nom de l'autoroute** (référence : A1, A6, etc.)
- **Exploitant** (si disponible)

### 2. Types de recherche disponibles

#### Recherche par nom
```dart
final osmService = OpenStreetMapService();
final results = await osmService.searchTollGates('Saint-Arnoult');
```

#### Recherche par autoroute
```dart
final results = await osmService.searchTollGatesByHighway('A1');
```

#### Recherche par nom exact avec zone géographique
```dart
final tollGate = await osmService.findTollGateByName(
  'Péage de Montmarault',
  centerLat: 46.3,
  centerLon: 2.9,
  radiusKm: 50,
);
```

### 3. Interface utilisateur

L'écran `TollGateMapScreen` offre :

- **Barre de recherche** : Recherche par nom de péage ou code d'autoroute
- **Carte interactive** : Affichage des péages sur une carte OpenStreetMap
- **Liste des résultats** : Vue en liste avec détails de chaque péage
- **Sélection interactive** : Cliquez sur un péage pour voir ses détails
- **Panneau de détails** : Affiche toutes les informations disponibles

## Modèle de données

### TollGate
```dart
class TollGate {
  final String name;               // Nom du péage
  final double? latitude;          // Coordonnée GPS latitude
  final double? longitude;         // Coordonnée GPS longitude
  final String? highwayName;       // Type de route (motorway, etc.)
  final String? highwayRef;        // Référence autoroute (A1, A6, etc.)
  final String? operator;          // Exploitant (Vinci, APRR, etc.)
  final Map<String, dynamic>? osmData; // Données brutes OSM
}
```

## API Overpass - Requêtes utilisées

### Recherche de péages en France
```overpass
[out:json][timeout:25];
area["ISO3166-1"="FR"][admin_level=2];
(
  node["barrier"="toll_booth"]["name"~"SEARCH_QUERY",i](area);
  node["highway"="toll_gantry"]["name"~"SEARCH_QUERY",i](area);
  way["barrier"="toll_booth"]["name"~"SEARCH_QUERY",i](area);
);
out center 50;
```

### Types d'objets OSM recherchés

1. **toll_booth** : Barrière de péage physique
2. **toll_gantry** : Portique de péage (télépéage)
3. **node** : Point géographique
4. **way** : Chemin/route

## Intégration

### Depuis l'écran d'accueil
Un bouton "Carte des péages OpenStreetMap" a été ajouté dans l'en-tête de l'application :

```dart
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TollGateMapScreen(),
      ),
    );
  },
  icon: const Icon(Icons.map),
  label: const Text('Carte des péages OpenStreetMap'),
)
```

### Avec un terme de recherche initial
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => TollGateMapScreen(
      initialSearchQuery: 'A6',
    ),
  ),
);
```

## Cache

Le service implémente un système de cache pour optimiser les performances :
- Les résultats de recherche sont mis en cache par clé (nom + pays)
- Réduit les appels API répétitifs
- Vider le cache manuellement : `osmService.clearCache()`

## Normalisation des noms

Le service normalise automatiquement les noms pour améliorer les recherches :
- Suppression des codes `/A###`
- Suppression des codes `(##)` au début
- Suppression des `N°###` à la fin

Exemple :
```dart
'(17) St-Gibrien / A131' → 'St-Gibrien'
```

## Exemple d'utilisation complète

```dart
import 'package:ecotoroute/services/openstreetmap_service.dart';

// 1. Créer une instance du service
final osmService = OpenStreetMapService();

// 2. Rechercher tous les péages sur l'A1
final peagesA1 = await osmService.searchTollGatesByHighway('A1');

// 3. Afficher les résultats
for (final peage in peagesA1) {
  print('Péage: ${peage.name}');
  if (peage.hasCoordinates) {
    print('  Position: ${peage.latitude}, ${peage.longitude}');
  }
  if (peage.highwayRef != null) {
    print('  Autoroute: ${peage.highwayRef}');
  }
}

// 4. Rechercher un péage spécifique
final peage = await osmService.findTollGateByName('Péage de Saint-Arnoult');
if (peage != null && peage.hasCoordinates) {
  print('Trouvé à: ${peage.latitude}, ${peage.longitude}');
}
```

## Limitations et considérations

### Limites de l'API Overpass
- **Timeout** : Les requêtes complexes peuvent prendre jusqu'à 25-60 secondes
- **Rate limiting** : L'API Overpass peut limiter les requêtes trop fréquentes
- **Données** : La qualité dépend des contributions OpenStreetMap

### Qualité des données OSM
- Tous les péages ne sont pas nécessairement cartographiés
- Les noms peuvent varier selon les contributeurs
- Les coordonnées peuvent être approximatives

### Recommandations
1. **Utiliser le cache** : Éviter les recherches répétitives
2. **Recherches larges** : Préférer les codes d'autoroute aux noms exacts
3. **Gestion d'erreurs** : Toujours gérer les cas où aucun résultat n'est trouvé
4. **Timeout approprié** : Prévoir des timeouts suffisants pour les requêtes

## Dépendances requises

```yaml
dependencies:
  http: ^1.2.1           # Requêtes HTTP vers API Overpass
  flutter_map: ^7.0.2    # Carte interactive OpenStreetMap
  latlong2: ^0.9.1       # Gestion des coordonnées GPS
```

## Architecture

```
lib/
├── models/
│   └── toll_gate.dart              # Modèle de données péage
├── services/
│   └── openstreetmap_service.dart  # Service API Overpass
└── screens/
    └── toll_gate_map_screen.dart   # Interface utilisateur carte
```

## Future améliorations possibles

1. **Enrichissement des données**
   - Lier les données OSM avec les tarifs de péages existants
   - Afficher le prix directement sur la carte

2. **Calcul d'itinéraire**
   - Intégrer avec l'algorithme d'optimisation existant
   - Visualiser le trajet optimal sur la carte

3. **Filtre avancé**
   - Filtrer par exploitant (Vinci, APRR, etc.)
   - Filtrer par type de péage (barrière, portique)

4. **Mode hors-ligne**
   - Télécharger et sauvegarder les données localement
   - Synchronisation périodique

5. **Contribution OSM**
   - Permettre aux utilisateurs de signaler des péages manquants
   - Interface pour contribuer à OpenStreetMap

## Ressources

- [API Overpass Documentation](https://wiki.openstreetmap.org/wiki/Overpass_API)
- [OpenStreetMap Tags - Toll](https://wiki.openstreetmap.org/wiki/Tag:barrier%3Dtoll_booth)
- [Flutter Map Package](https://pub.dev/packages/flutter_map)
