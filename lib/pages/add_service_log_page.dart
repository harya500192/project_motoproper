// lib/pages/add_service_log_page.dart (Versi Dropdown Part Statis)

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_motoproper/models/vehicle_model.dart';
import 'package:intl/intl.dart'; 

class AddServiceLogPage extends StatefulWidget {
  final Vehicle vehicle;
  const AddServiceLogPage({super.key, required this.vehicle});

  @override
  State<AddServiceLogPage> createState() => _AddServiceLogPageState();
}

class _AddServiceLogPageState extends State<AddServiceLogPage> {
  final supabase = Supabase.instance.client;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _kmController = TextEditingController();
  final TextEditingController _costController = TextEditingController(text: '0'); 
  final TextEditingController _notesController = TextEditingController();
  
  bool _isLoading = false;
  
  // Daftar pilihan part/servis statis
  final List<String> _serviceOptions = [
    'Servis Rutin Lengkap',
    'Ganti Oli Mesin & Filter',
    'Oli Transmisi/Gardan',
    'Busi & Filter Udara',
    'Ganti Ban',
    'Lain-lain',
  ];
  
  String? _selectedServiceName; // State untuk Dropdown

  @override
  void initState() {
    super.initState();
    _kmController.text = (widget.vehicle.currentKm + 1).toString();
    // Inisiasi pilihan pertama sebagai default
    _selectedServiceName = _serviceOptions.first;
  }

  @override
  void dispose() {
    _kmController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _saveServiceLog() async {
    if (!_formKey.currentState!.validate() || _selectedServiceName == null) return;
    
    final newKm = int.tryParse(_kmController.text) ?? 0;
    final costToSave = int.tryParse(_costController.text) ?? 0;

    setState(() => _isLoading = true);

    try {
      // 1. Masukkan Log Servis
      final logData = {
        'vehicle_id': widget.vehicle.id,
        'km_at_service': newKm,
        'service_name': _selectedServiceName!, // Menggunakan pilihan dari dropdown
        'date': DateTime.now().toIso8601String(), 
        'cost': costToSave, 
        'notes': _notesController.text.trim(), 
      };
      await supabase.from('service_logs').insert(logData);
      
      // 2. Update KM Kendaraan
      await supabase.from('vehicles').update({
        'current_km': newKm,
        'last_service_date': DateTime.now().toIso8601String(),
      }).eq('id', widget.vehicle.id);
      
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log Servis berhasil ditambahkan!')));
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')));
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
      appBar: AppBar(title: Text('Catat Servis ${widget.vehicle.name}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. KM Servis
              TextFormField(
                controller: _kmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'KM Setelah Servis', prefixIcon: Icon(Icons.speed)),
                validator: (value) {
                  final km = int.tryParse(value ?? '');
                  if (km == null || km < widget.vehicle.currentKm) {
                    return 'KM harus sama atau lebih besar dari KM saat ini (${NumberFormat('#,##0').format(widget.vehicle.currentKm)}).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 2. Jenis Servis (DROPDOWN BARU)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Jenis Servis', prefixIcon: Icon(Icons.settings)),
                value: _selectedServiceName,
                items: _serviceOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedServiceName = newValue;
                  });
                },
                validator: (value) => (value == null || value.isEmpty) ? 'Jenis servis wajib dipilih.' : null,
              ),
              const SizedBox(height: 16),
              
              // 3. Biaya
              TextFormField(
                controller: _costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Biaya Servis (Rp)', prefixIcon: Icon(Icons.money)),
              ),
              const SizedBox(height: 24),
              
              // 4. Catatan
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Catatan (Opsional)', prefixIcon: Icon(Icons.edit_note)),
              ),
              const SizedBox(height: 24),
              
              // Tombol Simpan
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _saveServiceLog,
                      icon: const Icon(Icons.check),
                      label: const Text('SIMPAN LOG SERVIS'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}