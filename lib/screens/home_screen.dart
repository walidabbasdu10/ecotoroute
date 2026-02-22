import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/toll_data_service.dart';
import '../models/optimized_route.dart';
import 'location_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TollDataService _dataService = TollDataService();
  String? _from;
  String? _to;
  OptimizedRoute? _optimizedRoute;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await _dataService.loadData();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _selectLocation(bool isFrom) async {
    // Si on sélectionne une destination et qu'il y a un départ, filtrer les destinations disponibles
    List<String>? availableLocations;
    if (!isFrom && _from != null) {
      availableLocations = _dataService.getDestinationsFrom(_from!);
      
      // Debug : afficher le nombre de destinations
      print('🔍 Départ: $_from');
      print('📍 Destinations disponibles: ${availableLocations.length}');
      
      if (availableLocations.isEmpty) {
        // Aucune destination disponible depuis ce point
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Aucune destination disponible depuis "$_from" dans les données actuelles'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationSelectionScreen(
          title: isFrom ? 'Point de départ' : 'Point d\'arrivée',
          initialLocation: isFrom ? _from : _to,
          availableLocations: availableLocations,
          originLocation: isFrom ? null : _from,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (isFrom) {
          _from = result;
          // Réinitialiser la destination si elle n'est plus valide
          if (_to != null && !_dataService.routeExists(result, _to!)) {
            _to = null;
            _optimizedRoute = null;
          }
        } else {
          _to = result;
        }
        _calculateToll();
      });
    }
  }

  void _calculateToll() {
    if (_from != null && _to != null) {
      setState(() {
        _optimizedRoute = _dataService.findOptimalRoute(_from!, _to!);
      });
    }
  }

  void _swapLocations() {
    if (_from != null || _to != null) {
      setState(() {
        final temp = _from;
        _from = _to;
        _to = temp;
        _calculateToll();
      });
    }
  }

  void _reset() {
    setState(() {
      _from = null;
      _to = null;
      _optimizedRoute = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Chargement des données...',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erreur',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1976D2),
              const Color(0xFF1565C0),
              Colors.blue[800]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // En-tête
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.route,
                      size: 64,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ecotoroute',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Calculez vos péages autoroutiers',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // Carte principale
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Message d'information sur les données complètes
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.green[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Version complète : 43 141 trajets disponibles',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.green[900],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Sélection de départ
                        _buildLocationCard(
                          icon: Icons.trip_origin,
                          iconColor: const Color(0xFF4CAF50),
                          title: 'Départ',
                          location: _from,
                          onTap: () => _selectLocation(true),
                        ),

                        // Bouton d'échange
                        Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.swap_vert),
                              onPressed: _swapLocations,
                              color: const Color(0xFF1976D2),
                            ),
                          ),
                        ),

                        // Sélection d'arrivée
                        _buildLocationCard(
                          icon: Icons.location_on,
                          iconColor: const Color(0xFFE53935),
                          title: 'Arrivée',
                          location: _to,
                          onTap: _from == null ? null : () => _selectLocation(false),
                          isDisabled: _from == null,
                        ),

                        const SizedBox(height: 24),

                        // Résultat du péage optimisé
                        if (_optimizedRoute != null) ...[
                          // Carte principale avec le prix
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _optimizedRoute!.isDirect 
                                    ? const Color(0xFF1976D2)
                                    : const Color(0xFF4CAF50),
                                  _optimizedRoute!.isDirect
                                    ? Colors.blue[700]!
                                    : Colors.green[700]!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: (_optimizedRoute!.isDirect 
                                    ? const Color(0xFF1976D2) 
                                    : const Color(0xFF4CAF50)).withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _optimizedRoute!.isDirect 
                                        ? Icons.route 
                                        : Icons.savings_outlined,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _optimizedRoute!.isDirect 
                                        ? 'Trajet direct'
                                        : 'Trajet optimisé',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${_optimizedRoute!.totalPrice.toStringAsFixed(2)} €',
                                  style: GoogleFonts.poppins(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Véhicule léger',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Détails du trajet si non direct
                          if (!_optimizedRoute!.isDirect) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline, 
                                        color: Colors.green[700], 
                                        size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Itinéraire détaillé',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green[900],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ..._optimizedRoute!.segments.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final segment = entry.value;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: Colors.green[700],
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${index + 1}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${segment.from} → ${segment.to}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    color: Colors.grey[800],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  '${segment.price.toStringAsFixed(2)} €',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  // Afficher l'économie si applicable
                                  if (_optimizedRoute!.segments.length > 1) ...[
                                    const Divider(height: 24),
                                    () {
                                      final savings = _dataService.calculateSavings(_from!, _to!);
                                      if (savings != null && savings > 0) {
                                        return Row(
                                          children: [
                                            Icon(Icons.trending_down, 
                                              color: Colors.green[700], 
                                              size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Économie : ${savings.toStringAsFixed(2)} €',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green[900],
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    }(),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _reset,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Nouveau calcul'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.grey[800],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ] else if (_from != null && _to != null) ...[
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.orange[800]),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Trajet non disponible',
                                        style: GoogleFonts.poppins(
                                          color: Colors.orange[900],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ce trajet n\'est pas disponible dans l\'échantillon de données actuel. Sélectionnez un autre départ pour voir les destinations disponibles.',
                                  style: GoogleFonts.poppins(
                                    color: Colors.orange[800],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? location,
    required VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    return Card(
      elevation: isDisabled ? 0 : 2,
      color: isDisabled ? Colors.grey[100] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isDisabled 
                            ? 'Sélectionnez d\'abord un départ'
                            : (location ?? 'Sélectionner un lieu'),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: location != null ? Colors.black87 : Colors.grey[400],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  isDisabled ? Icons.lock_outline : Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
