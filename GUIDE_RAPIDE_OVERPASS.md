# Guide Rapide : Utilisation de l'API Overpass

## 🚀 Démarrage rapide

### Importer le service

```dart
import 'package:ecotoroute/services/overpass_api_service.dart';
```

### Créer une instance

```dart
final apiService = OverpassApiService();
```

---

## 📚 Cas d'usage courants

### 1️⃣ Recherche simple avec Query Builder

**Le plus simple pour commencer !**

```dart
// Chercher 10 péages en France
final peages = await apiService
    .createQuery()
    .inCountry('FR')                    // Dans toute la France
    .addNode('barrier', 'toll_booth')   // Type: péage
    .limit(10)                          // Maximum 10 résultats
    .execute();

// Afficher les résultats
for (final peage in peages) {
  final tags = peage['tags'] as Map<String, dynamic>? ?? {};
  print(tags['name']); // Nom du péage
}
```

### 2️⃣ Recherche dans une zone géographique

**Pour chercher dans une région spécifique**

```dart
// Chercher autour de Paris
final peages = await apiService.getTollsInBoundingBox(
  48.5,  // Sud (min latitude)
  1.8,   // Ouest (min longitude)
  49.2,  // Nord (max latitude)
  3.0,   // Est (max longitude)
  maxResults: 50,
);

print('Trouvé ${peages.length} péages en Île-de-France');
```

