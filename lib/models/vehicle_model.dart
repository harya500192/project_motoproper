// lib/models/vehicle_model.dart

class Vehicle {
  final String id;
  final String name;
  final String plateNumber;
  final int currentKm;
  final DateTime lastServiceDate;
  
  Vehicle({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.currentKm,
    required this.lastServiceDate,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    // Memastikan setiap field yang mungkin null dari DB diberi fallback yang sesuai
    return Vehicle(
      id: json['id'] as String? ?? 'N/A', 
      name: json['name'] as String? ?? 'Nama Kendaraan', 
      plateNumber: json['plate_number'] as String? ?? 'N/A', 
      currentKm: json['current_km'] as int? ?? 0, 
      // lastServiceDate harus tahan null dari DB (terutama untuk kendaraan baru)
      lastServiceDate: DateTime.parse(json['last_service_date'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}