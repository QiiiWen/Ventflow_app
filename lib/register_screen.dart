import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'dart:convert';


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

  bool _isLoading = false; // For showing loading indicator
  StreamSubscription? _sub; // For deep link handling


  @override
  void initState() {
    super.initState();
    _initDeepLinkListener(); // Start listening for deep links
  }

  void _initDeepLinkListener() {
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null && uri.host == "account_verified") {
        _showVerificationSuccessDialog();
      }
    });
  }

  Future<void> _registerUser() async {
    if (passwordController.text != confirmPasswordController.text) {
      _showMessage("Passwords do not match!", Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Use 10.0.2.2 for Android Emulator or PC Localhost IP for real devices
    String url = "http://10.0.2.2/ventflow_backend/register.php";

    try {
      var response = await http.post(
        Uri.parse(url),
        body: {
          "first_name": firstNameController.text,
          "last_name": lastNameController.text,
          "email": emailController.text,
          "password": passwordController.text,
        },
      );

      var jsonResponse = jsonDecode(response.body);

      if (jsonResponse["success"]) {
        // Show verification popup when registration is successful
        _showVerificationPopup(emailController.text);
      } else {
        _showMessage(jsonResponse["message"], Colors.red);
      }
    } catch (e) {
      _showMessage("Error: $e", Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showVerificationPopup(String email) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the modal to expand to full screen if necessary
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.6, // Adjusts the height of the modal to 80% of the screen height
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                      IconButton(
                        alignment: Alignment.centerLeft ,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20), // Adds horizontal padding to the text
                  child: Text(
                    "A verification link has been sent to $email.\nPlease check your spam folder if you haven't received it.",
                    textAlign: TextAlign.start,
                    style: GoogleFonts.sen(fontSize: 16, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showVerificationSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Account Verification"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 80),
              SizedBox(height: 10),
              Text("Account Verification Complete!"),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/login'); // Navigate to Login Page
              },
              child: Text("Let's Log In Now!"),
            ),
          ],
        );
      },
    );
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
                  style: GoogleFonts.sen(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Have a great full journey using this app!",
                  style: GoogleFonts.sen(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField("First Name", firstNameController),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField("Last Name", lastNameController),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                _buildTextField("Email", emailController),
                SizedBox(height: 15),
                _buildTextField("Set Password", passwordController, isPassword: true),
                SizedBox(height: 5),
                Text(
                  "please type password",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                SizedBox(height: 15),
                _buildTextField("Retype new-Password", confirmPasswordController, isPassword: true),
                SizedBox(height: 10),
                Text(
                  "*password must be at least 8 characters and include at least a number, symbol and a capital letter",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
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
                    child: Text(
                      "Agree & Continue",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Center(
                  child: Text(
                    "By clicking, I agree with Terms & Conditions, Service & Privacy Policy",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
