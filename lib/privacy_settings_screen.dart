import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrivacySettingsScreen extends StatefulWidget {
  final String userId;

  PrivacySettingsScreen({required this.userId});

  @override
  _PrivacySettingsScreenState createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final supabase = Supabase.instance.client;
  bool _isPrivate = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPrivacySettings();
  }

  /// 🔄 **Fetch Privacy Settings from Supabase**
  Future<void> _fetchPrivacySettings() async {
    try {
      print("⏳ Fetching privacy settings for user_id: ${widget.userId}");

      final response = await supabase
          .from('user_profiles')
          .select('is_private')
          .eq('user_id', widget.userId)
          .maybeSingle();

      if (response == null) {
        print("⚠️ No privacy settings found for user_id: ${widget.userId}");
      } else {
        setState(() {
          _isPrivate = response['is_private'] ?? false;
        });
        print("✅ Privacy setting fetched: $_isPrivate");
      }
    } catch (e) {
      print("❌ Error fetching privacy settings: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 🔄 **Update Privacy Setting in Supabase**
  Future<void> _updatePrivacySetting(bool value) async {
    setState(() {
      _isPrivate = value;
    });

    try {
      await supabase
          .from('user_profiles')
          .update({'is_private': value})
          .eq('user_id', widget.userId);

      print("✅ Privacy setting updated successfully: $_isPrivate");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Privacy settings updated successfully!")),
      );
    } catch (e) {
      print("❌ Error updating privacy setting: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update privacy settings.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF040B41), // Dark blue background
      appBar: AppBar(
        backgroundColor: Color(0xFF040B41),
        elevation: 0,
        title: Text("Privacy Settings", style: GoogleFonts.sen(fontSize: 20, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // **Settings Container**
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF6850F6), // Purple container color
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Private Account",
                            style: GoogleFonts.sen(
                                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Only your followers can see \nyour content.",
                            style: GoogleFonts.sen(fontSize: 14, color: Colors.white70),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isPrivate,
                        onChanged: _updatePrivacySetting,
                        activeColor: Colors.white,
                        activeTrackColor: Colors.blueAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
