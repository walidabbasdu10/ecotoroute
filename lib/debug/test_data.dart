import 'dart:convert';
import 'package:flutter/services.dart';

Future<void> testTollData() async {
  print('\n=== TEST DES DONNÉES (Version avec nettoyage A###) ===\n');
  
  try {
    // Charger les données
    final dataString = await rootBundle.loadString('assets/toll_data_full.json');
    final List<dynamic> data = json.decode(dataString);
    
    print('✅ Total de trajets: ${data.length}');
    
    // Fonction pour nettoyer et normaliser les noms
    String cleanName(String name) {
      // 1. Enlever les codes /A###
      String cleaned = name.replaceAll(RegExp(r'\s*/\s*A\d+$'), '').trim();
      
      // 2. Enlever les numéros entre parenthèses au début
      cleaned = cleaned.replaceAll(RegExp(r'^\(\d+\)\s*'), '').trim();
      
      // 3. Enlever les N° à la fin
      cleaned = cleaned.replaceAll(RegExp(r'\s*N°\d+$'), '').trim();
      
      // 4. Normaliser : majuscules, remplacer tirets par espaces
      cleaned = cleaned.toUpperCase().replaceAll('-', ' ');
      
      // 5. Normaliser les espaces multiples
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
      
      return cleaned;
    }
    
    // Compter les destinations par point de départ (avec nettoyage)
    final Map<String, Set<String>> fromToMap = {};
    for (var route in data) {
      final fromClean = cleanName(route['from']);
      final toClean = cleanName(route['to']);
      
      if (!fromToMap.containsKey(fromClean)) {
        fromToMap[fromClean] = {};
      }
      if (toClean != fromClean) {
        fromToMap[fromClean]!.add(toClean);
      }
    }
    
    print('\n📊 Statistiques:');
    print('   Points de départ uniques: ${fromToMap.length}');
    
    // Top 10 avec le plus de destinations
    final sorted = fromToMap.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    
    print('\n🏆 Top 10 des départs avec le plus de destinations:');
    for (var i = 0; i < 10 && i < sorted.length; i++) {
      print('   ${sorted[i].key} -> ${sorted[i].value.length} destinations');
    }
    
    // Test avec LE HAVRE
    if (fromToMap.containsKey('LE HAVRE N°5')) {
      final destinations = fromToMap['LE HAVRE N°5']!.toList()..sort();
      print('\n🎯 LE HAVRE N°5:');
      print('   ${destinations.length} destinations');
      for (var dest in destinations) {
        print('     -> $dest');
      }
    }
    
    print('\n✅ Tests terminés!\n');
  } catch (e) {
    print('❌ Erreur: $e\n');
  }
}
