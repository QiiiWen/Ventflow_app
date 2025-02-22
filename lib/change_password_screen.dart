import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String email;
  ChangePasswordScreen({required this.email});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  final supabase = Supabase.instance.client;

  // ✅ Change password using Supabase
  Future<void> changePassword() async {
    if (passwordController.text.isEmpty || confirmPasswordController.text.isEmpty) {
      _showMessage("Please enter both fields", Colors.red);
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showMessage("Passwords do not match", Colors.red);
      return;
    }

    setState(() => isLoading = true);

    try {
      // ✅ Update password in Supabase
      await supabase.auth.updateUser(
        UserAttributes(password: passwordController.text.trim()),
      );

      _showMessage("Password changed successfully!", Colors.green);

      // ✅ Navigate to Login Screen after successful password reset
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    } catch (error) {
      _showMessage("Error: $error", Colors.red);
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 60),
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              SizedBox(height: 20),
              Text("Change Password", style: GoogleFonts.sen(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("Enter your new password below", style: GoogleFonts.sen(fontSize: 16, color: Colors.white70)),
              SizedBox(height: 30),

              // Password Input
              Text("New Password", style: GoogleFonts.sen(color: Colors.white70, fontSize: 16)),
              SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                    onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Confirm Password Input
              Text("Confirm Password", style: GoogleFonts.sen(color: Colors.white70, fontSize: 16)),
              SizedBox(height: 10),
              TextField(
                controller: confirmPasswordController,
                obscureText: !isConfirmPasswordVisible,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: Icon(isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                    onPressed: () => setState(() => isConfirmPasswordVisible = !isConfirmPasswordVisible),
                  ),
                ),
              ),
              SizedBox(height: 30),

              // Submit Button
              Center(
                child: ElevatedButton(
                  onPressed: isLoading ? null : changePassword,
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Confirm", style: GoogleFonts.sen(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
