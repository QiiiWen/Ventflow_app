import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  // ✅ Register a new user & auto-create profile
  Future<void> _registerUser() async {
    if (passwordController.text != confirmPasswordController.text) {
      _showMessage("Passwords do not match!", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Sign up user (Supabase will send a verification email automatically)
      final response = await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (response.user == null) {
        throw "Registration failed. Try again.";
      }

      final userId = response.user!.id; // 🔹 Get the user ID

      // ✅ Insert user data into `users` table
      await supabase.from('users').upsert({
        'id': userId,
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'email': emailController.text.trim(),
        'role': 'attendee', // Default role
        'verified': false, // Mark as unverified
      });

      // ✅ Create an empty profile for the user in `user_profiles`
      await supabase.from('user_profiles').upsert({
        'user_id': userId,
        'username': emailController.text.split('@')[0], // Default username
        'profile_pic': '', // Empty profile pic
        'location': '',
        'bio': '',
        'followers': 0,
        'following': 0,
        'created_at': DateTime.now().toIso8601String(),
        'is_private': false,
        'visible_to_public': true,
      });

      // ✅ Show verification popup
      _showVerificationPopup(emailController.text);
    } catch (error) {
      _showMessage(error.toString(), Colors.red);
    }

    setState(() => _isLoading = false);
  }

  // ✅ Show verification popup
  void _showVerificationPopup(String email) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.6,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  alignment: Alignment.centerLeft,
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(height: 20),
                Text(
                  "Account Verification",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sen(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.mail_outline, size: 100, color: Colors.black),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "A verification link has been sent to $email.\nPlease check your spam folder if you haven't received it.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sen(fontSize: 16, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // ✅ Auto-redirect to LoginScreen after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });
  }

  // ✅ Show message (error or success)
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
            colors: [Color(0xFF6B48FF), Color(0xFF0B0B42)],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                SizedBox(height: 10),
                Text(
                  "Register an\nAccount",
                  style: GoogleFonts.sen(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildTextField("First Name", firstNameController)),
                    SizedBox(width: 10),
                    Expanded(child: _buildTextField("Last Name", lastNameController)),
                  ],
                ),
                SizedBox(height: 15),
                _buildTextField("Email", emailController),
                SizedBox(height: 15),
                _buildTextField("Set Password", passwordController, isPassword: true),
                SizedBox(height: 15),
                _buildTextField("Retype Password", confirmPasswordController, isPassword: true),
                SizedBox(height: 20),
                Center(
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _registerUser,
                    child: Text("Agree & Continue", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white24,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
