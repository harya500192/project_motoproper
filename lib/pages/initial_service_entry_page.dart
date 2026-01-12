// lib/pages/initial_service_entry_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:project_motoproper/models/vehicle_model.dart';
import 'package:project_motoproper/pages/vehicle_detail_page.dart';

// Helper class yang sama dengan AddServiceLogPage
class ServicePartDraft {
  final TextEditingController partNameController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  final TextEditingController kmDueController = TextEditingController();
  final TextEditingController kmLastServiceController = TextEditingController(); // TAMBAHAN: KM Terakhir Servis

  ServicePartDraft({String initialKm = '0'}) {
    kmLastServiceController.text = initialKm;
    costController.text = '0'; // Biaya default 0
  }

  void dispose() {
    partNameController.dispose();
    costController.dispose();
    kmDueController.dispose();
    kmLastServiceController.dispose();
  }
}

class InitialServiceEntryPage extends StatefulWidget {
  final Vehicle vehicle;
  const InitialServiceEntryPage({super.key, required this.vehicle});

  @override
  State<InitialServiceEntryPage> createState() => _InitialServiceEntryPageState();
}

class _InitialServiceEntryPageState extends State<InitialServiceEntryPage> {
  final supabase = Supabase.instance.client;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _notesController = TextEditingController();
  
  bool _isLoading = false;

  // Daftar Parts yang akan disimpan (hanya parts yang memiliki data KM > 0 akan disimpan)
  List<ServicePartDraft> _partsDraft = [];

  @override
  void initState() {
    super.initState();
    // Inisialisasi daftar parts standar (sesuai Gambar 14f3c8.png)
    _initializeStandardParts();
  }

  void _initializeStandardParts() {
    _partsDraft.add(ServicePartDraft()..partNameController.text = 'Oli Mesin & Filter');
    _partsDraft.add(ServicePartDraft()..partNameController.text = 'Busi & Filter Udara');
    _partsDraft.add(ServicePartDraft()..partNameController.text = 'Oli Transmisi/Gardan');
    _partsDraft.add(ServicePartDraft()..partNameController.text = 'Ban');
  }

  // Fungsi untuk menambah entri bagian baru (Opsional)
  void _addCustomPartDraft() {
    setState(() {
      _partsDraft.add(ServicePartDraft());
    });
  }

  // Fungsi untuk menghapus entri bagian
  void _removePartDraft(int index) {
    setState(() {
      _partsDraft.removeAt(index);
    });
  }

  Future<void> _saveInitialService() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final int currentKm = widget.vehicle.currentKm;
    
    // Filter parts yang KM terakhir servisnya valid (> 0)
    final List<ServicePartDraft> validParts = _partsDraft.where((draft) {
      final km = int.tryParse(draft.kmLastServiceController.text) ?? 0;
      return km > 0;
    }).toList();
    
    // Jika tidak ada parts yang dimasukkan, hanya simpan catatan dan lewati
    if (validParts.isEmpty && _notesController.text.trim().isEmpty) {
        if (mounted) {
            _navigateToDetail(context);
        }
        return;
    }
    
