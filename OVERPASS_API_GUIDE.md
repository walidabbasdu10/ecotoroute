# Guide API Overpass - Console de Test

## Vue d'ensemble

L'**Overpass API** est un service de requête pour OpenStreetMap qui permet d'extraire des données géographiques spécifiques. Cette application inclut maintenant une console de test interactive et un service API avancé.

## Architecture

```
lib/
├── services/
│   ├── overpass_api_service.dart      # Service API avancé
│   └── openstreetmap_service.dart     # Service de recherche de péages
└── screens/
    ├── overpass_api_test_screen.dart  # Console de test interactive
    └── toll_gate_map_screen.dart      # Carte des péages
```

## Fonctionnalités de l'API Service

### 1. Service de base

```dart
final apiService = OverpassApiService();

// Exécuter une requête brute
final result = await apiService.executeQuery('''
[out:json][timeout:25];
area["ISO3166-1"="FR"][admin_level=2];
(
  node["barrier"="toll_booth"](area);
);
out center 50;
''');
```

### 2. Recherche dans une zone géographique (BBox)

```dart
// Rechercher tous les péages dans un rectangle
// Format: minLat, minLon, maxLat, maxLon
final tolls = await apiService.getTollsInBoundingBox(
  48.8, 2.2, 48.9, 2.5,  // Région parisienne
  maxResults: 100,
);

print('Trouvé ${tolls.length} péages');
```

### 3. Recherche autour d'un point

```dart
// Rechercher dans un rayon de 50km autour de Paris
final nearby = await apiService.searchAroundPoint(
  48.8566, // latitude
  2.3522,  // longitude
  50000,   // rayon en mètres
  tagKey: 'barrier',
  tagValue: 'toll_booth',
  maxResults: 50,
);
```

### 4. Query Builder (Constructeur de requêtes)

Le Query Builder permet de construire des requêtes complexes facilement :

```dart
// Exemple 1: Péages en France
final tolls = await apiService
    .createQuery()
    .inCountry('FR')
    .addNode('barrier', 'toll_booth')
    .timeout(30)
    .limit(100)
    .execute();

// Exemple 2: Autoroutes dans une zone
final highways = await apiService
    .createQuery()
    .inBoundingBox(48.0, 2.0, 49.0, 3.0)
    .addWay('highway', 'motorway')
    .addNode('barrier', 'toll_booth')
    .limit(50)
    .execute();

// Exemple 3: Construction et inspection de la requête
final builder = apiService
    .createQuery()
    .inCountry('FR')
    .addNode('amenity', 'fuel');

// Voir la requête générée
print(builder.build());

// Exécuter
final stations = await builder.execute();
```

### 5. Statistiques et analyses

```dart
// Obtenir des statistiques sur les péages
final stats = await apiService.getFrenchTollStatistics();
print('Total de péages: ${stats['total_tolls']}');

// Grouper les péages par autoroute
final highwayTolls = await apiService.getHighwaysWithTolls();
highwayTolls.forEach((highway, tolls) {
  print('$highway: ${tolls.length} péages');
});
```

### 6. Détails d'un élément OSM

```dart
// Récupérer les détails d'un nœud spécifique
final element = await apiService.getElementDetails('node', 123456789);

if (element != null) {
  final tags = element['tags'] as Map<String, dynamic>;
  print('Nom: ${tags['name']}');
  print('Lat: ${element['lat']}, Lon: ${element['lon']}');
}
```

### 7. Gestion des serveurs

L'API supporte plusieurs serveurs Overpass :

```dart
// Serveurs disponibles
print(OverpassApiService.overpassServers);
// [
//   'https://overpass-api.de/api/interpreter',
//   'https://overpass.kumi.systems/api/interpreter',
//   'https://overpass.openstreetmap.ru/api/interpreter',
// ]

// Changer de serveur
apiService.setServer(OverpassApiService.overpassServers[1]);

// Tester la connexion
final isConnected = await apiService.testConnection();
print('Connecté: $isConnected');

// Statut du serveur
final status = await apiService.getServerStatus();
print('Serveur disponible: ${status['available']}');
print('Code HTTP: ${status['status_code']}');
```

## Console de Test Interactive

La console de test (`OverpassApiTestScreen`) offre une interface graphique pour :

### Fonctionnalités