**Astuce :** Utilisez [BoundingBox](http://bboxfinder.com/) pour trouver les coordonnées de votre zone.

### 3️⃣ Recherche autour d'un point

**Pour trouver les péages près d'une ville**

```dart
// Péages dans un rayon de 50km autour de Paris
final parisLat = 48.8566;
final parisLon = 2.3522;

final peages = await apiService.searchAroundPoint(
  parisLat,
  parisLon,
  50000,  // 50km = 50000 mètres
  tagKey: 'barrier',
  tagValue: 'toll_booth',
  maxResults: 30,
);

print('${peages.length} péages trouvés');
```

### 4️⃣ Trouver tous les péages d'une autoroute

**Pour lister les péages d'une autoroute spécifique**

```dart
// Tous les péages de l'A1
final elementsA1 = await apiService.getElementsWithTag(
  'ref',      // Clé du tag
  'A1',       // Valeur du tag
  country: 'FR',
  maxResults: 100,
);

// Filtrer uniquement les péages
final peages = elementsA1.where((element) {
  final tags = element['tags'] as Map<String, dynamic>? ?? {};
  return tags['barrier'] == 'toll_booth';
}).toList();

print('${peages.length} péages sur l\'A1');
```

### 5️⃣ Exécuter une requête personnalisée

**Pour les requêtes avancées en Overpass QL**

```dart
final query = '''
[out:json][timeout:25];
area["ISO3166-1"="FR"][admin_level=2];
(
  node["barrier"="toll_booth"]["name"~"Saint",i](area);
);
out center 20;
''';

final result = await apiService.executeQuery(query);
final elements = result['elements'] as List<dynamic>;

print('${elements.length} péages trouvés avec "Saint" dans le nom');
```

---

## 🔧 Fonctionnalités avancées

### Query Builder complet

**Construire des requêtes complexes étape par étape**

```dart
final builder = apiService
    .createQuery()
    .inCountry('FR')                      // Zone: France
    .addNode('barrier', 'toll_booth')     // Ajouter des nodes
    .addWay('barrier', 'toll_booth')      // Ajouter des ways
    .timeout(30)                          // Timeout 30 sec
    .limit(100);                          // Max 100 résultats

// Voir la requête générée
print(builder.build());

// Exécuter
final results = await builder.execute();
```

### Changer de serveur Overpass

**Si un serveur est lent ou indisponible**

```dart
// Voir les serveurs disponibles
print(OverpassApiService.overpassServers);

// Changer de serveur
apiService.setServer(OverpassApiService.overpassServers[1]);

// Tester la connexion
final isOk = await apiService.testConnection();
print('Serveur OK: $isOk');
```

### Obtenir le statut du serveur

```dart
final status = await apiService.getServerStatus();

print('Disponible: ${status['available']}');
print('Code HTTP: ${status['status_code']}');
```

### Statistiques sur les péages

```dart
final stats = await apiService.getFrenchTollStatistics();

print('Total péages: ${stats['total_tolls']}');
print('Date: ${stats['query_timestamp']}');
```

---

## ⚡ Intégration avec votre code existant

### Utiliser avec OpenStreetMapService

```dart
final osmService = OpenStreetMapService();
final apiService = OverpassApiService();

// 1. Trouver un péage avec OSM
final peages = await osmService.searchTollGates('Saint-Arnoult');

if (peages.isNotEmpty && peages.first.hasCoordinates) {
  final peage = peages.first;
  
  // 2. Chercher autour avec l'API avancée
  final autour = await apiService.searchAroundPoint(
    peage.latitude!,
    peage.longitude!,
    10000,  // 10km
  );
  
  print('${autour.length} éléments trouvés autour de ${peage.name}');
}
```

### Enrichir vos données de trajets

```dart
// Dans votre TollDataService
Future<void> enrichirAvecCoordonnees(String location) async {
  final apiService = OverpassApiService();
  
  // Chercher le péage
  final results = await apiService
      .createQuery()
      .inCountry('FR')
      .addNode('barrier', 'toll_booth')
      .limit(100)
      .execute();
  
  // Filtrer par nom
  final match = results.firstWhere(
    (r) {
      final tags = r['tags'] as Map<String, dynamic>? ?? {};
      return tags['name']?.contains(location) ?? false;
    },
    orElse: () => {},
  );
  
  if (match.isNotEmpty) {
    print('Trouvé: ${match['lat']}, ${match['lon']}');
  }
}
```

---

## 🎯 Cas d'usage pratiques pour Ecotoroute

### 1. Afficher les péages sur une carte

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MaCarte extends StatelessWidget {
  Future<List<Marker>> _chargerPeages() async {
    final apiService = OverpassApiService();
    
    final peages = await apiService
        .createQuery()
        .inBoundingBox(48.0, 2.0, 49.0, 3.0)
        .addNode('barrier', 'toll_booth')
        .limit(50)
        .execute();
    
    return peages.map((peage) {
      return Marker(
        point: LatLng(peage['lat'], peage['lon']),
        width: 30,
        height: 30,
        child: Icon(Icons.toll, color: Colors.red),
      );
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Marker>>(
      future: _chargerPeages(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        
        return FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(48.5, 2.5),
            initialZoom: 8,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
            MarkerLayer(markers: snapshot.data!),
          ],
        );
      },
    );
  }
}
```

### 2. Calculer le nombre de péages sur un trajet

```dart
Future<int> compterPeagesSurTrajet(
  double latDepart,
  double lonDepart,
  double latArrivee,
  double lonArrivee,
) async {
  final apiService = OverpassApiService();
  
  // Créer une bbox qui englobe le trajet
  final minLat = [latDepart, latArrivee].reduce((a, b) => a < b ? a : b);
  final maxLat = [latDepart, latArrivee].reduce((a, b) => a > b ? a : b);
  final minLon = [lonDepart, lonArrivee].reduce((a, b) => a < b ? a : b);
  final maxLon = [lonDepart, lonArrivee].reduce((a, b) => a > b ? a : b);
  
  // Ajouter une marge de 0.2 degrés
  final peages = await apiService.getTollsInBoundingBox(
    minLat - 0.2,
    minLon - 0.2,
    maxLat + 0.2,
    maxLon + 0.2,
  );
  
  return peages.length;
}
```

### 3. Créer une alerte de proximité

```dart
Future<List<String>> obtenirPeagesProches(
  double latitude,
  double longitude,
  {double rayonKm = 10}
) async {
  final apiService = OverpassApiService();
  
  final peages = await apiService.searchAroundPoint(
    latitude,
    longitude,
    rayonKm * 1000,  // Convertir km en mètres
    tagKey: 'barrier',
    tagValue: 'toll_booth',
  );
  
  return peages.map((p) {
    final tags = p['tags'] as Map<String, dynamic>? ?? {};
    return tags['name'] as String? ?? 'Péage sans nom';
  }).toList();
}

// Utilisation
final peagesProches = await obtenirPeagesProches(48.8566, 2.3522, rayonKm: 5);
if (peagesProches.isNotEmpty) {
  print('⚠️ Péage à proximité: ${peagesProches.first}');
}
```

---

## 🛡️ Gestion des erreurs

```dart
try {
  final peages = await apiService
      .createQuery()
      .inCountry('FR')
      .addNode('barrier', 'toll_booth')
      .execute();
      
  print('Succès: ${peages.length} résultats');
  
} on OverpassApiException catch (e) {
  // Erreur spécifique à Overpass
  print('Erreur Overpass: ${e.message}');
  
  if (e.statusCode == 429) {
    print('Trop de requêtes. Attendez 1 minute.');
  } else if (e.statusCode == 504) {
    print('Timeout. Simplifiez votre requête.');
  }
  
} catch (e) {
  // Autres erreurs
  print('Erreur: $e');
}
```

---

## 💡 Bonnes pratiques

### ✅ À FAIRE

```dart
// ✅ Limiter les résultats
.limit(50)

// ✅ Utiliser des zones restreintes
.inBoundingBox(48.8, 2.2, 48.9, 2.5)

// ✅ Mettre en cache
final cache = <String, List<dynamic>>{};
if (cache.containsKey('peages_paris')) {
  return cache['peages_paris']!;
}

// ✅ Timeout raisonnable
.timeout(30)  // 30 secondes max

// ✅ Gérer les erreurs
try { ... } catch (e) { ... }
```

### ❌ À ÉVITER

```dart
// ❌ Trop de résultats
.limit(10000)  // Trop !

// ❌ Zone trop grande
.inCountry('FR')  // Pour tout le pays!
// Préférez: .inBoundingBox(...)

// ❌ Pas de timeout
// Le serveur peut mettre longtemps

// ❌ Requêtes successives rapides
await query1();
await query2();  // Trop rapide!
// Ajoutez: await Future.delayed(Duration(seconds: 2));
```

---

## 🔍 Debugging

### Voir la requête générée

```dart
final builder = apiService.createQuery()
    .inCountry('FR')
    .addNode('barrier', 'toll_booth');

// Afficher la requête avant de l'exécuter
print(builder.build());
```

### Tester dans Overpass Turbo

1. Allez sur https://overpass-turbo.eu/
2. Copiez votre requête
3. Cliquez sur "Exécuter"
4. Visualisez les résultats sur la carte

---

## 📖 Aller plus loin

### Documentation complète
- Voir [OVERPASS_API_GUIDE.md](../OVERPASS_API_GUIDE.md)
- Voir [overpass_api_examples.dart](../lib/examples/overpass_api_examples.dart)

### Ressources externes
- [Overpass API Documentation](https://wiki.openstreetmap.org/wiki/Overpass_API)
- [Overpass Turbo](https://overpass-turbo.eu/) - Testeur en ligne
- [OpenStreetMap Tags](https://wiki.openstreetmap.org/wiki/Map_Features)

### Console de test intégrée

Accédez à la console de test dans votre app :
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => OverpassApiTestScreen(),
  ),
);
```

---

## 🎓 Exemple complet minimal

```dart
import 'package:ecotoroute/services/overpass_api_service.dart';

Future<void> main() async {
  // 1. Créer le service
  final api = OverpassApiService();
  
  // 2. Chercher des péages
  final peages = await api
      .createQuery()
      .inCountry('FR')
      .addNode('barrier', 'toll_booth')
      .limit(10)
      .execute();
  
  // 3. Afficher les résultats
  print('Trouvé ${peages.length} péages:');
  for (final peage in peages) {
    final tags = peage['tags'] as Map<String, dynamic>? ?? {};
    final nom = tags['name'] ?? 'Sans nom';
    final lat = peage['lat'];
    final lon = peage['lon'];
    print('  • $nom ($lat, $lon)');
  }
}
```

**C'est tout !** Vous êtes prêt à utiliser l'API Overpass dans votre application. 🚀
