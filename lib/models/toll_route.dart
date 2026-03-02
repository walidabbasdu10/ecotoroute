class TollRoute {
  final String fromId;
  final String fromName;
  final String fromMotorway;
  final String fromNetwork;
  final String toId;
  final String toName;
  final String toMotorway;
  final String toNetwork;
  final double class1Price;
  final double class2Price;
  final double class3Price;

  TollRoute({
    required this.fromId,
    required this.fromName,
    required this.fromMotorway,
    required this.fromNetwork,
    required this.toId,
    required this.toName,
    required this.toMotorway,
    required this.toNetwork,
    required this.class1Price,
    this.class2Price = 0.0,
    this.class3Price = 0.0,
  });

  // Compatibilité avec l'ancien format
  String get from => '$fromName / $fromMotorway';
  String get to => '$toName / $toMotorway';
  double get price => class1Price;

  factory TollRoute.fromJson(Map<String, dynamic> json) {
    // Fonction helper pour convertir les prix (peut être int, double ou String)
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return TollRoute(
      fromId: json['fromId'] as String? ?? '',
      fromName: json['fromName'] as String? ?? '',
      fromMotorway: json['fromMotorway'] as String? ?? '',
      fromNetwork: json['fromNetwork'] as String? ?? '',
      toId: json['toId'] as String? ?? '',
      toName: json['toName'] as String? ?? '',
      toMotorway: json['toMotorway'] as String? ?? '',
      toNetwork: json['toNetwork'] as String? ?? '',
      class1Price: parsePrice(json['class1Price']),
      class2Price: parsePrice(json['class2Price']),
      class3Price: parsePrice(json['class3Price']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromId': fromId,
      'fromName': fromName,
      'fromMotorway': fromMotorway,
      'fromNetwork': fromNetwork,
      'toId': toId,
      'toName': toName,
      'toMotorway': toMotorway,
      'toNetwork': toNetwork,
      'class1Price': class1Price,
      'class2Price': class2Price,
      'class3Price': class3Price,
    };
  }
}
