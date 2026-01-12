// lib/models/vehicle_type_model.dart

class VehicleType {
  final String id;
  final String typeName;
  
  VehicleType({required this.id, required this.typeName});
  
  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: json['id'] as String,
      typeName: json['type_name'] as String,
    );
  }
}