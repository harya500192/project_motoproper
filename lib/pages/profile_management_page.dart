// lib/pages/profile_management_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileManagementPage extends StatefulWidget {
  const ProfileManagementPage({super.key});

  @override
  State<ProfileManagementPage> createState() => _ProfileManagementPageState();
}

class _ProfileManagementPageState extends State<ProfileManagementPage> {
  final supabase = Supabase.instance.client; 
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _currentUserId; 
  bool _isLoading = false; 

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); 
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  
  Future<void> _logout() async {
    await supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance(); 
    await prefs.setBool('is_logged_in', false);
    
    if (mounted) { 
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false); 
    }
  }
  
  Future<void> _loadUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      _currentUserId = user.id; 
      _nameController.text = user.userMetadata?['user_name'] ?? '';
      _emailController.text = user.email ?? '';
    } else {
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true); 

    try {
      await supabase.auth.updateUser(
        UserAttributes( 
          data: {'user_name': _nameController.text.trim()},
        ),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui!')));
        // Navigator.pop(context, true); // Tidak perlu pop jika mau tetap di halaman profil
      }
    } on AuthException catch (e) { 
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal Update: ${e.message}'))); }
    } catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi kesalahan saat update profil.'))); }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan & Profil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Ubah Informasi Dasar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const Divider(),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Pengguna'),
                validator: (value) => (value == null || value.isEmpty) ? 'Nama wajib diisi.' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                readOnly: true, 
                decoration: const InputDecoration(
                  labelText: 'Email (Tidak dapat diubah)',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _updateProfile, 
                      icon: const Icon(Icons.save),
                      label: const Text('SIMPAN PERUBAHAN PROFIL'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    ),
              
              const SizedBox(height: 50),
              
              const Text('Aksi Akun', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const Divider(),
              
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, color: Colors.blue),
                title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _logout, 
              ),
              
              const Divider(),
              
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}