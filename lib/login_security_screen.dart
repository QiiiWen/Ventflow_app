import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginSecurityScreen extends StatefulWidget {
  final String userId;

  LoginSecurityScreen({required this.userId});

  @override
  _LoginSecurityScreenState createState() => _LoginSecurityScreenState();
}

class _LoginSecurityScreenState extends State<LoginSecurityScreen> {
  final supabase = Supabase.instance.client;

  TextEditingController _oldPasswordController = TextEditingController();
  TextEditingController _newPasswordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  /// 🔄 **Update Password Using Supabase**
  Future<void> _updatePassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = "New password and confirm password do not match.";
        _isLoading = false;
      });
      return;
    }

    try {
      // **Retrieve the current user's email**
      final user = supabase.auth.currentUser;
      if (user == null || user.email == null) {
        setState(() {
          _errorMessage = "❌ No email found for this account. Please log in again.";
        });
        return;
      }

      await supabase.auth.updateUser(
        UserAttributes(
          email: user.email!, // Ensure email is passed
          password: _newPasswordController.text,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Password updated successfully!")),
      );

      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      setState(() {
        _errorMessage = "❌ Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  /// 🚨 **Delete Account Using Supabase**
  Future<void> _deleteAccount() async {
    try {
      await supabase.auth.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Account logged out successfully!")),
      );

      Navigator.pop(context); // Navigate back
    } catch (e) {
      setState(() {
        _errorMessage = "❌ Error logging out: ${e.toString()}";
      });
    }

  }

  /// 🛑 **Show Delete Account Confirmation Dialog**
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Account"),
        content: Text("Are you sure you want to delete your account? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Color(0xFF6850F6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabeledTextField("New Password", _newPasswordController, obscureText: true),
                      SizedBox(height: 15),
                      _buildLabeledTextField("Confirm New Password", _confirmPasswordController, obscureText: true),

                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(_errorMessage!, style: TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                ),
              ),

              // 🔄 **Update Password Button**
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 100, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isLoading ? null : _updatePassword,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Update Password", style: TextStyle(color: Colors.white)),
                ),
              ),
              SizedBox(height: 20),

              // 🚨 **Delete Account Button**
              Center(
                child: TextButton(
                  onPressed: _showDeleteAccountDialog,
                  child: Text(
                    "Delete Account",
                    style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// **🔹 Reusable Labeled Text Field Widget**
  Widget _buildLabeledTextField(String label, TextEditingController controller, {bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.sen(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white24,
            contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