1. **Éditeur de requêtes**
   - Éditeur de code pour écrire des requêtes Overpass QL
   - Coloration syntaxique (police monospace)
   - Possibilité de copier/coller

2. **Exemples rapides**
   - BBox Paris : Recherche dans un rectangle géographique
   - Statistiques : Stats sur les péages français
   - Autour point : Recherche dans un rayon
   - Query Builder : Démonstration du constructeur
   - Autoroutes : Liste des autoroutes et leurs péages

3. **Visualisation des résultats**
   - Affichage JSON formaté
   - Copie rapide dans le presse-papiers
   - Messages d'erreur détaillés

4. **Gestion des serveurs**
   - Changement de serveur en temps réel
   - Statut de disponibilité
   - Test de connexion

### Accès à la console

```dart
// Depuis n'importe où dans l'app
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const OverpassApiTestScreen(),
  ),
);
```

## Langage Overpass QL

### Structure de base

```overpass
[out:json][timeout:25];          // Format de sortie et timeout
area["ISO3166-1"="FR"];          // Zone de recherche (France)
(                                 // Début du groupe d'éléments
  node["barrier"="toll_booth"];  // Recherche de nœuds
  way["highway"="motorway"];     // Recherche de chemins
);                                // Fin du groupe
out center 100;                   // Sortie avec centre, limite 100
```

### Filtres courants

```overpass
// Par zone géographique (bbox)
(48.8, 2.2, 48.9, 2.5)

// Par pays
area["ISO3166-1"="FR"]

// Par région administrative
area["name"="Île-de-France"]

// Autour d'un point
(around:50000, 48.8566, 2.3522)  // 50km autour de Paris

// Par tag
["barrier"="toll_booth"]
["highway"="motorway"]
["amenity"="fuel"]

// Par nom (regex)
["name"~"Saint", i]              // Contient "Saint" (insensible à la casse)
["ref"~"^A[0-9]+$"]              // Commence par A suivi de chiffres
```

### Types de sorties

```overpass
out;          // Sortie simple
out body;     // Avec tous les tags
out center;   // Avec le centre géométrique
out geom;     // Avec la géométrie complète
out count;    // Juste le nombre d'éléments
```

## Exemples pratiques

### Exemple 1: Tous les péages sur l'A1

```dart
final a1Tolls = await apiService.createQuery()
    .inCountry('FR')
    .addNode('barrier', 'toll_booth')
    .execute();

// Filtrer par référence A1
final a1Only = a1Tolls.where((toll) {
  final tags = toll['tags'] as Map<String, dynamic>?;
  return tags?['ref']?.contains('A1') ?? false;
}).toList();
```

### Exemple 2: Stations-service près d'un péage

```dart
// 1. Trouver le péage
final tollGate = await osmService.findTollGateByName('Péage de Saint-Arnoult');

if (tollGate != null && tollGate.hasCoordinates) {
  // 2. Chercher les stations dans un rayon de 5km
  final stations = await apiService.searchAroundPoint(
    tollGate.latitude!,
    tollGate.longitude!,
    5000,
    tagKey: 'amenity',
    tagValue: 'fuel',
  );
  
  print('${stations.length} stations trouvées près du péage');
}
```

### Exemple 3: Carte de chaleur des péages

```dart
// Obtenir tous les péages
final allTolls = await apiService.createQuery()
    .inCountry('FR')
    .addNode('barrier', 'toll_booth')
    .limit(500)
    .execute();

// Grouper par département (en utilisant les coordonnées)
final Map<String, int> tollsByRegion = {};
for (final toll in allTolls) {
  final lat = toll['lat'] as double;
  final lon = toll['lon'] as double;
  final region = _getRegionFromCoords(lat, lon);
  tollsByRegion[region] = (tollsByRegion[region] ?? 0) + 1;
}
```

## Gestion des erreurs

```dart
try {
  final result = await apiService.executeQuery(myQuery);
  // Traiter le résultat
} on OverpassApiException catch (e) {
  if (e.statusCode == 429) {
    // Trop de requêtes - attendre
    print('Rate limit atteint, réessayez dans 1 minute');
  } else if (e.statusCode == 504) {
    // Timeout
    print('Requête trop complexe, essayez de réduire la zone');
  } else {
    print('Erreur API: ${e.message}');
  }
} catch (e) {
  print('Erreur inattendue: $e');
}
```

