# 🎯 Guide Complet : Utilisation de l'API Overpass dans Ecotoroute

## 📋 Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Démarrage rapide](#démarrage-rapide)
3. [Interfaces disponibles](#interfaces-disponibles)
4. [Exemples de code](#exemples-de-code)
5. [Documentation](#documentation)

---

## 🎨 Vue d'ensemble

Votre application **Ecotoroute** intègre maintenant l'**API Overpass** d'OpenStreetMap pour récupérer en temps réel :

- ✅ **Coordonnées GPS** des péages (latitude/longitude)
- ✅ **Noms des péages** (officiels depuis OSM)
- ✅ **Noms des autoroutes** (A1, A6, A10, etc.)
- ✅ **Informations détaillées** (exploitant, type, etc.)

---

## 🚀 Démarrage rapide

### 1. Accès rapide depuis l'application

Lancez votre app et vous verrez 3 nouveaux boutons sur l'écran d'accueil :

```
┌─────────────────────────────────────────┐
│  🗺️  Carte OSM     |   💻 API Test      │
├─────────────────────────────────────────┤
│    🚀 Démo API Overpass (Tests rapides) │
└─────────────────────────────────────────┘
```

- **Carte OSM** : Recherchez et visualisez les péages sur une carte
- **API Test** : Console avancée pour développeurs
- **Démo API** : 5 tests préfabriqués pour découvrir l'API ⭐

### 2. Utilisation dans votre code

```dart
// Importer le service
import 'package:ecotoroute/services/overpass_api_service.dart';

// Créer une instance
final api = OverpassApiService();

// Rechercher des péages
final peages = await api
    .createQuery()
    .inCountry('FR')
    .addNode('barrier', 'toll_booth')
    .limit(10)
    .execute();

// Afficher les résultats
for (final peage in peages) {
  final tags = peage['tags'] as Map<String, dynamic>? ?? {};
  print(tags['name']); // Nom du péage
}
```

---

## 🎮 Interfaces disponibles

### 1️⃣ Démo Overpass (Recommandé pour commencer)

**Écran :** `DemoOverpassScreen`

**5 tests intégrés :**

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const DemoOverpassScreen(),
  ),
);
```

**Tests disponibles :**

| Test | Description | Ce qu'il montre |
|------|-------------|-----------------|
| 1. Query Builder | Recherche simple de 5 péages | Usage de base du Query Builder |
| 2. Autour de Paris | Péages dans 30km autour de Paris | Recherche par rayon |
| 3. BBox IDF | Péages en Île-de-France | Recherche par zone géographique |
| 4. Statut serveur | Info sur le serveur Overpass | Test de connexion |
| 5. Voir requête | Affiche la requête générée | Debug et compréhension |

**Utilisation :**
1. Lancez l'app
2. Cliquez sur "🚀 Démo API Overpass"
3. Cliquez sur un bouton de test
4. Observez les résultats en temps réel

### 2️⃣ Carte interactive OSM

**Écran :** `TollGateMapScreen`

**Fonctionnalités :**
- Recherche de péages par nom
- Recherche par autoroute (ex: A1)
- Affichage sur carte interactive
- Détails complets de chaque péage

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const TollGateMapScreen(),
  ),
);
```

### 3️⃣ Console API avancée

**Écran :** `OverpassApiTestScreen`

**Pour développeurs :**
- Éditeur de requêtes Overpass QL
- Exemples de requêtes
- Changement de serveur
- Export JSON des résultats

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const OverpassApiTestScreen(),
  ),
);
```

---

## 💻 Exemples de code

### Exemple 1 : Recherche simple

```dart
import 'package:ecotoroute/services/overpass_api_service.dart';

