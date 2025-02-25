import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_screen.dart'; // Import the ProfileScreen

class FollowersListScreen extends StatefulWidget {
  final String userId;
  final String loggedInUserId;

  FollowersListScreen({required this.userId, required this.loggedInUserId});

  @override
  _FollowersListScreenState createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> followersList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFollowers();
  }

  Future<void> _fetchFollowers() async {
    try {
      final response = await supabase
          .from('followers')
          .select('follower_id')
          .eq('following_id', widget.userId);

      setState(() {
        followersList = response;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching followers: $e");
    }
  }

  Future<void> _removeFollower(String followerId)
  async {
    try {
      await supabase
          .from('followers')
          .delete()
          .match({'follower_id': followerId, 'following_id': widget.userId});
      setState(() {
        followersList.removeWhere((follower) => follower['follower_id'] == followerId);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Removed follower")));
    } catch (e) {
      print("❌ Error removing follower: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error removing follower")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF040B41), // ✅ Background Color
      appBar: AppBar(
        title: Text("Followers", style: GoogleFonts.sen(color: Colors.white)),
        backgroundColor: Color(0xFF040B41),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: followersList.length,
        itemBuilder: (context, index) {
          String followerId = followersList[index]['follower_id'];
          return FutureBuilder(
            future: supabase
                .from('user_profiles')
                .select('username, profile_pic')
                .eq('user_id', followerId)
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
                            : 'https://via.placeholder.com/150', // Fallback if profile_pic is null
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
                        _removeFollower(followerId);
                      },
                      child: Text("Remove"),
                    ),
                    onTap: () {
                      // ✅ Navigate to ProfileScreen when tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            userId: followerId,
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
