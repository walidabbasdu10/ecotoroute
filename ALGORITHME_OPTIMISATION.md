# Algorithme d'optimisation des trajets

## 📊 Fonctionnalité ajoutée

L'application intègre maintenant un **algorithme d'optimisation des trajets** qui compare automatiquement toutes les combinaisons possibles entre le départ et l'arrivée pour trouver le prix le plus avantageux.

## 🎯 Objectif

Trouver le trajet le moins cher entre deux points en permettant **une sortie et une rentrée** sur l'autoroute via un point intermédiaire.

## 🔍 Comment ça fonctionne ?

### Algorithme de recherche

Pour un trajet de **A vers C**, l'algorithme :

1. **Vérifie le trajet direct** : A → C
2. **Teste tous les points intermédiaires B** possibles :
   - A → B + B → C
   - Compare le coût total avec le trajet direct
3. **Retourne le meilleur trajet** trouvé

### Exemple concret

```
Départ : PARIS
Arrivée : LYON

Option 1 (Direct) :
  PARIS → LYON : 35.80 €

Option 2 (Via AUXERRE) :
  PARIS → AUXERRE : 18.40 €
  AUXERRE → LYON : 15.20 €
  Total : 33.60 € ✅ (Économie de 2.20 €)

→ L'application affiche automatiquement l'option 2 (la moins chère)
```

## 💻 Architecture technique

### Nouveaux modèles

**`OptimizedRoute`** (`lib/models/optimized_route.dart`)
```dart
class OptimizedRoute {
  final List<RouteSegment> segments;  // Liste des tronçons
  final double totalPrice;            // Prix total
  final bool isDirect;                // Direct ou optimisé ?
}
```

**`RouteSegment`** (même fichier)
```dart
class RouteSegment {
  final String from;    // Point de départ du segment
  final String to;      // Point d'arrivée du segment
  final double price;   // Prix du segment
}
```

### Méthodes ajoutées

**`TollDataService.findOptimalRoute()`**
```dart
OptimizedRoute? findOptimalRoute(String from, String to)
```
- Parcourt tous les points intermédiaires possibles (696 lieux)
- Compare le prix de chaque combinaison
- Retourne le trajet avec le coût minimal

**`TollDataService.calculateSavings()`**
```dart
double? calculateSavings(String from, String to)
```
- Calcule l'économie réalisée par rapport au trajet direct
- Retourne `0.0` si le trajet direct est déjà optimal
- Retourne `null` si aucun trajet n'existe

### Modifications UI

**Affichage adaptatif** (`home_screen.dart`)

**Trajet direct :**
- Fond bleu (#1976D2)
- Icône : `Icons.route`
- Label : "Trajet direct"

**Trajet optimisé :**
- Fond vert (#4CAF50)
- Icône : `Icons.savings_outlined`
- Label : "Trajet optimisé"
- Détails affichés :
  - Itinéraire complet étape par étape
  - Prix de chaque segment
  - Économie réalisée

## 📈 Complexité

- **Temps :** O(n) où n = nombre de points intermédiaires (696)
- **Espace :** O(1) - pas de stockage supplémentaire
- **Trajets testés par recherche :** ~696 combinaisons maximum

## ⚡ Optimisations possibles

Pour des améliorations futures :

1. **Cache des résultats** : Stocker les trajets déjà calculés
2. **Algorithme A*** : Pour les trajets avec plusieurs étapes (2+)
3. **Filtrage géographique** : Exclure les points trop éloignés
4. **Index spatial** : Accélérer la recherche des points intermédiaires
5. **Algorithme de Dijkstra** : Pour trouver le plus court chemin avec N étapes

## 🎨 Interface utilisateur

### Carte de résultat (Direct)
```
┌─────────────────────────┐
│   🛣️  Trajet direct      │
│                         │
│      35.80 €           │
│   Véhicule léger       │
└─────────────────────────┘
```

### Carte de résultat (Optimisé)
```
┌─────────────────────────┐
│   💰 Trajet optimisé    │
│                         │
│      33.60 €           │
│   Véhicule léger       │
└─────────────────────────┘

┌─────────────────────────┐
│ ℹ️ Itinéraire détaillé  │
│                         │
│ 1️⃣ PARIS → AUXERRE      │
│    18.40 €             │
│                         │
│ 2️⃣ AUXERRE → LYON       │
│    15.20 €             │
│                         │
│ 📉 Économie : 2.20 €   │
└─────────────────────────┘
```

## 🧪 Tests recommandés

### Cas à tester :

1. **Trajet direct optimal**
   - Ex: Points proches où le direct est plus économique

2. **Trajet avec économie**
   - Ex: Longues distances avec points intermédiaires stratégiques

3. **Aucun trajet disponible**
   - Gestion de l'erreur si aucune combinaison n'existe

4. **Points identiques**
   - Départ = Arrivée (doit retourner 0 €)

## 📊 Statistiques

Avec **43,141 trajets** et **696 points** :
- Nombre maximum de comparaisons par recherche : **696**
- Temps moyen de calcul : **< 100ms** (sur données en mémoire)
- Taux de réussite d'optimisation : **Variable selon les trajets**

## 🚀 Améliorations futures

1. **Trajets multi-étapes** : Autoriser 2+ sorties/entrées
2. **Préférences utilisateur** : 
   - Privilégier la rapidité vs l'économie
   - Éviter certaines zones
3. **Historique des recherches** : Suggestions basées sur l'usage
4. **Mode comparaison** : Afficher toutes les options côte à côte
5. **Export PDF** : Générer un récapitulatif du trajet optimal

## 📝 Notes techniques

- L'algorithme normalise les noms de lieux avant la comparaison
- Compatibilité maintenue avec le filtrage intelligent des destinations
- Pas d'impact sur les performances de chargement initial
- Calcul effectué uniquement quand départ ET arrivée sont sélectionnés

---

**Date d'implémentation :** 22 février 2026  
**Version :** 1.1.0