Future<void> rechercherPeages() async {
  final api = OverpassApiService();
  
  final peages = await api
      .createQuery()
      .inCountry('FR')
      .addNode('barrier', 'toll_booth')
      .limit(10)
      .execute();
  
  print('Trouvé ${peages.length} péages');
}
```

### Exemple 2 : Recherche autour d'un point

```dart
Future<void> peagesAutourDeParis() async {
  final api = OverpassApiService();
  
  final peages = await api.searchAroundPoint(
    48.8566, // Latitude Paris
    2.3522,  // Longitude Paris
    50000,   // 50km de rayon
    tagKey: 'barrier',
    tagValue: 'toll_booth',
  );
  
  print('${peages.length} péages dans un rayon de 50km');
}
```

### Exemple 3 : Recherche dans une zone

```dart
Future<void> peagesIleDeFrance() async {
  final api = OverpassApiService();
  
  // Bounding box de l'Île-de-France
  final peages = await api.getTollsInBoundingBox(
    48.5, // Min latitude
    1.8,  // Min longitude
    49.2, // Max latitude
    3.0,  // Max longitude
  );
  
  print('${peages.length} péages en IDF');
}
```

### Exemple 4 : Intégration avec votre service existant

```dart
import 'package:ecotoroute/services/openstreetmap_service.dart';
import 'package:ecotoroute/services/overpass_api_service.dart';

Future<void> enrichirDonnees(String nomLieu) async {
  final osmService = OpenStreetMapService();
  final apiService = OverpassApiService();
  
  // 1. Chercher le lieu
  final peages = await osmService.searchTollGates(nomLieu);
  
  if (peages.isNotEmpty && peages.first.hasCoordinates) {
    final peage = peages.first;
    
    // 2. Chercher autour
    final autour = await apiService.searchAroundPoint(
      peage.latitude!,
      peage.longitude!,
      10000, // 10km
    );
    
    print('Trouvé ${autour.length} éléments autour de ${peage.name}');
  }
}
```

### Exemple 5 : Afficher sur une carte Flutter

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MaCartePerso extends StatelessWidget {
  Future<List<Marker>> _chargerMarkers() async {
    final api = OverpassApiService();
    
    final peages = await api
        .createQuery()
        .inBoundingBox(48.0, 2.0, 49.0, 3.0)
        .addNode('barrier', 'toll_booth')
        .execute();
    
    return peages.map((p) {
      return Marker(
        point: LatLng(p['lat'], p['lon']),
        width: 30,
        height: 30,
        child: Icon(Icons.toll, color: Colors.red),
      );
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Marker>>(
      future: _chargerMarkers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        
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

---

## 📚 Documentation

### Fichiers créés

Votre projet contient maintenant :

#### 📄 Modèles
- `lib/models/toll_gate.dart` - Modèle de données péage

#### 🔧 Services
- `lib/services/openstreetmap_service.dart` - Service de recherche simple
- `lib/services/overpass_api_service.dart` - API avancée avec Query Builder ⭐

#### 🖥️ Interfaces
- `lib/screens/toll_gate_map_screen.dart` - Carte interactive
- `lib/screens/overpass_api_test_screen.dart` - Console développeur
- `lib/screens/demo_overpass_screen.dart` - Démo avec tests ⭐

#### 📖 Documentation
- `OPENSTREETMAP_INTEGRATION.md` - Guide d'intégration OSM complet
- `OVERPASS_API_GUIDE.md` - Guide détaillé de l'API Overpass
- `GUIDE_RAPIDE_OVERPASS.md` - Guide de démarrage rapide ⭐
- `README_UTILISATION_API.md` - Ce fichier ⭐

#### 🧪 Exemples
- `lib/examples/overpass_api_examples.dart` - 10 exemples pratiques ⭐

---

## 🎯 Cas d'usage recommandés

### Pour débuter

1. **Lancez la démo** → Bouton "🚀 Démo API Overpass"
2. **Testez les 5 exemples** un par un
3. **Lisez** `GUIDE_RAPIDE_OVERPASS.md`

### Pour développer

1. **Consultez** `lib/examples/overpass_api_examples.dart`
2. **Copiez** un exemple proche de votre besoin
3. **Adaptez** à votre code

### Pour approfondir

1. **Lisez** `OVERPASS_API_GUIDE.md`
2. **Utilisez** la console API Test
3. **Testez** sur https://overpass-turbo.eu/

---

## 🛠️ API Principale

### OverpassApiService

```dart
final api = OverpassApiService();
```

#### Méthodes principales

| Méthode | Description | Usage |
|---------|-------------|-------|
| `createQuery()` | Query Builder | Recommandé ⭐ |
| `executeQuery(String query)` | Exécuter requête brute | Avancé |
| `getTollsInBoundingBox()` | Recherche par zone | Courant |
| `searchAroundPoint()` | Recherche par rayon | Courant |
| `getElementsWithTag()` | Recherche par tag | Spécifique |
| `getFrenchTollStatistics()` | Statistiques | Info |
| `testConnection()` | Test serveur | Debug |
| `getServerStatus()` | Statut serveur | Debug |

#### Query Builder

```dart
final builder = api.createQuery();

