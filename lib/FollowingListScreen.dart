import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_screen.dart'; // Ensure ProfileScreen is imported

class FollowingListScreen extends StatefulWidget {
  final String userId;
  final String loggedInUserId; // Pass logged-in user to check ownership

  FollowingListScreen({required this.userId, required this.loggedInUserId});

  @override
  _FollowingListScreenState createState() => _FollowingListScreenState();
}

class _FollowingListScreenState extends State<FollowingListScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> followingList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFollowing();
  }

  Future<void> _fetchFollowing() async {
    try {
      final response = await supabase
          .from('followers')
          .select('following_id')
          .eq('follower_id', widget.userId);

      setState(() {
        followingList = response;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching following: $e");
    }
  }

  Future<void> _unfollowUser(String followingId) async {
    try {
      await supabase
          .from('followers')
          .delete()
          .match({'follower_id': widget.userId, 'following_id': followingId});
      setState(() {
        followingList.removeWhere((following) => following['following_id'] == followingId);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unfollowed successfully")));
    } catch (e) {
      print("❌ Error unfollowing user: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error unfollowing user")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF040B41), // ✅ Background Color
      appBar: AppBar(
        title: Text("Following", style: GoogleFonts.sen(color: Colors.white)),
        backgroundColor: Color(0xFF040B41),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: followingList.length,
        itemBuilder: (context, index) {
          String followingId = followingList[index]['following_id'];
          return FutureBuilder(
            future: supabase
                .from('user_profiles')
                .select('username, profile_pic')
                .eq('user_id', followingId)
                .maybeSingle(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return ListTile(title: CircularProgressIndicator());

              if (snapshot.hasData) {
                final userProfile = snapshot.data as Map<String, dynamic>?;
                if (userProfile != null) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        userProfile['profile_pic'] != null && userProfile['profile_pic'].isNotEmpty
                            ? "https://ropvyxordeaxskpwkqdo.supabase.co/storage/v1/object/public/user-profile/${userProfile['profile_pic']}"
                            : 'https://via.placeholder.com/150',
                      ),
                    ),
                    title: Text(
                      userProfile['username'] ?? 'No Username',
                      style: GoogleFonts.sen(color: Colors.white),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(color: Colors.white, width: 2),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        backgroundColor: Color(0xFF040B41), // ✅ Remove button color
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        _unfollowUser(followingId);
                      },
                      child: Text("Unfollow"),
                    ),
                    onTap: () {
                      // ✅ Navigate to ProfileScreen when tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            userId: followingId,
                            loggedInUserId: widget.loggedInUserId,
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return Container();
                }
              } else {
                return Container();
              }
            },
          );
        },
      ),
    );
  }
}
