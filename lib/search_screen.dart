import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_screen.dart';
import 'dart:async';

class SearchScreen extends StatefulWidget {
  final String loggedInUserId;

  SearchScreen({required this.loggedInUserId});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final supabase = Supabase.instance.client;
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce; // Debounce to avoid excessive API calls

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// 🕵️ **Debounced Search Listener**
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 500), () {
      _searchUsers(_searchController.text);
    });
  }

  /// 🔍 **Search Users in Supabase**
  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase
          .from('user_profiles')
          .select('user_id, username, profile_pic')
          .ilike('username', '%$query%'); // Case-insensitive search

      // ✅ Process profile pictures correctly
      final users = response.map((user) {
        String? profilePicPath = user['profile_pic'];
        String profilePicUrl = profilePicPath != null && profilePicPath.isNotEmpty
            ? "https://ropvyxordeaxskpwkqdo.supabase.co/storage/v1/object/public/$profilePicPath"
            : "https://via.placeholder.com/150";

        return {
          ...user,
          'profile_pic': profilePicUrl, // Convert path to full URL
        };
      }).toList();

      setState(() {
        _searchResults = users;
        _isLoading = false;
      });

      print("✅ Search results: $_searchResults");
    } catch (e) {
      print("❌ Error fetching search results: $e");
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
        title: Text("Search Users", style: GoogleFonts.sen(fontSize: 20, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 🔍 **Search Bar**
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search username...",
                hintStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white24,
                prefixIcon: Icon(Icons.search, color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ⏳ **Loading Indicator**
          if (_isLoading)
            Center(child: CircularProgressIndicator(color: Colors.white))
          else
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(child: Text("No users found", style: TextStyle(color: Colors.white)))
                  : ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  var user = _searchResults[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(user['profile_pic']),
                    ),
                    title: Text(user['username'] ?? "Unknown", style: TextStyle(color: Colors.white)),
                    onTap: () {
                      // ✅ Navigate to the clicked user's profile
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            userId: user['user_id'], // Clicked user's ID
                            loggedInUserId: widget.loggedInUserId, // Current logged-in user ID
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