// Méthodes du builder
builder.inCountry('FR');              // Zone: pays
builder.inBoundingBox(48, 2, 49, 3);  // Zone: bbox
builder.addNode('key', 'value');      // Ajouter node
builder.addWay('key', 'value');       // Ajouter way
builder.timeout(30);                  // Timeout (sec)
builder.limit(100);                   // Limite résultats

// Exécution
final results = await builder.execute();

// Ou juste voir la requête
final queryString = builder.build();
```

---

## ⚠️ Points importants

### Limites de l'API

- **Timeout** : Maximum 180 secondes
- **Rate limiting** : 2 requêtes simultanées max
- **Taille résultats** : Limiter à 500 éléments max

### Bonnes pratiques

```dart
// ✅ BON
.limit(100)                                    // Limite raisonnable
.inBoundingBox(48.5, 1.8, 49.2, 3.0)          // Zone restreinte
await Future.delayed(Duration(seconds: 2));    // Pause entre requêtes

// ❌ À ÉVITER
.limit(10000)                                  // Trop !
.inCountry('FR')  // sur requête complexe     // Trop large
// Requêtes successives sans pause             // Rate limit
```

### Gestion d'erreurs

```dart
try {
  final result = await api.createQuery()...execute();
} on OverpassApiException catch (e) {
  if (e.statusCode == 429) {
    print('Trop de requêtes - Attendez');
  } else if (e.statusCode == 504) {
    print('Timeout - Simplifiez la requête');
  }
} catch (e) {
  print('Erreur: $e');
}
```

---

## 🎓 Apprentissage progressif

### Niveau 1 : Découverte (30 min)

1. Lancez la démo → Testez les 5 boutons
2. Lisez `GUIDE_RAPIDE_OVERPASS.md`
3. Essayez l'exemple 1 dans votre code

### Niveau 2 : Pratique (1-2h)

1. Consultez `lib/examples/overpass_api_examples.dart`
2. Testez 3-4 exemples
3. Adaptez un exemple à votre besoin

### Niveau 3 : Maîtrise (2-4h)

1. Lisez `OVERPASS_API_GUIDE.md`
2. Utilisez la console API Test
3. Créez vos propres requêtes

### Niveau 4 : Expert

1. Testez sur https://overpass-turbo.eu/
2. Lisez la doc officielle Overpass
3. Contribuez à OpenStreetMap !

---

## 🔗 Ressources

### Documentation officielle

- [Overpass API](https://wiki.openstreetmap.org/wiki/Overpass_API)
- [Overpass Turbo](https://overpass-turbo.eu/)
- [OpenStreetMap Tags](https://wiki.openstreetmap.org/wiki/Map_Features)

### Dans votre projet

- 📖 Guide complet : `OVERPASS_API_GUIDE.md`
- 🚀 Guide rapide : `GUIDE_RAPIDE_OVERPASS.md`
- 🧪 Exemples : `lib/examples/overpass_api_examples.dart`

### Support

- Issues GitHub : https://github.com/walidabbasdu10/ecotoroute/issues
- Documentation OpenStreetMap : https://wiki.openstreetmap.org/

---

## ✅ Checklist de démarrage

- [ ] J'ai lancé la démo (bouton 🚀)
- [ ] J'ai testé les 5 exemples
- [ ] J'ai lu le guide rapide
- [ ] J'ai essayé un exemple de code
- [ ] Je comprends le Query Builder
- [ ] Je sais gérer les erreurs
- [ ] Je connais les limites de l'API

---

## 🎉 Vous êtes prêt !

Vous avez maintenant tous les outils pour utiliser l'API Overpass dans votre application Ecotoroute. Commencez par la **démo** et progressez à votre rythme !

**Bon développement ! 🚀**
