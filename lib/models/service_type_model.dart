// lib/models/service_type_model.dart

class ServiceType {
  final String id;
  final String name; 
  final int frequencyKm; 
  final int frequencyMonths; 
  final double defaultCost; 

  ServiceType({
    required this.id,
    required this.name,
    required this.frequencyKm,
    required this.frequencyMonths,
    required this.defaultCost,
  });

  factory ServiceType.fromJson(Map<String, dynamic> json) {
    return ServiceType(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String,
      frequencyKm: (json['frequency_km'] as num).toInt(), 
      frequencyMonths: (json['frequency_months'] as num).toInt(),
      defaultCost: (json['default_cost'] as num).toDouble(), 
    );
  }

  factory ServiceType.fromMap(Map<String, dynamic> json) {
      return ServiceType.fromJson(json);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'frequency_km': frequencyKm,
      'frequency_months': frequencyMonths,
      'default_cost': defaultCost,
    };
  }
}