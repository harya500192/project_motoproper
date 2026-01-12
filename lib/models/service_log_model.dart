// lib/models/service_log_model.dart

class ServiceLog {
  final String id;
  final String vehicleId;
  final int kmAtService;
  final String serviceName;
  final DateTime date;
  final int cost;
  final String? notes;

  ServiceLog({
    required this.id,
    required this.vehicleId,
    required this.kmAtService,
    required this.serviceName,
    required this.date,
    required this.cost,
    this.notes,
  });

  factory ServiceLog.fromJson(Map<String, dynamic> json) {
    return ServiceLog(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      kmAtService: json['km_at_service'] as int? ?? 0,
      serviceName: json['service_name'] as String? ?? 'Servis Umum',
      date: DateTime.parse(json['date'] as String),
      cost: json['cost'] as int? ?? 0,
      notes: json['notes'] as String?,
    );
  }
}