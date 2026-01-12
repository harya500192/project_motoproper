// lib/models/service_part_model.dart

class ServicePart {
  final String id;
  final String logId;
  final String partName;
  final int cost;
  final int? kmNextDue; // Kilometer servis selanjutnya (bisa null)

  ServicePart({
    required this.id,
    required this.logId,
    required this.partName,
    required this.cost,
    this.kmNextDue,
  });

  factory ServicePart.fromJson(Map<String, dynamic> json) {
    return ServicePart(
      id: json['id'] as String,
      logId: json['log_id'] as String,
      partName: json['part_name'] as String,
      cost: (json['cost'] as num).toInt(),
      kmNextDue: (json['km_next_due'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'log_id': logId,
      'part_name': partName,
      'cost': cost,
      'km_next_due': kmNextDue,
    };
  }
}