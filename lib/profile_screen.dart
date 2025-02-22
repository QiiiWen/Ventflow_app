import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'search_screen.dart';
import 'post_upload_screen.dart';
import 'qr_code_screen.dart';
import 'qr_scanner_screen.dart';


class ProfileScreen extends StatefulWidget {
  final String userId;
  final String loggedInUserId;

  ProfileScreen({required this.userId, required this.loggedInUserId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }


  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SettingsScreen(
                userId: widget.userId, userEmail: userProfile?['email'] ?? ""),
      ),
    );
  }

  void _openQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) =>
          QRScannerScreen(loggedInUserId: widget.loggedInUserId)),
    );
  }

  void _showQRCode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRCodeScreen(userId: widget.userId),
      ),
    );
  }

  void _openPhotoUploadScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoUploadScreen(userId: widget.loggedInUserId),
      ),
    ).then((_) {
      _fetchUserProfile(); // Refresh profile after photo upload
    });
  }

  Future<void> _toggleFollow() async {
    final supabase = Supabase.instance.client;
    try {
      final existingFollow = await supabase
          .from('followers')
          .select('id')
          .eq('follower_id', widget.loggedInUserId)
          .eq('following_id', widget.userId)
          .maybeSingle(); // ✅ Prevents crashes when no data is found

      if (existingFollow != null) {
        // ✅ Unfollow (Delete)
        await supabase
            .from('followers')
            .delete()
            .match({
          'follower_id': widget.loggedInUserId,
          'following_id': widget.userId
        });

        setState(() {
          isFollowing = false;
          userProfile!['followers'] = (userProfile!['followers'] ?? 0) - 1;
        });
        print("✅ Unfollowed successfully");
      } else {
        // ✅ Follow (Insert)
        await supabase.from('followers').insert({
          'follower_id': widget.loggedInUserId,
          'following_id': widget.userId,
          'created_at': DateTime.now().toIso8601String(),
        });

        setState(() {
          isFollowing = true;
          userProfile!['followers'] = (userProfile!['followers'] ?? 0) + 1;
        });
        print("✅ Followed successfully");
      }
    } catch (e) {
      print("❌ Error toggling follow status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating follow status")),
      );
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      // Fetch user profile data
      final profileResponse = await supabase
          .from('user_profiles')
          .select('username, profile_pic, location, bio')
          .eq('user_id', widget.userId)
          .maybeSingle();

      if (profileResponse == null) {
        print("⚠️ No user profile found for user_id: ${widget.userId}");
        return;
      }

      // Construct full profile picture URL
      String? profilePicPath = profileResponse['profile_pic'];
      String? profilePicUrl;
      if (profilePicPath != null && profilePicPath.isNotEmpty) {
        profilePicUrl =
        "https://ropvyxordeaxskpwkqdo.supabase.co/storage/v1/object/public/user-profile/$profilePicPath";
      }

      // Fetch followers count correctly
      final followersResponse = await supabase
          .from('followers')
          .select('id')
          .eq('following_id', widget.userId);
      final followersCount = followersResponse.length;

      // Fetch following count correctly
      final followingResponse = await supabase
          .from('followers')
          .select('id')
          .eq('follower_id', widget.userId);
      final followingCount = followingResponse.length;

      // 🔥 Fetch user photos from `posts` table
      final postsResponse = await supabase
          .from('posts')
          .select('image_url')
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);

      List<String> photos = postsResponse.isNotEmpty
          ? List<String>.from(postsResponse.map((post) => post['image_url']))
          : [];

      setState(() {
        userProfile = {
          ...profileResponse,
          'profile_pic': profilePicUrl ?? "https://via.placeholder.com/150",
          'followers': followersCount,
          'following': followingCount,
          'photos': photos, // ✅ Store user photos from `posts`
        };
        isLoading = false;
      });

      print("✅ User Profile Loaded with ${photos.length} photos");
    } catch (e) {
      print("❌ Error fetching profile: $e");
      setState(() {
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    bool isOwnProfile = widget.userId == widget.loggedInUserId;

    return Scaffold(
      backgroundColor: Color(0xFF6850F6),
      appBar: AppBar(
        backgroundColor: Color(0xFF040B41),
        elevation: 0,
        title: Text("Profile",
            style: GoogleFonts.sen(fontSize: 20, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [

          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>
                    SearchScreen(loggedInUserId: widget.loggedInUserId)),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : userProfile == null
          ? Center(child: Text(
          "Profile not found", style: TextStyle(color: Colors.white)))
          : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    bool isOwnProfile = widget.userId == widget.loggedInUserId;

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF040B41),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(userProfile!['profile_pic'] ??
                      "https://via.placeholder.com/150"),
                ),
                SizedBox(height: 10),
                Text(
                  "${userProfile!['username']}",
                  style: GoogleFonts.sen(fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                Text(
                  userProfile!['bio'] ?? "No bio available",
                  style: GoogleFonts.sen(fontSize: 16, color: Colors.white54),
                ),

                // Follow/Unfollow Button (Only when viewing other profiles)
                if (!isOwnProfile)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing ? Color(0xFF040B41) : Color(
                          0xFF6850F6),
                      padding: EdgeInsets.symmetric(
                          horizontal: 40, vertical: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                    onPressed: _toggleFollow,
                    child: Text(isFollowing ? "Unfollow" : "Follow",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),

                // QR Code & Scanner Buttons (Only for logged-in users viewing their own profile)
                if (isOwnProfile) ...[
                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.qr_code, color: Colors.white),
                        label: Text("Show QR Code",
                            style: GoogleFonts.sen(fontSize: 10, color: Colors
                                .white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF040B41),
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.white, width: 2)),
                        ),
                        onPressed: _showQRCode,
                      ),
                      SizedBox(width: 15),
                      ElevatedButton.icon(
                        icon: Icon(Icons.qr_code_scanner, color: Colors.white),
                        label: Text("Scan QR Code",
                            style: GoogleFonts.sen(fontSize: 10, color: Colors
                                .white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF6850F6),
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _openQRScanner,
                      ),
                    ],
                  ),
                ],

                SizedBox(height: 15),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(
                          "Followers", userProfile!['followers'] ?? 0),
                      _buildStatColumn(
                          "Following", userProfile!['following'] ?? 0),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Photos Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Photos", style: GoogleFonts.sen(fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
                if (isOwnProfile)
                  IconButton(
                    icon: Icon(
                        Icons.add_a_photo, color: Colors.white, size: 25),
                    onPressed: _openPhotoUploadScreen,
                  ),
              ],
            ),
          ),
          _buildPhotoGallery(),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.sen(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          label,
          style: GoogleFonts.sen(fontSize: 14, color: Colors.white54),
        ),
      ],
    );
  }


  Widget _buildPhotoGallery() {
    List<String> photos = userProfile?['photos'] ?? [];

    return photos.isEmpty
        ? Center(
      child: Text(
        "No photos uploaded",
        style: TextStyle(color: Colors.white54),
      ),
    )
        : Padding(
      padding: EdgeInsets.symmetric(horizontal: 15), // ✅ Add padding on left & right
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            child: Image.network(
              photos[index],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.broken_image, color: Colors.white54);
              },
            ),
          );
        },
      ),
    );
  }
}


