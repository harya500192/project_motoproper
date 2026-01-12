// lib/pages/manage_service_types_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:project_motoproper/models/service_type_model.dart';

class ManageServiceTypesPage extends StatefulWidget {
  const ManageServiceTypesPage({super.key});

  @override
  State<ManageServiceTypesPage> createState() => _ManageServiceTypesPageState();
}

class _ManageServiceTypesPageState extends State<ManageServiceTypesPage> {
  final supabase = Supabase.instance.client;
  List<ServiceType> _serviceTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServiceTypes();
  }

  Future<void> _fetchServiceTypes() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('service_types')
          .select()
          .order('name', ascending: true);
      
      _serviceTypes = response.map((data) => ServiceType.fromJson(data)).toList(); 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat tipe servis: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteServiceType(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tipe Servis'),
        content: const Text('Apakah Anda yakin ingin menghapus tipe servis ini? Aksi ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await supabase.from('service_types').delete().eq('id', id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tipe servis berhasil dihapus.')));
        }
        _fetchServiceTypes(); 
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddEditDialog({ServiceType? serviceType}) {
    final isEditing = serviceType != null;
    final nameController = TextEditingController(text: serviceType?.name);
    final kmController = TextEditingController(text: serviceType?.frequencyKm.toString());
    final monthsController = TextEditingController(text: serviceType?.frequencyMonths.toString());
    final costController = TextEditingController(text: serviceType?.defaultCost.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Tipe Servis' : 'Tambah Tipe Servis'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Servis'),
                  validator: (value) => value == null || value.isEmpty ? 'Nama wajib diisi.' : null,
                ),
                TextFormField(
                  controller: kmController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Interval KM (Contoh: 3000)'),
                  validator: (value) => value == null || int.tryParse(value) == null ? 'KM wajib diisi dengan angka.' : null,
                ),
                TextFormField(
                  controller: monthsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Interval Bulan (Contoh: 3)'),
                  validator: (value) => value == null || int.tryParse(value) == null ? 'Bulan wajib diisi dengan angka.' : null,
                ),
                TextFormField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Biaya Default (Rp)'),
                  validator: (value) => value == null || double.tryParse(value) == null ? 'Biaya wajib diisi dengan angka.' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                _saveServiceType(
                  id: serviceType?.id,
                  name: nameController.text.trim(),
                  km: int.parse(kmController.text),
                  months: int.parse(monthsController.text),
                  cost: double.parse(costController.text),
                );
              }
            },
            child: Text(isEditing ? 'SIMPAN' : 'TAMBAH'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveServiceType({
    String? id,
    required String name,
    required int km,
    required int months,
    required double cost,
  }) async {
    setState(() => _isLoading = true);
    final data = {
      'name': name,
      'frequency_km': km,
      'frequency_months': months,
      'default_cost': cost,
    };

    try {
      if (id == null) {
        await supabase.from('service_types').insert(data);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tipe servis berhasil ditambahkan.')));
      } else {
        await supabase.from('service_types').update(data).eq('id', id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tipe servis berhasil diperbarui.')));
      }
      _fetchServiceTypes();
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi kesalahan yang tidak terduga.')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Tipe Servis'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _serviceTypes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Belum ada tipe servis. Tambahkan satu untuk memulai.'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAddEditDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Tipe Servis'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _serviceTypes.length,
                  itemBuilder: (context, index) {
                    final type = _serviceTypes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(type.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Interval: ${NumberFormat('#,##0').format(type.frequencyKm)} KM atau ${type.frequencyMonths} Bulan\nBiaya Default: Rp ${NumberFormat('#,##0').format(type.defaultCost)}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAddEditDialog(serviceType: type),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteServiceType(type.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _serviceTypes.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditDialog(),
              label: const Text('Tambah Tipe'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }
}