## Limites et bonnes pratiques

### Limites de l'API Overpass

1. **Timeout** : Maximum 180 secondes (3 minutes)
2. **Mémoire** : Maximum 512 MB par requête
3. **Rate limiting** : 2 requêtes simultanées par IP
4. **Slots** : Attendre que les slots soient libérés entre requêtes

### Bonnes pratiques

```dart
// ✅ BON : Requête ciblée
final query = apiService.createQuery()
    .inBoundingBox(48.8, 2.2, 48.9, 2.5)  // Zone restreinte
    .addNode('barrier', 'toll_booth')
    .limit(50);

// ❌ MAUVAIS : Requête trop large
final badQuery = apiService.createQuery()
    .inCountry('FR')  // Tout le pays
    .addNode('highway')  // Tous les types de routes
    .limit(10000);  // Limite trop élevée
```

### Optimisation

1. **Utiliser le cache**
```dart
// Les résultats sont automatiquement mis en cache
final tolls1 = await apiService.searchTollGates('Saint-Arnoult');
final tolls2 = await apiService.searchTollGates('Saint-Arnoult'); // Depuis le cache

// Vider le cache si nécessaire
apiService.clearCache();
```

2. **Limiter les résultats**
```dart
// Toujours spécifier une limite raisonnable
.limit(100)  // Au lieu de 10000
```

3. **Zones géographiques précises**
```dart
// Préférer bbox à country pour des zones restreintes
.inBoundingBox(48.8, 2.2, 48.9, 2.5)  // Mieux que
.inCountry('FR')
```

## Ressources

### Documentation

- [Overpass API Documentation](https://wiki.openstreetmap.org/wiki/Overpass_API)
- [Overpass Turbo](https://overpass-turbo.eu/) - Testeur en ligne
- [OpenStreetMap Tags](https://wiki.openstreetmap.org/wiki/Map_Features)
- [Overpass QL Language Guide](https://wiki.openstreetmap.org/wiki/Overpass_API/Language_Guide)

### Outils de développement

- **Overpass Turbo** : https://overpass-turbo.eu/
  - Interface web pour tester les requêtes
  - Visualisation sur carte
  - Export des résultats

- **Overpass API Status** : https://overpass-api.de/api/status
  - Statut en temps réel
  - Slots disponibles
  - Load du serveur

### Tags OSM pour les péages

| Tag | Valeur | Description |
|-----|--------|-------------|
| `barrier` | `toll_booth` | Barrière de péage physique |
| `highway` | `toll_gantry` | Portique de télépéage |
| `fee` | `yes` | Route payante |
| `toll` | `yes` | Péage présent |
| `payment:electronic_toll_collection` | `yes` | Télépéage disponible |

## Exemples de requêtes utiles

### Tous les péages avec leurs exploitants

```overpass
[out:json][timeout:25];
area["ISO3166-1"="FR"][admin_level=2];
(
  node["barrier"="toll_booth"]["operator"](area);
);
out body;
```

### Autoroutes avec distance totale

```overpass
[out:json][timeout:30];
area["ISO3166-1"="FR"][admin_level=2];
(
  way["highway"="motorway"]["ref"~"^A[0-9]+$"](area);
);
out geom;
```

### Péages ouverts 24/7

```overpass
[out:json][timeout:25];
area["ISO3166-1"="FR"][admin_level=2];
(
  node["barrier"="toll_booth"]["opening_hours"="24/7"](area);
);
out center;
```

## Intégration dans l'application

L'API Overpass est maintenant intégrée à trois niveaux :

1. **Recherche de péages** (`OpenStreetMapService`) : Recherche simple et rapide
2. **API avancée** (`OverpassApiService`) : Requêtes complexes et personnalisées
3. **Console de test** (`OverpassApiTestScreen`) : Interface de développement

```dart
// Niveau 1 : Recherche simple
final osmService = OpenStreetMapService();
final tolls = await osmService.searchTollGates('Saint-Arnoult');

// Niveau 2 : API avancée
final apiService = OverpassApiService();
final result = await apiService.getTollsInBoundingBox(48.8, 2.2, 48.9, 2.5);

// Niveau 3 : Console interactive
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const OverpassApiTestScreen()),
);
```
