# Résolution du problème de filtrage des destinations - Version 2

## Analyse du problème persistant

### Symptôme observé
Malgré la première correction des codes `/A###`, **tous les départs retournaient exactement 9 destinations**, quelle que soit l'origine sélectionnée.

### Logs système révélateurs
```
🔍 Départ: (17) St-Gibrien
📍 Destinations disponibles: 9

🔍 Départ: (15) St-Germain-Laxis
📍 Destinations disponibles: 9

🔍 Départ: (19) Vatry
📍 Destinations disponibles: 9
```

## Cause racine identifiée

**Incohérence de format entre les fichiers :**

### Fichier `locations_clean.json` (UI)
```
"(17) St-Gibrien"
"(15) St-Germain-Laxis"
"LE HAVRE N°5"
```

### Fichier `toll_data_full.json` (données brutes)
```
"ST GIBRIEN"
"ST GERMAIN LAXIS"
"LE HAVRE"
```

**Résultat** : La recherche de destinations échouait car "(17) St-Gibrien" ≠ "ST GIBRIEN" !

## Solution : Normalisation complète

### Fonction `_getBaseName()` améliorée

```dart
String _getBaseName(String location) {
  // 1. Enlever les codes /A### à la fin
  String cleaned = location.replaceAll(RegExp(r'\s*/\s*A\d+$'), '').trim();
  
  // 2. Enlever les numéros entre parenthèses au début : (17) -> ""
  cleaned = cleaned.replaceAll(RegExp(r'^\(\d+\)\s*'), '').trim();
  
  // 3. Enlever les N° à la fin : N°5 -> ""
  cleaned = cleaned.replaceAll(RegExp(r'\s*N°\d+$'), '').trim();
  
  // 4. Normaliser : majuscules, tirets -> espaces
  cleaned = cleaned.toUpperCase().replaceAll('-', ' ');
  
  // 5. Normaliser les espaces multiples
  cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  
  return cleaned;
}
```

### Exemples de normalisation

| Entrée | Sortie normalisée |
|--------|-------------------|
| `(17) St-Gibrien` | `ST GIBRIEN` |
| `ST GIBRIEN` | `ST GIBRIEN` |
| `LE HAVRE N°5 / A131` | `LE HAVRE` |
| `LE HAVRE N°5` | `LE HAVRE` |
| `SAINT-ROMAIN-DE-COLBOSC N°6` | `SAINT ROMAIN DE COLBOSC` |

## Validation des résultats

### Test PowerShell avec normalisation complète

```powershell
Destinations depuis 'ST GIBRIEN': 105
  -> AMBERIEU
  -> ARLAY
  -> AUXERRE NORD
  -> AUXERRE SUD
  -> AVALLON
  -> BALAN
  -> BAUME LES DAMES
  ... (105 destinations au total)
```

**Avant correction** : 9 destinations (incorrectes)  
**Après correction** : 105 destinations ✅

### Test LE HAVRE

```powershell
Destinations depuis 'LE HAVRE': 7
  -> BEAUT
  -> BOLBEC
  -> FECAMP
  -> ST ROMAIN DE COLBOSC
  -> ST SAENS
  -> YERVILLE
  -> YVETOT
```

## Impact de la correction

### Fichiers modifiés
1. `lib/services/toll_data_service.dart` - Fonction `_getBaseName()` complètement réécrite
2. `lib/debug/test_data.dart` - Mise à jour de la fonction `cleanName()` avec la même logique

### Points techniques importants

1. **Normalisation bidirectionnelle** : Fonctionne aussi bien pour les noms de l'UI que pour les données brutes
2. **Préservation des données** : `toll_data_full.json` reste inchangé
3. **Compatibilité** : `findRoute()` essaie d'abord une correspondance exacte avant  de normaliser
4. **Élimination des doublons** : Utilisation d'un `Set` dans `getDestinationsFrom()`

### Étapes de débogage utilisées

1. Analyse des logs système → Identification du pattern "9 destinations" constant
2. Examen du fichier `locations_clean.json` → Format "(17) St-Gibrien"
3. Examen du fichier `toll_data_full.json` → Format "ST GIBRIEN"
4. Test de correspondance → Échec du matching
5. Implémentation de la normalisation complète
6. Validation avec PowerShell → 105 destinations trouvées
7. Application du fix au code Dart

## Différence avec la première correction

| Correction #1 | Correction #2 (finale) |
|---------------|------------------------|
| Gérait uniquement `/A###` | Gère 5 types de variations |
| Conservait les parenthèses | Supprime `(17)` |
| Conservait les N° | Supprime `N°5` |
| Conservait la casse | Normalise en MAJUSCULES |
| Conservait les tirets | Convertit tirets en espaces |

## Date des corrections

- **Correction #1** : 22 février 2026 - Codes /A###
- **Correction #2** : 22 février 2026 - Normalisation complète

## Niveau de confiance

✅ **Validation technique réussie** : Tests PowerShell confirment 105 destinations  
⏳ **Validation utilisateur en cours** : Application en cours de démarrage
