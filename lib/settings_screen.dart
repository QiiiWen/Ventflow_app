import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile_screen.dart';
import 'help_center_screen.dart';
import 'privacy_settings_screen.dart';
import 'login_security_screen.dart';
import 'login_screen.dart';
import 'verify_password_screen.dart';

class SettingsScreen extends StatelessWidget {
  final String userId;
  final String userEmail;

  SettingsScreen({required this.userId, required this.userEmail});

  final supabase = Supabase.instance.client;

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await supabase.auth.signOut();

      // Navigate to Login Screen and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false, // Removes all previous screens
      );
    } catch (error) {
      print("❌ Error logging out: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF040B41),
      appBar: AppBar(
        backgroundColor: Color(0xFF040B41),
        elevation: 0,
        title: Text("Settings", style: GoogleFonts.sen(fontSize: 20, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFF6850F6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 20),
                children: [
                  _buildSettingsOption(
                    context,
                    icon: Icons.edit,
                    title: "Edit Profile",
                    onTap: () => _navigateTo(context, EditProfileScreen(userId: userId)),
                  ),
                  _buildSettingsOption(
                    context,
                    icon: Icons.lock,
                    title: "Login & Security",
                    onTap: () async {
                      final user = supabase.auth.currentUser;
                      if (user == null || user.email == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("❌ No email found. Please log in again.")),
                        );
                        return;
                      }

                      _navigateTo(
                        context,
                        VerifyPasswordScreen(userId: user.id, userEmail: user.email!),
                      );
                    },
                  ),
                  _buildSettingsOption(
                    context,
                    icon: Icons.privacy_tip,
                    title: "Privacy Settings",
                    onTap: () => _navigateTo(context, PrivacySettingsScreen(userId: userId)),
                  ),
                  _buildSettingsOption(
                    context,
                    icon: Icons.help_center,
                    title: "Help Center",
                    onTap: () => _navigateTo(context, HelpCenterScreen(userId: userId)),
                  ),
                ],
              ),
            ),

            // Logout Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 120),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(Icons.logout, color: Colors.white),
                label: Text("Log Out", style: GoogleFonts.sen(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: GoogleFonts.sen(fontSize: 16, color: Colors.white)),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
      onTap: onTap,
    );
  }
}
