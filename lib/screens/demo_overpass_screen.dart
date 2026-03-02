import 'package:flutter/material.dart';
import '../services/overpass_api_service.dart';
import 'dart:convert';

/// Écran de démonstration simple pour tester l'API Overpass
/// Utilisez cet écran pour voir l'API en action sans complexité
class DemoOverpassScreen extends StatefulWidget {
  const DemoOverpassScreen({super.key});

  @override
  State<DemoOverpassScreen> createState() => _DemoOverpassScreenState();
}

class _DemoOverpassScreenState extends State<DemoOverpassScreen> {
  final OverpassApiService _api = OverpassApiService();
  String _resultat = 'Cliquez sur un bouton pour tester l\'API';
  bool _isLoading = false;

  Future<void> _test1() async {
    setState(() {
      _isLoading = true;
      _resultat = 'Chargement...';
    });

    try {
      // TEST 1: Recherche simple avec Query Builder
      final peages = await _api
          .createQuery()
          .inCountry('FR')
          .addNode('barrier', 'toll_booth')
          .limit(5)
          .execute();

      final buffer = StringBuffer();
      buffer.writeln('✅ TEST 1 RÉUSSI!');
      buffer.writeln('\nTrouvé ${peages.length} péages:\n');

      for (var i = 0; i < peages.length; i++) {
        final p = peages[i];
        final tags = p['tags'] as Map<String, dynamic>? ?? {};
        final nom = tags['name'] ?? 'Sans nom';
        final lat = p['lat'] ?? 'N/A';
        final lon = p['lon'] ?? 'N/A';

        buffer.writeln('${i + 1}. $nom');
        buffer.writeln('   📍 $lat, $lon');
        if (tags['ref'] != null) {
          buffer.writeln('   🛣️  ${tags['ref']}');
        }
        buffer.writeln();
      }

      setState(() {
        _resultat = buffer.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _resultat = '❌ Erreur: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _test2() async {
    setState(() {
      _isLoading = true;
      _resultat = 'Recherche autour de Paris...';
    });

    try {
      // TEST 2: Recherche autour de Paris (30km)
      final peages = await _api.searchAroundPoint(
        48.8566, // Paris
        2.3522,
        30000, // 30km
        tagKey: 'barrier',
        tagValue: 'toll_booth',
        maxResults: 10,
      );

      final buffer = StringBuffer();
      buffer.writeln('✅ TEST 2 RÉUSSI!');
      buffer.writeln('\nPéages dans un rayon de 30km autour de Paris:');
      buffer.writeln('Trouvé ${peages.length} résultat(s)\n');

      for (var i = 0; i < peages.length && i < 8; i++) {
        final p = peages[i];
        final tags = p['tags'] as Map<String, dynamic>? ?? {};
        final nom = tags['name'] ?? 'Sans nom';

        buffer.writeln('${i + 1}. $nom');
      }

      if (peages.isEmpty) {
        buffer.writeln('Aucun péage trouvé dans cette zone.');
      }

      setState(() {
        _resultat = buffer.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _resultat = '❌ Erreur: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _test3() async {
    setState(() {
      _isLoading = true;
      _resultat = 'Recherche dans Île-de-France...';
    });

    try {
      // TEST 3: BBox Île-de-France
      final peages = await _api.getTollsInBoundingBox(
        48.5, 1.8, 49.2, 3.0,
        maxResults: 20,
      );

      final buffer = StringBuffer();
      buffer.writeln('✅ TEST 3 RÉUSSI!');
      buffer.writeln('\nPéages en Île-de-France:');
      buffer.writeln('Trouvé ${peages.length} résultat(s)\n');

      // Grouper par autoroute
      final Map<String, int> parAutoroute = {};
      for (final p in peages) {
        final tags = p['tags'] as Map<String, dynamic>? ?? {};
        final ref = tags['ref'] as String? ?? 'Non spécifié';
        parAutoroute[ref] = (parAutoroute[ref] ?? 0) + 1;
      }

      buffer.writeln('Répartition par autoroute:');
      parAutoroute.forEach((autoroute, nombre) {
        buffer.writeln('  🛣️  $autoroute: $nombre péage(s)');
      });

      setState(() {
        _resultat = buffer.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _resultat = '❌ Erreur: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _test4() async {
    setState(() {
      _isLoading = true;
      _resultat = 'Test de connexion...';
    });

    try {
      // TEST 4: Statut du serveur
      final isConnected = await _api.testConnection();
      final status = await _api.getServerStatus();

      final buffer = StringBuffer();
      buffer.writeln('✅ TEST 4 RÉUSSI!');
      buffer.writeln('\nStatut du serveur:\n');
      buffer.writeln('🌐 Serveur: ${_api.currentServer}');
      buffer.writeln('🔌 Connexion: ${isConnected ? "✓ OK" : "✗ Échec"}');
      buffer.writeln('📊 Disponible: ${status['available']}');
      buffer.writeln('🔢 Code HTTP: ${status['status_code']}');
      buffer.writeln('\nServeurs disponibles:');
      for (var i = 0; i < OverpassApiService.overpassServers.length; i++) {
        final server = OverpassApiService.overpassServers[i];
        final current = server == _api.currentServer ? ' ← actuel' : '';
        buffer.writeln('  ${i + 1}. $server$current');
      }

      setState(() {
        _resultat = buffer.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _resultat = '❌ Erreur: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _test5() async {
    setState(() {
      _isLoading = true;
      _resultat = 'Génération de requête...';
    });

    try {
      // TEST 5: Afficher la requête générée
      final builder = _api
          .createQuery()
          .inCountry('FR')
          .addNode('barrier', 'toll_booth')
          .addWay('barrier', 'toll_booth')
          .timeout(30)
          .limit(50);

      final query = builder.build();

      final buffer = StringBuffer();
      buffer.writeln('✅ TEST 5 RÉUSSI!');
      buffer.writeln('\nRequête Overpass QL générée:\n');
      buffer.writeln('━' * 40);
      buffer.writeln(query);
      buffer.writeln('━' * 40);
      buffer.writeln('\n💡 Copiez cette requête dans');
      buffer.writeln('   https://overpass-turbo.eu/');
      buffer.writeln('   pour la tester en ligne!');

      setState(() {
        _resultat = buffer.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _resultat = '❌ Erreur: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Démo API Overpass'),
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        children: [
          // Boutons de test
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border(
                bottom: BorderSide(color: Colors.green[200]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tests rapides',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTestButton('1. Query Builder', _test1, Colors.blue),
                    _buildTestButton('2. Autour de Paris', _test2, Colors.orange),
                    _buildTestButton('3. BBox IDF', _test3, Colors.purple),
                    _buildTestButton('4. Statut serveur', _test4, Colors.green),
                    _buildTestButton('5. Voir requête', _test5, Colors.teal),
                  ],
                ),
              ],
            ),
          ),

          // Zone de résultats
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Chargement...'),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: SelectableText(
                        _resultat,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(String label, VoidCallback onPressed, Color color) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label),
    );
  }
}
