# Ecotoroute 🚗

Application Flutter pour calculer les coûts de péages autoroutiers en France (2026).

## 📱 Fonctionnalités

- **Interface intuitive** : Design moderne avec style navigation
- **Recherche de lieux** : Trouvez facilement votre point de départ et d'arrivée parmi 199 sorties d'autoroutes
- **Calcul de péage** : Obtenez instantanément le coût du trajet pour véhicule léger
- **Échange de points** : Inversez facilement le départ et l'arrivée

## 🗂️ Structure du projet

```
lib/
├── main.dart                           # Point d'entrée de l'application
├── models/
│   └── toll_route.dart                 # Modèle de données pour les trajets
├── services/
│   └── toll_data_service.dart          # Service de gestion des données
└── screens/
    ├── home_screen.dart                # Écran principal
    └── location_selection_screen.dart  # Écran de sélection de lieu

assets/
├── toll_data_sample.json               # Données d'échantillon (873 trajets)
└── locations.json                      # Liste des lieux (199 sorties)
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
# Android/iOS
flutter run

# Web
flutter run -d chrome

# Windows
flutter run -d windows
```

## 📊 Données

L'application utilise actuellement un échantillon de données des tarifs autoroutiers 2026 :
- **873 trajets** couvrant 199 sorties d'autoroutes
- Source : Tarifs officiels autoroutes 2026

### Charger toutes les données

Pour utiliser la totalité des 43 754 trajets, vous pouvez exporter l'intégralité du fichier Excel vers JSON :

```powershell
# Script PowerShell pour exporter toutes les données
# (Voir le script complet dans les commentaires du code)
```

Puis modifiez `toll_data_service.dart` pour charger `toll_data.json` au lieu de `toll_data_sample.json`.

## 🎨 Design

- **Couleurs principales** : Bleu (#1976D2)
- **Typographie** : Google Fonts (Poppins)
- **Style** : Material Design 3 avec gradients modernes
- **Interface** : Style navigation avec cartes de sélection

## 🔧 Technologies utilisées

- **Flutter** : Framework UI multiplateforme
- **Dart** : Langage de programmation
- **google_fonts** : Polices personnalisées

## 📝 Utilisation

1. **Sélectionnez le point de départ** : Cliquez sur la carte "Départ"
2. **Recherchez votre lieu** : Utilisez la barre de recherche
3. **Sélectionnez le point d'arrivée** : Cliquez sur la carte "Arrivée"
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
