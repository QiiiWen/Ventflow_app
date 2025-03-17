import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter is ready

  // ✅ Initialize Supabase
  await Supabase.initialize(
    url: 'https://ropvyxordeaxskpwkqdo.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJvcHZ5eG9yZGVheHNrcHdrcWRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAwNDY3ODUsImV4cCI6MjA1NTYyMjc4NX0.9dq9wjZwTmkRGI-GqEHEWNTixAL3t7MgPNQVCLm4S6I',
  );

  // ✅ Initialize Stripe
  Stripe.publishableKey =
  "pk_test_51QJcjlCYiaR54l0AvFcUHwXuvMHLO6Anja1NXFSkplNWo3VHLxDukX11DXOvVD7iNUEFCIKdPr5fpN8IvlWdZgKn00SEpYHaWz";

  await initializeDateFormatting('en_US', null); // Initialize date formatting
  runApp(VentFlowApp());
}

class VentFlowApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // Start with the splash screen
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final Color firstColor = Color(0xFF040B41);
  final Color secondColor = Color(0xFF6850F6);

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(seconds: 3), () async {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    });
  }

  // ✅ Function to verify user email after clicking deep link
  Future<void> _verifyUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.emailConfirmedAt != null) {
      await Supabase.instance.client
          .from('users')
          .update({'verified': true})
          .eq('id', user.id);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("✅ Email verified! You can now log in."),
        backgroundColor: Colors.green,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.center,
            end: Alignment.bottomCenter,
            colors: [firstColor, secondColor],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "VentFlow",
                    style: GoogleFonts.sen(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Smart tool for business event management",
                    style: GoogleFonts.sen(
                      fontSize: 20,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),
            Image.network(
              'https://ropvyxordeaxskpwkqdo.supabase.co/storage/v1/object/public/assets//megaphone.png',
              width: 300,
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.image_not_supported, size: 100, color: Colors.grey);
              },
            ),
            SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 110, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Text(
                "GET STARTED >",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
