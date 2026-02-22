class OptimizedRoute {
  final List<RouteSegment> segments;
  final double totalPrice;
  final bool isDirect;

  OptimizedRoute({
    required this.segments,
    required this.totalPrice,
    required this.isDirect,
  });

  String get description {
    if (isDirect) {
      return 'Trajet direct';
    }
    
    final intermediates = segments
        .skip(1)
        .take(segments.length - 2)
        .map((s) => s.from)
        .join(' → ');
    
    return 'Via: $intermediates';
  }

  double get savings {
    if (segments.isEmpty) return 0.0;
    // On ne peut calculer l'économie que si on a le prix direct
    return 0.0;
  }
}

class RouteSegment {
  final String from;
  final String to;
  final double price;

  RouteSegment({
    required this.from,
    required this.to,
    required this.price,
  });

  @override
  String toString() => '$from → $to (${price.toStringAsFixed(2)} €)';
}
