# Ecotoroute 🚗🛣️

Application Flutter multiplateforme pour calculer les coûts de péages autoroutiers en France (tarifs 2026).

## ✨ Fonctionnalités

- **🎨 Interface moderne** : Design élégant avec gradient bleu style navigation
- **📍 43,141 trajets** : Base de données complète des autoroutes françaises 2026
- **🔍 696 points de péage** : Couverture exhaustive du réseau autoroutier
- **🎯 Filtrage intelligent** : Les destinations s'adaptent automatiquement au point de départ
- **⚡ Recherche rapide** : Trouvez instantanément votre lieu parmi des centaines de sorties
- **💰 Calcul instantané** : Coût du péage pour véhicules légers en temps réel
- **🔄 Échange de points** : Inversez facilement départ et arrivée
- **🌐 Multiplateforme** : Windows, Android, Web, iOS, Linux, macOS

## 📊 Données

- **Source** : Tarifs autoroutes 2026 (toutes les autoroutes françaises)
- **Trajets** : 43,141 itinéraires directs
- **Points de péage** : 696 sorties uniques
- **Normalisation** : Gestion intelligente des variations de noms (N°, codes /A###, formats différents)

## 🗂️ Structure du projet

```
lib/
├── main.dart                           # Point d'entrée avec diagnostics
├── models/
│   └── toll_route.dart                 # Modèle de données des trajets
├── services/
│   └── toll_data_service.dart          # Service de gestion et normalisation des données
├── screens/
│   ├── home_screen.dart                # Écran principal avec sélection départ/arrivée
│   └── location_selection_screen.dart  # Écran de sélection avec recherche filtrée
└── debug/
    └── test_data.dart                  # Outils de diagnostic des données

assets/
├── toll_data_full.json                 # Base complète (43,141 trajets - 3.07 MB)
├── locations_clean.json                # Lieux normalisés (696 points)
├── toll_data_sample.json               # Échantillon pour tests (873 trajets)
└── locations_full.json                 # Liste brute originale
```

## 🚀 Installation

1. Assurez-vous d'avoir Flutter 3.9.0+ installé
2. Clonez le projet
3. Installez les dépendances :
   ```bash
   flutter pub get
   ```

## ▶️ Lancer l'application

```bash
# Cloner le projet
git clone https://github.com/VOTRE-USERNAME/ecotoroute.git
cd ecotoroute

# Installer les dépendances
flutter pub get

# Windows
flutter run -d windows

# Android
flutter run -d android

# Web
flutter run -d chrome

# iOS (macOS requis)
flutter run -d ios
```

## 🔧 Technologies utilisées

- **Flutter 3.9.0+** : Framework UI multiplateforme
- **Dart** : Langage de programmation
- **google_fonts** : Police Poppins
- **Material Design 3** : Design system moderne

## 🎨 Design

- **Palette** : Gradient bleu (#1976D2 → #64B5F6)
- **Typographie** : Poppins (Google Fonts)
- **Interface** : Cartes de sélection style navigation
- **Animations** : Transitions fluides

## 📝 Utilisation

1. **Sélectionnez le point de départ** : Cliquez sur la carte "Départ"
2. **Recherchez votre lieu** : Tapez dans la barre de recherche (ex: "Paris", "Lyon")
3. **Sélectionnez le point d'arrivée** : La liste se filtre automatiquement selon le départ choisi
4. **Consultez le tarif** : Le coût s'affiche instantanément

## 🛠️ Corrections techniques

L'application intègre plusieurs couches de normalisation pour garantir la cohérence des données :

### Normalisation des noms de lieux
La fonction `_getBaseName()` gère 5 types de variations :
1. Codes autoroutiers : `/A131` → supprimé
2. Numéros de sortie : `(17)` → supprimé
3. Numéros de péage : `N°5` → supprimé
4. Casse : `St-Gibrien` → `ST GIBRIEN`
5. Tirets : `Saint-Romain` → `SAINT ROMAIN`

### Résolution des bugs
- ✅ Filtrage intelligent des destinations selon le départ
- ✅ Gestion des formats incohérents entre UI et données
- ✅ Élimination des doublons via Set
- ✅ Validation avec 43,141 trajets en production

Documentation détaillée dans `CORRECTION_NORMALISATION.md`

## 📄 Licence

Ce projet est un outil de calcul basé sur les tarifs publics des autoroutes françaises 2026.

## 👤 Auteur

Développé avec Flutter 💙

---

**Note** : Les tarifs affichés sont basés sur les données 2026 et concernent uniquement les véhicules légers (classe 1).
4. **Consultez le tarif** : Le coût s'affiche automatiquement

## 🔄 Prochaines étapes

- [ ] Charger toutes les données (43 754 trajets)
- [ ] Ajouter le calcul pour différents types de véhicules
- [ ] Implémenter un système de recherche d'itinéraire multi-étapes
- [ ] Ajouter une carte interactive
- [ ] Historique des recherches
- [ ] Mode hors ligne

## 📄 Licence

Ce projet utilise les données officielles des tarifs autoroutiers 2026.
