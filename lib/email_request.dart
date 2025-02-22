import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;
  final supabase = Supabase.instance.client;

  // ✅ Send 6-Digit OTP Using Supabase Auth
  Future<void> sendResetOTP() async {
    setState(() => isLoading = true);

    try {
      final String email = emailController.text.trim();

      // ✅ Supabase Automatically Sends 6-Digit OTP
      await supabase.auth.signInWithOtp(email: email);

      // ✅ Navigate to OTP Verification Screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OTPVerificationScreen(email: email)),
      );

      _showMessage("OTP sent to your email", Colors.green);
    } catch (error) {
      _showMessage("Failed to send OTP: $error", Colors.red);
    }

    setState(() => isLoading = false);
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reset Password', style: GoogleFonts.sen(color: Colors.white)), backgroundColor: Color(0xFF6850F6)),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6850F6), Color(0xFF040B41)],
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Reset Password", style: GoogleFonts.sen(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 20),
            TextField(
              controller: emailController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: "Email Address", labelStyle: TextStyle(color: Colors.white70), filled: true, fillColor: Colors.white24, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            ),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: sendResetOTP,
              child: Text('Send OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
