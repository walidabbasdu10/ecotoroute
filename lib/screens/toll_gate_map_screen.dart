import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/toll_gate.dart';
import '../services/openstreetmap_service.dart';

class TollGateMapScreen extends StatefulWidget {
  final String? initialSearchQuery;
  
  const TollGateMapScreen({super.key, this.initialSearchQuery});

  @override
  State<TollGateMapScreen> createState() => _TollGateMapScreenState();
}

class _TollGateMapScreenState extends State<TollGateMapScreen> {
  final OpenStreetMapService _osmService = OpenStreetMapService();
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  
  List<TollGate> _tollGates = [];
  bool _isLoading = false;
  String? _errorMessage;
  TollGate? _selectedTollGate;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null) {
      _searchController.text = widget.initialSearchQuery!;
      _searchTollGates();
    }
  }

  Future<void> _searchTollGates() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer un nom de péage ou d\'autoroute';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedTollGate = null;
    });

    try {
      // Normaliser le nom pour la recherche
      final normalizedQuery = _osmService.normalizeName(query);
      
      List<TollGate> results;
      
      // Si c'est un code d'autoroute (A1, A6, etc.), chercher par autoroute
      if (RegExp(r'^A\d+$', caseSensitive: false).hasMatch(normalizedQuery)) {
        results = await _osmService.searchTollGatesByHighway(normalizedQuery.toUpperCase());
      } else {
        results = await _osmService.searchTollGates(normalizedQuery);
      }

      setState(() {
        _tollGates = results;
        _isLoading = false;
        
        if (results.isEmpty) {
          _errorMessage = 'Aucun péage trouvé pour "$query"';
        } else {
          // Centrer la carte sur le premier résultat
          if (results.first.hasCoordinates) {
            _mapController.move(
              LatLng(results.first.latitude!, results.first.longitude!),
              10.0,
            );
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Péages sur OpenStreetMap'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Nom du péage ou autoroute (ex: A1, Saint-Arnoult)...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _searchTollGates(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _searchTollGates,
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: const Text('Rechercher'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Message d'erreur
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),

          // Carte et résultats
          Expanded(
            child: _tollGates.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Recherchez un péage ou une autoroute',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ex: "A1", "Saint-Arnoult", "Montmarault"',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      // Liste des résultats
                      Container(
                        width: 350,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(2, 0),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_tollGates.length} péage${_tollGates.length > 1 ? 's' : ''} trouvé${_tollGates.length > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _tollGates.length,
                                itemBuilder: (context, index) {
                                  final tollGate = _tollGates[index];
                                  final isSelected = _selectedTollGate == tollGate;
                                  
                                  return ListTile(
                                    selected: isSelected,
                                    selectedTileColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                        .withOpacity(0.3),
                                    leading: CircleAvatar(
                                      backgroundColor: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.blue.shade100,
                                      child: Icon(
                                        Icons.toll,
                                        color: isSelected ? Colors.white : Colors.blue,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      tollGate.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (tollGate.highwayRef != null)
                                          Text('🛣️ ${tollGate.highwayRef}'),
                                        if (tollGate.hasCoordinates)
                                          Text(
                                            '📍 ${tollGate.latitude!.toStringAsFixed(4)}, ${tollGate.longitude!.toStringAsFixed(4)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedTollGate = tollGate;
                                      });
                                      if (tollGate.hasCoordinates) {
                                        _mapController.move(
                                          LatLng(tollGate.latitude!, tollGate.longitude!),
                                          14.0,
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Carte
                      Expanded(
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: const LatLng(46.603354, 1.888334), // Centre de la France
                            initialZoom: 6.0,
                            minZoom: 4.0,
                            maxZoom: 18.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.ecotoroute',
                            ),
                            MarkerLayer(
                              markers: _tollGates
                                  .where((tg) => tg.hasCoordinates)
                                  .map((tollGate) {
                                final isSelected = _selectedTollGate == tollGate;
                                return Marker(
                                  point: LatLng(tollGate.latitude!, tollGate.longitude!),
                                  width: 40,
                                  height: 40,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedTollGate = tollGate;
                                      });
                                    },
                                    child: Icon(
                                      Icons.location_on,
                                      color: isSelected ? Colors.red : Colors.blue,
                                      size: isSelected ? 40 : 32,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),

          // Détails du péage sélectionné
          if (_selectedTollGate != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(
                  top: BorderSide(color: Colors.blue.shade200),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Détails du péage',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Nom', _selectedTollGate!.name),
                  if (_selectedTollGate!.highwayRef != null)
                    _buildDetailRow('Autoroute', _selectedTollGate!.highwayRef!),
                  if (_selectedTollGate!.operator != null)
                    _buildDetailRow('Exploitant', _selectedTollGate!.operator!),
                  if (_selectedTollGate!.hasCoordinates)
                    _buildDetailRow(
                      'Coordonnées GPS',
                      '${_selectedTollGate!.latitude!.toStringAsFixed(6)}, ${_selectedTollGate!.longitude!.toStringAsFixed(6)}',
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
