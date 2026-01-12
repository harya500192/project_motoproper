// lib/pages/add_vehicle_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final supabase = Supabase.instance.client;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();
  final TextEditingController _currentKmController = TextEditingController(text: '0');
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _plateNumberController.dispose();
    _currentKmController.dispose();
    super.dispose();
  }
  
  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Pengguna tidak terautentikasi.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final vehicleData = {
        'user_id': currentUserId,
        'name': _nameController.text.trim(),
        'plate_number': _plateNumberController.text.trim(),
        'current_km': int.tryParse(_currentKmController.text) ?? 0,
        
        // --- PERBAIKAN SCHEMA DB ---
        // 1. Hapus key 'model' (Error 3)
        // 2. Hapus key 'created_at' (Error 2)
        
        // 3. Mengganti 'general' dengan UUID valid (Error 4)
        'daily_usage': 0, 
        'vehicle_type_id': '00000000-0000-0000-0000-000000000000', 
      };
      
      await supabase.from('vehicles').insert(vehicleData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kendaraan berhasil ditambahkan!')));
        Navigator.pop(context, true); 
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan kendaraan: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan tak terduga: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Kendaraan Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. Nama Kendaraan ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Panggilan Kendaraan', prefixIcon: Icon(Icons.motorcycle)),
                validator: (value) => (value == null || value.isEmpty) ? 'Nama wajib diisi.' : null,
              ),
              const SizedBox(height: 16),
              
              // --- 2. Plat Nomor ---
              TextFormField(
                controller: _plateNumberController,
                decoration: const InputDecoration(labelText: 'Plat Nomor', prefixIcon: Icon(Icons.credit_card)),
                validator: (value) => (value == null || value.isEmpty) ? 'Plat Nomor wajib diisi.' : null,
              ),
              const SizedBox(height: 16),
              
              // --- 3. KM Saat Ini ---
              TextFormField(
                controller: _currentKmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'KM Saat Ini', prefixIcon: Icon(Icons.speed)),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'KM wajib diisi.';
                  if (int.tryParse(value) == null) return 'KM harus berupa angka.';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // --- Tombol Simpan ---
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _saveVehicle,
                      icon: const Icon(Icons.save),
                      label: const Text('SIMPAN KENDARAAN'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}