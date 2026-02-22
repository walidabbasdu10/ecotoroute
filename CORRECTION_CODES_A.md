# Correction du problème de filtrage des destinations

## Problème identifié

**Symptôme** : La liste des destinations ne s'adaptait pas selon le point de départ sélectionné.

**Cause racine** : Les données du fichier Excel contenaient des identifiants uniques pour chaque ligne avec des codes `/A###` (A131, A132, A133, etc.), rendant chaque trajet unique même pour le même point de départ.

### Exemple concret :
```
LE HAVRE N°5 / A131 -> LE HAVRE N°5 / A131 (0.00 €)
LE HAVRE N°5 / A132 -> ST-ROMAIN-DE-COLBOSC N°6 (1.20 €)
LE HAVRE N°5 / A133 -> BOLBEC N°7 (2.50 €)
LE HAVRE N°5 / A134 -> FECAMP N°8 (4.20 €)
...
```

Chaque "LE HAVRE N°5 / A###" était considéré comme un lieu différent !

## Solution implémentée

### 1. Modification du service de données (`toll_data_service.dart`)

Ajout d'une fonction `_getBaseName()` qui nettoie les codes :
```dart
String _getBaseName(String location) {
  final regex = RegExp(r'\s*/\s*A\d+$');
  return location.replaceAll(regex, '').trim();
}
```

### 2. Mise à jour des méthodes de recherche

Toutes les méthodes utilisent maintenant le nom de base pour comparer :
- `findRoute()` : cherche d'abord exactement, puis par nom de base
- `getRoutesFrom()` : groupe tous les trajets par nom de base
- `getDestinationsFrom()` : retourne toutes les destinations uniques (Set) pour un départ donné

### 3. Création d'un fichier locations nettoyé

- **Avant** : 786 lieux avec codes (LE HAVRE N°5 / A131, LE HAVRE N°5 / A132...)
- **Après** : 746 lieux uniques (LE HAVRE N°5, etc.)
- Fichier : `assets/locations_clean.json`

### 4. Résultat

Pour "LE HAVRE N°5" :
- **Avant** : 1 destination (lui-même)
- **Après** : 7 destinations ✅
  - BOLBEC N°7
  - FECAMP N°8
  - ST-ROMAIN-DE-COLBOSC N°6
  - YERVILLE N°9
  - ...

## Fichiers modifiés

1. `lib/services/toll_data_service.dart`
   - Ajout de `_getBaseName()`
   - Modification de `findRoute()`, `getRoutesFrom()`, `getDestinationsFrom()`
   - Chargement de `locations_clean.json` au lieu de `locations_full.json`

2. `lib/debug/test_data.dart`
   - Mise à jour pour utiliser la même logique de nettoyage
   - Affichage des statistiques avec noms nettoyés

3. `pubspec.yaml`
   - Référence à `assets/locations_clean.json`

4. `assets/locations_clean.json` (nouveau)
   - 746 lieux uniques sans codes A###

## Validation

Test en PowerShell :
```powershell
# LE HAVRE N°5 passe de 1 à 7 destinations
Destinations depuis 'LE HAVRE N°5': 7
  -> BOLBEC N°7
  -> FECAMP N°8
  -> ST-ROMAIN-DE-COLBOSC N°6
  -> YERVILLE N°9
  ...
```

## Points techniques importants

1. **Conservation des données originales** : Le fichier `toll_data_full.json` n'a pas été modifié, seul le traitement en mémoire a changé.

2. **Recherche intelligente** : La méthode `findRoute()` essaie d'abord une correspondance exacte avant de nettoyer, garantissant la compatibilité.

3. **Set pour éviter les doublons** : `getDestinationsFrom()` utilise un Set pour éliminer les destinations en double.

4. **Tri automatique** : Les résultats sont triés alphabétiquement pour une meilleure UX.

## Date de correction

22 février 2026
