import 'package:flutter/material.dart';
import '../services/toll_data_service.dart';

class LocationSelectionScreen extends StatefulWidget {
  final String title;
  final String? initialLocation;
  final List<String>? availableLocations;
  final String? originLocation;

  const LocationSelectionScreen({
    super.key,
    required this.title,
    this.initialLocation,
    this.availableLocations,
    this.originLocation,
  });

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TollDataService _dataService = TollDataService();
  List<String> _filteredLocations = [];
  List<String> _baseLocations = [];

  @override
  void initState() {
    super.initState();
    // Utiliser les locations disponibles si fournies, sinon toutes les locations
    _baseLocations = widget.availableLocations ?? _dataService.locations;
    _filteredLocations = _baseLocations;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredLocations = _baseLocations;
      } else {
        final queryLower = _searchController.text.toLowerCase();
        _filteredLocations = _baseLocations
            .where((loc) => loc.toLowerCase().contains(queryLower))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1976D2),
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher un lieu...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),
          // Message informatif si on filtre les destinations disponibles
          if (widget.availableLocations != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.blue[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_baseLocations.length} destination${_baseLocations.length > 1 ? 's' : ''} disponible${_baseLocations.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.originLocation != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Depuis : ${widget.originLocation}',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: _filteredLocations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun lieu trouvé',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredLocations.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final location = _filteredLocations[index];
                      final isSelected = location == widget.initialLocation;
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected 
                              ? const Color(0xFF1976D2) 
                              : Colors.grey[300],
                          child: Icon(
                            Icons.location_on,
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                        ),
                        title: Text(
                          location,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFF1976D2) : Colors.black87,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Color(0xFF1976D2))
                            : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {
                          Navigator.pop(context, location);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
