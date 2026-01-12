// lib/pages/vehicle_detail_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; 
import 'package:project_motoproper/models/vehicle_model.dart'; 
import 'package:project_motoproper/models/service_log_model.dart'; // Asumsi model ini ada
import 'package:project_motoproper/pages/add_service_log_page.dart'; 
import 'package:project_motoproper/pages/edit_vehicle_page.dart'; 

// --- MODEL PART STATIS (Diperlukan untuk 6 Kategori Servis) ---
class StaticPartReminder {
  final String partName;
  final int intervalKm;
  final int kmCurrent;
  final String iconName;
  
  StaticPartReminder({
    required this.partName, 
    required this.intervalKm, 
    required this.kmCurrent, 
    required this.iconName,
  });

  // Logika sederhana untuk menghitung sisa KM
  int get remainingKm {
      final remaining = intervalKm - (kmCurrent % intervalKm);
      // Untuk interval yang sangat besar (seperti "Lain-lain"), kita asumsikan tidak akan jatuh tempo
      if (intervalKm > 50000) return 99999; 
      return remaining > 0 ? remaining : 0; 
  }
  
  // Asumsi jatuh tempo jika sisa KM kurang dari 500
  bool get isOverdue => remainingKm <= 500; 
}


class VehicleDetailPage extends StatefulWidget {
  final Vehicle vehicle;
  const VehicleDetailPage({super.key, required this.vehicle});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  final supabase = Supabase.instance.client;
  late Vehicle _currentVehicle;
  
  // --- STATE UNTUK REKOMENDASI PART ---
  List<StaticPartReminder> _staticPartReminders = []; 
  
  List<ServiceLog> _serviceLogs = []; 
  bool _isLoadingLogs = true; 

  // DAFTAR PART STATIS DENGAN INTERVAL KM
  final List<Map<String, dynamic>> _staticPartsData = [
    {'name': 'Servis Rutin Lengkap', 'interval': 4000, 'icon': 'service'},
    {'name': 'Ganti Oli Mesin & Filter', 'interval': 4000, 'icon': 'oli'},
    {'name': 'Oli Transmisi/Gardan', 'interval': 8000, 'icon': 'transmisi'},
    {'name': 'Busi & Filter Udara', 'interval': 12000, 'icon': 'busi'},
    {'name': 'Ganti Ban', 'interval': 15000, 'icon': 'ban'},
    {'name': 'Lain-lain', 'interval': 99999, 'icon': 'lain'}, 
  ];

  @override
  void initState() {
    super.initState();
    _currentVehicle = widget.vehicle;
    _initializeStaticParts(); // Inisialisasi daftar part
    _fetchServiceLogs(); 
  }
  
  void _initializeStaticParts() {
    final currentKm = _currentVehicle.currentKm;
    _staticPartReminders = _staticPartsData.map((data) {
      return StaticPartReminder(
        partName: data['name'],
        intervalKm: data['interval'],
        kmCurrent: currentKm,
        iconName: data['icon'],
      );
    }).toList();
  }
  
  // --- LOGIKA DATA (Edit, Hapus, Fetch) ---

