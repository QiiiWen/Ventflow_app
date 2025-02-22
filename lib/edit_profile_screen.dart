import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  final String userId;

  EditProfileScreen({required this.userId});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _bioController = TextEditingController();
  TextEditingController _locationController = TextEditingController();

  bool isLoading = true;
  String _profilePic = "";
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  /// 📥 **Fetch Profile Data from Supabase**
  Future<void> _fetchProfileData() async {
    try {
      print("⏳ Fetching profile data for user_id: ${widget.userId}...");

      final startTime = DateTime.now(); // ✅ Start time tracking

      final response = await supabase
          .from('user_profiles')
          .select('username, bio, location, profile_pic, users!user_profiles_user_id_fkey(first_name, last_name)')
          .eq('user_id', widget.userId)
          .maybeSingle();

      final endTime = DateTime.now(); // ✅ End time tracking
      print("⏳ Query execution time: ${endTime.difference(startTime).inMilliseconds}ms");

      if (response == null) {
        print("⚠️ No profile found for user_id: ${widget.userId}");
        setState(() {
          isLoading = false;
        });
        return;
      }

      print("✅ Profile data received: $response");

      String? profilePicPath = response['profile_pic'];
      String profilePicUrl = profilePicPath != null && profilePicPath.isNotEmpty
          ? "https://ropvyxordeaxskpwkqdo.supabase.co/storage/v1/object/public/user-profile/$profilePicPath"
          : "https://via.placeholder.com/150";

      setState(() {
        _usernameController.text = response['username'] ?? "";
        _bioController.text = response['bio'] ?? "";
        _locationController.text = response['location'] ?? "";
        _firstNameController.text = response['users']?['first_name'] ?? "";
        _lastNameController.text = response['users']?['last_name'] ?? "";
        _profilePic = profilePicUrl;
        isLoading = false;
      });

    } catch (e) {
      print("❌ Error fetching profile: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  /// 📤 **Upload Image to Supabase Storage & Update Profile**
  Future<void> _uploadProfilePic() async {
    if (_imageFile == null) return;

    try {
      final fileName = "${widget.userId}.jpg";
      final filePath = "user-profile/$fileName";

      // ✅ Upload image
      await supabase.storage.from('user-profile').upload(filePath, _imageFile!,
          fileOptions: FileOptions(cacheControl: '3600', upsert: true));

      // ✅ Generate Public URL
      final publicUrl = "https://ropvyxordeaxskpwkqdo.supabase.co/storage/v1/object/public/$filePath";

      // ✅ Update user_profiles table with new profile_pic URL
      await supabase.from('user_profiles').update({'profile_pic': filePath}).eq('user_id', widget.userId);

      setState(() {
        _profilePic = publicUrl;
      });

      print("✅ Profile picture uploaded and database updated: $publicUrl");
    } catch (e) {
      print("❌ Error uploading image: $e");
    }
  }

  /// 📤 **Update Profile in Supabase**
  Future<void> _updateProfile() async {
    try {
      // ✅ Update `users` table
      await supabase.from('users').update({
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
      }).eq('id', widget.userId);

      // ✅ Update `user_profiles` table
      await supabase.from('user_profiles').update({
        'username': _usernameController.text,
        'bio': _bioController.text,
        'location': _locationController.text,
      }).eq('user_id', widget.userId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Profile updated successfully!")),
      );

      print("✅ Profile updated successfully!");
      Navigator.pop(context, true);
    } catch (e) {
      print("❌ Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Update failed! Try again.")),
      );
    }
  }

  /// 📸 **Pick Image from Gallery**
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });

      await _uploadProfilePic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF040B41),
      appBar: AppBar(
        backgroundColor: Color(0xFF040B41),
        elevation: 0,
        title: Text("Edit Profile", style: GoogleFonts.sen(fontSize: 20, color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              // 📸 Profile Picture Section
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : NetworkImage(_profilePic) as ImageProvider,
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 18,
                      child: Icon(Icons.edit, color: Colors.black, size: 18),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // 🔹 **Form Inputs in a Styled Container**
              Container(
                padding: EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Color(0xFF6850F6), // Inner Container Background
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField("First Name", _firstNameController),
                    SizedBox(height: 10),
                    _buildTextField("Last Name", _lastNameController),
                    SizedBox(height: 10),
                    _buildTextField("Username", _usernameController),
                    SizedBox(height: 10),
                    _buildTextField("Location", _locationController),
                    SizedBox(height: 10),
                    _buildTextField("Bio", _bioController, maxLines: 3),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(horizontal: 60, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _updateProfile,
                      child: Text("Update", style: GoogleFonts.sen(fontSize: 16, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// **Reusable Styled Text Field**
  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white24,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
