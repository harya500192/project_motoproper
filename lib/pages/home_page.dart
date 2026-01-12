// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:project_motoproper/models/vehicle_model.dart';
import 'package:project_motoproper/pages/add_vehicle_page.dart';
import 'package:project_motoproper/pages/vehicle_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _userName = 'Pengguna'; 

  @override
  void initState() {
    super.initState();
    _fetchUserDataAndVehicles();
  }

  // --- LOGIKA FETCH DATA ---
  Future<void> _fetchUserDataAndVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User ID tidak ditemukan. Sesi berakhir.");
      
      // 1. Ambil Nama Pengguna (Dengan Fallback ke Email)
      try {
        final res = await supabase.from('profiles').select('username').eq('id', user.id).single();
        _userName = res['username'] ?? user.email?.split('@').first ?? 'Pengguna';
      } catch (e) {
        // Jika gagal (seperti error tabel profiles), gunakan bagian email sebagai nama.
        _userName = user.email?.split('@').first ?? 'Pengguna';
      }

      // 2. Ambil Daftar Kendaraan
      final vehicleResponse = await supabase
          .from('vehicles')
          .select('*')
          .eq('user_id', user.id)
          .order('name', ascending: true);

      final vehicles = vehicleResponse.map((data) => Vehicle.fromJson(data)).toList();
      
      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _isLoading = false;
        });
      }

    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'DB Error: ${e.message}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }
  
  // --- NAVIGASI & LOGOUT ---
  void _navigateToDetail(Vehicle vehicle) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailPage(vehicle: vehicle)));
    if (result == true) _fetchUserDataAndVehicles();
  }

  void _navigateToAdd() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddVehiclePage()));
    if (result == true) _fetchUserDataAndVehicles();
  }
  
  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal Logout: ${e.toString()}')));
    }
  }
  
  // --- WIDGET KARTU KENDARAAN (RINGKAS) ---
  Widget _buildVehicleCard(Vehicle vehicle) {
    const int serviceIntervalMonths = 6; 
    final bool isOverdueDate = DateTime.now().difference(vehicle.lastServiceDate).inDays > (30 * serviceIntervalMonths); 
    final bool isDue = isOverdueDate;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDue ? const BorderSide(color: Colors.redAccent, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(vehicle),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      vehicle.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(isDue ? Icons.warning : Icons.check_circle_outline, color: isDue ? Colors.red : Colors.green),
                ],
              ),
              const SizedBox(height: 4),
              Text('Plat: ${vehicle.plateNumber}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('KM: ${NumberFormat('#,##0').format(vehicle.currentKm)} KM', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('Servis Terakhir: ${DateFormat('dd MMM yy').format(vehicle.lastServiceDate)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              if (isDue) Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('⚠️ PERLU SERVIS (>$serviceIntervalMonths bulan)!', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- BUILD METHOD UTAMA ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MotoProper - Hi, $_userName'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchUserDataAndVehicles, tooltip: 'Muat Ulang'),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Keluar'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUserDataAndVehicles,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Total Kendaraan
              Card(
                color: Colors.blue.shade50,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Total Kendaraan Anda: ${_vehicles.length} Unit', 
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                ),
              ),
              const SizedBox(height: 20),

              // Konten Dinamis (Loading, Error, Empty, List)
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? _buildErrorWidget(context)
                        : _vehicles.isEmpty
                            ? _buildEmptyWidget()
                            : ListView.builder(
                                padding: const EdgeInsets.only(top: 10),
                                itemCount: _vehicles.length,
                                itemBuilder: (context, index) => _buildVehicleCard(_vehicles[index]),
                              ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _isLoading || _vehicles.isEmpty 
          ? null 
          : FloatingActionButton.extended(onPressed: _navigateToAdd, icon: const Icon(Icons.add), label: const Text('Tambah Kendaraan')),
    );
  }

  // --- WIDGET PEMBANTU ---
  Widget _buildErrorWidget(BuildContext context) {
    final bool isJwtExpired = _errorMessage!.contains('JWT expired'); // Cek error JWT
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: isJwtExpired ? Colors.orange : Colors.red, size: 50),
          const SizedBox(height: 10),
          Text(_errorMessage!, textAlign: TextAlign.center),
          if (isJwtExpired)
             const Padding(
               padding: EdgeInsets.all(8.0),
               child: Text('Sesi kedaluwarsa. Silakan Logout & Login kembali.', textAlign: TextAlign.center, style: TextStyle(color: Colors.orange)),
             ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _fetchUserDataAndVehicles,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Muat Ulang'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_bike, size: 50, color: Colors.grey),
          const SizedBox(height: 10),
          const Text('Belum ada kendaraan terdaftar.', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton.icon(onPressed: _navigateToAdd, icon: const Icon(Icons.add), label: const Text('TAMBAH KENDARAAN PERTAMA')),
        ],
      ),
    );
  }
}