  void _navigateToAddLog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddServiceLogPage(vehicle: _currentVehicle),
      ),
    );
    if (result == true) {
      _refreshData();
    }
  }

  void _navigateToEditPage() async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditVehiclePage(vehicle: _currentVehicle),
        ),
      );
      if (result == true) {
        _refreshData(); 
      }
  }

  Future<void> _fetchCurrentVehicle() async {
      try {
          // Select * untuk memastikan semua field terambil, meskipun model sudah disederhanakan
          final response = await supabase.from('vehicles').select('*').eq('id', widget.vehicle.id).single();
          if (mounted) {
              setState(() {
                  _currentVehicle = Vehicle.fromJson(response);
                  _initializeStaticParts(); // Update reminder setelah KM di-refresh
              });
          }
      } catch (e) {
          debugPrint('Failed to fetch updated vehicle data: $e');
      }
  }

  Future<void> _fetchServiceLogs() async {
    setState(() => _isLoadingLogs = true);
    try {
      final response = await supabase
          .from('service_logs')
          .select('*')
          .eq('vehicle_id', widget.vehicle.id)
          .order('date', ascending: false);
      
      final logs = response.map((data) => ServiceLog.fromJson(data)).toList();
      
      if (mounted) {
        setState(() {
          _serviceLogs = logs;
          _isLoadingLogs = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching service logs: $e');
      if (mounted) setState(() => _isLoadingLogs = false);
    }
  }

  void _confirmDeleteVehicle() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kendaraan'),
        content: Text('Apakah Anda yakin ingin menghapus ${_currentVehicle.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteVehicle();
            },
            child: const Text('HAPUS', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteVehicle() async {
    try {
      await supabase.from('vehicles').delete().eq('id', widget.vehicle.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_currentVehicle.name} berhasil dihapus.')));
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus kendaraan: ${e.toString()}')));
      }
    }
  }

  Future<void> _refreshData() async {
      await _fetchCurrentVehicle();
      await _fetchServiceLogs();
  }

  // --- WIDGET HELPER (Mengembalikan Tampilan Part Statis) ---

  IconData _getIconData(String iconName) {
      final name = iconName.toLowerCase();
      if (name.contains('oli') || name.contains('fuel')) return Icons.local_gas_station_outlined;
      if (name.contains('busi') || name.contains('filter') || name.contains('udara')) return Icons.ac_unit; 
      if (name.contains('transmisi') || name.contains('gardan')) return Icons.swap_vert;
      if (name.contains('ban') || name.contains('roda')) return Icons.circle_outlined;
      return Icons.settings_applications;
  }
  
  Widget _buildStaticReminderTile(BuildContext context, StaticPartReminder part) {
    final Color color = part.isOverdue ? Colors.red.shade700 : Colors.green.shade600;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 1,
      color: color.withAlpha((255 * 0.05).round()), 
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha((255 * 0.1).round()), 
          child: Icon(_getIconData(part.iconName), color: color, size: 20),
        ),
        title: Text(part.partName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Interval ${NumberFormat('#,##0').format(part.intervalKm)} KM'),
        trailing: Text(
          // Menampilkan 99,999 KM lagi jika intervalnya besar (untuk 'Lain-lain')
          part.intervalKm > 50000 
            ? '99,999+ KM lagi'
            : (part.isOverdue ? 'JATUH TEMPO!' : '${NumberFormat('#,##0').format(part.remainingKm)} KM lagi'),
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }

  Widget _buildServiceLogList() {
    if (_isLoadingLogs) return const Center(child: CircularProgressIndicator());
    if (_serviceLogs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('Belum ada riwayat servis tercatat.'),),);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _serviceLogs.length,
      itemBuilder: (context, index) {
        final log = _serviceLogs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            leading: Icon(Icons.history, color: Theme.of(context).primaryColor),
            title: Text(log.serviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              'KM: ${NumberFormat('#,##0').format(log.kmAtService)} | Biaya: Rp ${NumberFormat('#,##0').format(log.cost)}'
            ),
            trailing: Text(DateFormat('dd MMM yy').format(log.date)),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail ${_currentVehicle.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditPage, 
            tooltip: 'Edit Kendaraan',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: _confirmDeleteVehicle, 
            tooltip: 'Hapus Kendaraan',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- RINGKASAN KENDARAAN ---
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Plat: ${_currentVehicle.plateNumber}', style: Theme.of(context).textTheme.titleMedium),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('KM Saat Ini:', style: TextStyle(fontWeight: FontWeight.w300)),
                              Text('${NumberFormat('#,##0').format(_currentVehicle.currentKm)} KM', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Servis Terakhir:', style: TextStyle(fontWeight: FontWeight.w300)),
                              Text(DateFormat('dd MMM yyyy').format(_currentVehicle.lastServiceDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _navigateToAddLog,
                        icon: const Icon(Icons.add),
                        label: const Text('CATAT SERVIS BARU & UPDATE KM'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // --- REKOMENDASI PERAWATAN PART (6 KATEGORI STATIS) ---
              Text('Rekomendasi Servis (6 Kategori Statis)', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.blue.shade800)),
              const SizedBox(height: 10),
              
              Column(children: _staticPartReminders.map((part) => _buildStaticReminderTile(context, part)).toList()),

              const SizedBox(height: 20),
              
              // --- RIWAYAT SERVIS ---
              Text('Riwayat Servis', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black)),
              const SizedBox(height: 10),
              
              _buildServiceLogList(),
            ],
          ),
        ),
      ),
    );
  }
}