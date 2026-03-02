import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../services/overpass_api_service.dart';

class OverpassApiTestScreen extends StatefulWidget {
  const OverpassApiTestScreen({super.key});

  @override
  State<OverpassApiTestScreen> createState() => _OverpassApiTestScreenState();
}

class _OverpassApiTestScreenState extends State<OverpassApiTestScreen> {
  final OverpassApiService _apiService = OverpassApiService();
  final TextEditingController _queryController = TextEditingController();
  
  String? _result;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _serverStatus;

  @override
  void initState() {
    super.initState();
    _loadServerStatus();
    _setDefaultQuery();
  }

  void _setDefaultQuery() {
    _queryController.text = '''[out:json][timeout:25];
area["ISO3166-1"="FR"][admin_level=2];
(
  node["barrier"="toll_booth"]["name"~"Saint",i](area);
);
out center 10;''';
  }

  Future<void> _loadServerStatus() async {
    final status = await _apiService.getServerStatus();
    setState(() {
      _serverStatus = status;
    });
  }

  Future<void> _executeQuery() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _errorMessage = 'La requête est vide';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final result = await _apiService.executeQuery(query);
      setState(() {
        _result = const JsonEncoder.withIndent('  ').convert(result);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _testExamples(String exampleType) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      dynamic result;
      
      switch (exampleType) {
        case 'bbox':
          // Péages autour de Paris (bbox)
          result = await _apiService.getTollsInBoundingBox(
            48.8, 2.2, 48.9, 2.5,
            maxResults: 20,
          );
          break;
          
        case 'stats':
          // Statistiques des péages en France
          result = await _apiService.getFrenchTollStatistics();
          break;
          
        case 'around':
          // Péages autour d'un point (Paris)
          result = await _apiService.searchAroundPoint(
            48.8566, 2.3522, 50000, // 50km autour de Paris
            tagKey: 'barrier',
            tagValue: 'toll_booth',
            maxResults: 15,
          );
          break;
          
        case 'builder':
          // Utilisation du Query Builder
          result = await _apiService
              .createQuery()
              .inCountry('FR')
              .addNode('barrier', 'toll_booth')
              .timeout(25)
              .limit(10)
              .execute();
          break;
          
        case 'highways':
          // Autoroutes avec leurs péages
          result = await _apiService.getHighwaysWithTolls();
          break;
      }

      setState(() {
        _result = const JsonEncoder.withIndent('  ').convert(result);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overpass API - Test Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadServerStatus,
            tooltip: 'Actualiser le statut du serveur',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.dns),
            tooltip: 'Changer de serveur',
            onSelected: (server) {
              _apiService.setServer(server);
              _loadServerStatus();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Serveur changé: $server')),
              );
            },
            itemBuilder: (context) => OverpassApiService.overpassServers
                .map((server) => PopupMenuItem(
                      value: server,
                      child: Text(
                        server,
                        style: TextStyle(
                          fontWeight: server == _apiService.currentServer
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: Row(
        children: [
          // Panneau de gauche - Requêtes
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  right: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Statut du serveur
                  if (_serverStatus != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _serverStatus!['available'] == true
                            ? Colors.green[50]
                            : Colors.red[50],
                        border: Border(
                          bottom: BorderSide(
                            color: _serverStatus!['available'] == true
                                ? Colors.green[200]!
                                : Colors.red[200]!,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _serverStatus!['available'] == true
                                ? Icons.check_circle
                                : Icons.error,
                            color: _serverStatus!['available'] == true
                                ? Colors.green[700]
                                : Colors.red[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Serveur: ${_serverStatus!['available'] == true ? 'Disponible' : 'Indisponible'}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _serverStatus!['available'] == true
                                    ? Colors.green[900]
                                    : Colors.red[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Exemples rapides
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border(
                        bottom: BorderSide(color: Colors.blue[200]!),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Exemples rapides',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildExampleButton('BBox Paris', 'bbox'),
                            _buildExampleButton('Statistiques', 'stats'),
                            _buildExampleButton('Autour point', 'around'),
                            _buildExampleButton('Query Builder', 'builder'),
                            _buildExampleButton('Autoroutes', 'highways'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Éditeur de requête
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Requête Overpass QL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: _queryController,
                        maxLines: null,
                        expands: true,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Entrez votre requête Overpass QL...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Boutons d'action
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _executeQuery,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.play_arrow),
                            label: const Text('Exécuter'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _setDefaultQuery,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réinitialiser'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Panneau de droite - Résultats
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.data_object, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Résultat JSON',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (_result != null)
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _result!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Résultat copié'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          tooltip: 'Copier',
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: _buildResultView(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleButton(String label, String type) {
    return ElevatedButton(
      onPressed: _isLoading ? null : () => _testExamples(type),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: Text(label),
    );
  }

  Widget _buildResultView() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Exécution de la requête...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red[700], size: 48),
              const SizedBox(height: 16),
              const Text(
                'Erreur',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[900]),
              ),
            ],
          ),
        ),
      );
    }

    if (_result == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.api, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Exécutez une requête ou testez un exemple',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: SelectableText(
        _result!,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }
}
