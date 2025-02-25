import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForYouPage extends StatefulWidget {
  final String userId;

  ForYouPage({required this.userId});

  @override
  _ForYouPageState createState() => _ForYouPageState();
}

class _ForYouPageState extends State<ForYouPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchForYouPosts();
  }

  /// ✅ **Fetch Posts & Prioritize Followed Users**
  Future<void> _fetchForYouPosts() async {
    final supabase = Supabase.instance.client;

    try {
      // 🔹 Get IDs of users the logged-in user follows
      final followingResponse = await supabase
          .from('followers')
          .select('following_id')
          .eq('follower_id', widget.userId);

      // 🟢 Ensure `following_id` is treated as a String (UUID)
      List<String> followingIds = followingResponse.map<String>((row) => row['following_id'].toString()).toList();

      // 🔹 Fetch all posts + user details
      final postsResponse = await supabase
          .from('posts')
          .select('id, image_url, caption, created_at, user_id, users!inner(id, user_profiles!user_profiles_user_id_fkey(username, profile_pic))')
          .order('created_at', ascending: false);

      List<dynamic> posts = postsResponse;

      setState(() {
        // 🔹 Print the structure for debugging
        print("🔎 Posts Data: $posts");

        // 🟢 Ensure `user_id` is also treated as a String before sorting
        _posts = posts..sort((a, b) {
          bool aIsFollowed = followingIds.contains(a['user_id'].toString());
          bool bIsFollowed = followingIds.contains(b['user_id'].toString());

          if (aIsFollowed && !bIsFollowed) return -1; // Move followed users' posts up
          if (!aIsFollowed && bIsFollowed) return 1;  // Move others down
          return 0; // Keep same order otherwise
        });

        _isLoading = false;
      });

      print("✅ For You Posts Fetched: ${_posts.length}");
    } catch (error) {
      print("❌ Error fetching posts: $error");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF040B41),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : _posts.isEmpty
          ? Center(
        child: Text(
          "No posts available",
          style: GoogleFonts.sen(color: Colors.white70, fontSize: 16),
        ),
      )
          : ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return _buildPostCard(_posts[index]);
        },
      ),
    );
  }

  Widget _buildPostCard(dynamic post) {
    final userProfiles = post['users']['user_profiles'];
    final user = (userProfiles is List && userProfiles.isNotEmpty) ? userProfiles[0] : null;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🟢 **User Info Row**
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: user != null && user['profile_pic'] != null
                      ? NetworkImage("https://ropvyxordeaxskpwkqdo.supabase.co/storage/v1/object/public/${user['profile_pic']}")
                      : AssetImage('assets/default_profile.png') as ImageProvider,
                  radius: 20,
                ),
                SizedBox(width: 10),
                Text(
                  "@${user != null ? user['username'] ?? 'Unknown' : 'Unknown'}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 10),

            // 🟢 **Post Image**
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                post['image_url'],
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.broken_image, size: 50, color: Colors.grey);
                },
              ),
            ),
            SizedBox(height: 5),

            // 🟢 **Post Caption**
            Text(
              post['caption'],
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

}
