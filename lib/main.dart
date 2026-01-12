// lib/main.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
// ... Import pages dan models lainnya (pastikan semua path ini benar)
import 'package:project_motoproper/pages/home_page.dart';
import 'package:project_motoproper/pages/login_page.dart';
import 'package:project_motoproper/pages/register_page.dart'; 
import 'package:project_motoproper/pages/profile_management_page.dart';
import 'package:project_motoproper/pages/vehicle_detail_page.dart'; 
import 'package:project_motoproper/pages/add_vehicle_page.dart';
import 'package:project_motoproper/pages/edit_vehicle_page.dart';
import 'package:project_motoproper/pages/add_service_log_page.dart';
import 'package:project_motoproper/pages/initial_service_entry_page.dart'; 
import 'package:project_motoproper/pages/manage_service_types_page.dart'; 
import 'package:project_motoproper/pages/password_recovery_page.dart';
import 'package:project_motoproper/models/vehicle_model.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  String? initError;
  bool isLoggedIn = false;
  
  try {
      await dotenv.load(fileName: "supabase.env"); 

      final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      
      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
          throw Exception("SUPABASE_URL atau SUPABASE_ANON_KEY tidak ditemukan/kosong di file .env. Pastikan file terdaftar di pubspec.yaml.");
      }

      await Supabase.initialize(
        url: supabaseUrl, 
        anonKey: supabaseAnonKey,
      );

      final prefs = await SharedPreferences.getInstance();
      
      // Akses Supabase Client untuk pengecekan user saat ini
      final supabaseClient = Supabase.instance.client;
      isLoggedIn = supabaseClient.auth.currentUser != null || (prefs.getBool('is_logged_in') ?? false);
      
  } catch (e) {
      initError = e.toString();
  }
  
  runApp(MyApp(isLoggedIn: isLoggedIn, initError: initError));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn; 
  final String? initError; 

  const MyApp({super.key, required this.isLoggedIn, this.initError}); 
  
  @override
  Widget build(BuildContext context) {
    if (initError != null) {
      // ... (Bagian Error Handling tetap sama)
      return MaterialApp(
        title: 'MotoProper Error',
        home: Scaffold(
          appBar: AppBar(title: const Text('Initialization Error')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  const SizedBox(height: 20),
                  const Text('Aplikasi gagal memuat karena error konfigurasi Supabase/ENV.', 
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text('Detail Error: $initError', textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  const Text('Pastikan file supabase.env ada di root project dan kunci SUPABASE_URL & SUPABASE_ANON_KEY sudah terisi dengan benar.'),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return MaterialApp(
      title: 'MotoProper',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/profile_management': (context) => const ProfileManagementPage(),
        '/add_vehicle': (context) => const AddVehiclePage(),
        '/manage_services': (context) => const ManageServiceTypesPage(),
        '/password_recovery': (context) => const PasswordRecoveryPage(),

        '/edit_vehicle': (context) {
          final vehicle = ModalRoute.of(context)!.settings.arguments as Vehicle; 
          return EditVehiclePage(vehicle: vehicle);
        },
        '/add_log': (context) {
          final vehicle = ModalRoute.of(context)!.settings.arguments as Vehicle;
          return AddServiceLogPage(vehicle: vehicle);
        },
        '/detail': (context) {
          final vehicle = ModalRoute.of(context)!.settings.arguments as Vehicle;
          return VehicleDetailPage(vehicle: vehicle);
        },
        '/initial_service': (context) {
          final vehicle = ModalRoute.of(context)!.settings.arguments as Vehicle;
          return InitialServiceEntryPage(vehicle: vehicle);
        },
      },
    );
  }
}