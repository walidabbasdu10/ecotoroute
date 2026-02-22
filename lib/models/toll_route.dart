class TollRoute {
  final String from;
  final String to;
  final String distance;
  final double price;

  TollRoute({
    required this.from,
    required this.to,
    required this.distance,
    required this.price,
  });

  factory TollRoute.fromJson(Map<String, dynamic> json) {
    return TollRoute(
      from: json['from'] as String,
      to: json['to'] as String,
      distance: json['distance'] as String? ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'distance': distance,
      'price': price,
    };
  }
}
