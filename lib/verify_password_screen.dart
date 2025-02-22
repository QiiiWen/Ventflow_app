import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_security_screen.dart';

class VerifyPasswordScreen extends StatefulWidget {
  final String userId;
  final String? userEmail;

  VerifyPasswordScreen({required this.userId, this.userEmail});

  @override
  _VerifyPasswordScreenState createState() => _VerifyPasswordScreenState();
}

class _VerifyPasswordScreenState extends State<VerifyPasswordScreen> {
  final supabase = Supabase.instance.client;
  TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? userEmail; // Store the actual email

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();
  }

  /// 🔄 **Fetch User Email from Supabase if Not Provided**
  Future<void> _fetchUserEmail() async {
    if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
      setState(() {
        userEmail = widget.userEmail;
      });
      return;
    }

    try {
      final user = supabase.auth.currentUser;
      if (user != null && user.email != null) {
        setState(() {
          userEmail = user.email!;
        });
      } else {
        setState(() {
          _errorMessage = "❌ Error: No email found for this account. Please log in again.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "❌ Error fetching email: ${e.toString()}";
      });
    }
  }

  /// 🔄 **Verify Password Using Supabase Auth**
  Future<void> _verifyPassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (userEmail == null || userEmail!.isEmpty) {
      setState(() {
        _errorMessage = "❌ No email found. Please log in again.";
        _isLoading = false;
      });
      return;
    }

    try {
      // ✅ Authenticate user with email and password
      final response = await supabase.auth.signInWithPassword(
        email: userEmail!,
        password: _passwordController.text,
      );

      if (response.user != null) {
        // ✅ Successfully authenticated, navigate to Login Security
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginSecurityScreen(userId: widget.userId),
          ),
        );
      } else {
        setState(() {
          _errorMessage = "❌ Invalid password. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "❌ Authentication error: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF040B41),
      appBar: AppBar(
        backgroundColor: Color(0xFF040B41),
        elevation: 0,
        title: Text("Login & Security", style: GoogleFonts.sen(fontSize: 20, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 50, color: Colors.white),
            SizedBox(height: 10),
            Text(
              "Enter your password to continue",
              style: GoogleFonts.sen(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 20),

            // 🔹 Email Display
            if (userEmail != null)
              Text(
                "Verifying for: $userEmail",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),

            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Password",
                labelStyle: TextStyle(color: Colors.white),
                filled: true,
                fillColor: Color(0xFF6850F6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_errorMessage!, style: TextStyle(color: Colors.red)),
              ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Back", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6850F6)),
                  onPressed: _isLoading ? null : _verifyPassword,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Continue", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