    try {
      // 1. Masukkan Log Servis Awal (Log Utama)
      // Kita buat satu log utama untuk menampung semua data awal ini
      final logData = {
        'vehicle_id': widget.vehicle.id,
        'km_at_service': currentKm, // KM saat ini adalah KM log awal
        'service_name': 'Pencatatan Servis Awal Kendaraan',
        'date': DateTime.now().toIso8601String(),
        'cost': 0, // Biaya 0 karena ini hanya pencatatan riwayat
        'notes': 'Log ini mencatat KM terakhir servis komponen utama sebelum fitur pengingat diaktifkan. ' + _notesController.text.trim(),
      };
      
      final response = await supabase.from('service_logs').insert(logData).select('id');
      final newLogId = response.first['id'] as String;

      // 2. Masukkan Detail Parts/Komponen
      final List<Map<String, dynamic>> partsToInsert = validParts.map((draft) {
        // Logika KM Servis Berikutnya (asumsi: Oli 3k, Busi/Filter 6k, Ban 15k, Gardan 8k)
        int kmDueOffset = 0;
        final partName = draft.partNameController.text;
        
        if (partName.contains('Oli Mesin')) kmDueOffset = 3000;
        else if (partName.contains('Busi') || partName.contains('Filter Udara')) kmDueOffset = 6000;
        else if (partName.contains('Oli Transmisi') || partName.contains('Gardan')) kmDueOffset = 8000;
        else if (partName.contains('Ban')) kmDueOffset = 15000;
        else if (int.tryParse(draft.kmDueController.text) != null) kmDueOffset = int.parse(draft.kmDueController.text);
        
        final kmLastService = int.parse(draft.kmLastServiceController.text);
        final kmNextDue = kmLastService + kmDueOffset;

        return {
          'log_id': newLogId,
          'part_name': draft.partNameController.text.trim(),
          'cost': 0, // Biaya 0 karena ini riwayat
          'km_next_due': kmNextDue,
        };
      }).toList();
      
      if (partsToInsert.isNotEmpty) {
          await supabase.from('service_parts').insert(partsToInsert);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Data servis awal berhasil dicatat!'),
          backgroundColor: Colors.green,
        ));
        _navigateToDetail(context);
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan log servis: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan yang tidak terduga: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _navigateToDetail(BuildContext context) {
      // Ganti ke halaman detail kendaraan yang baru
      Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => VehicleDetailPage(vehicle: widget.vehicle))
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servis Awal Kendaraan'),
        automaticallyImplyLeading: false, 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.vehicle.name} (${widget.vehicle.plateNumber}) - KM Saat Ini: ${widget.vehicle.currentKm} KM',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.blue.shade700),
              ),
              const SizedBox(height: 10),
              const Text(
                'Masukkan KM terakhir Anda mengganti/servis bagian di bawah ini. Jika belum pernah, biarkan 0 atau kosong.',
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
              const Divider(),
              const SizedBox(height: 10),

              // --- FORM DETAIL PARTS/KOMPONEN ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Riwayat Servis Part', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: _addCustomPartDraft,
                    tooltip: 'Tambah Bagian Servis Kustom',
                  ),
                ],
              ),
              const Divider(),

              ...List.generate(_partsDraft.length, (index) {
                final draft = _partsDraft[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Jika ini part standar, tidak bisa dihapus, jika kustom bisa.
                              Text('Part: ${draft.partNameController.text.isNotEmpty ? draft.partNameController.text : 'Part Kustom'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (index >= 4) // Anggap 4 item pertama adalah standar
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removePartDraft(index),
                                ),
                            ],
                          ),
                          if (index >= 4) // Hanya part kustom yang bisa diedit namanya
                            TextFormField(
                              controller: draft.partNameController,
                              decoration: const InputDecoration(labelText: 'Nama Bagian Kustom'),
                              validator: (value) => (value == null || value.isEmpty) ? 'Wajib diisi.' : null,
                            ),
                          
                          TextFormField(
                            controller: draft.kmLastServiceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'KM Terakhir Servis/Ganti',
                              prefixIcon: Icon(Icons.access_time),
                              helperText: 'Masukkan 0 jika belum pernah diganti.'
                            ),
                            validator: (value) {
                              final km = int.tryParse(value ?? '');
                              if (km == null || km < 0 || km > widget.vehicle.currentKm) {
                                return 'KM harus antara 0 dan KM saat ini (${widget.vehicle.currentKm}).';
                              }
                              return null;
                            },
                          ),
                          
                          // Input opsional untuk KM servis berikutnya (hanya untuk part kustom)
                          if (index >= 4)
                            TextFormField(
                              controller: draft.kmDueController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Jarak KM Servis Berikutnya (Ex: 5000 KM)',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan Tambahan (Opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _saveInitialService,
                      icon: const Icon(Icons.save),
                      label: const Text('SELESAI & LANJUTKAN KE DETAIL KENDARAAN'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => _navigateToDetail(context),
                child: const Text('Lewati (Asumsi Semua Part Belum Pernah Servis)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}