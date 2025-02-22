import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForYouPage extends StatefulWidget {
  final String loggedInUserId;

  ForYouPage({required this.loggedInUserId}); // Fix: Accepts userId

  @override
  _ForYouPageState createState() => _ForYouPageState();
}

class _ForYouPageState extends State<ForYouPage> {
  List<dynamic> _posts = [];
  bool _isLoading = true;

  Future<void> _fetchFeed() async {
    var url = "http://10.0.2.2/ventflow_backend/get_feed.php?user_id=${widget.loggedInUserId}";

    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (data["status"] == "success") {
          setState(() {
            _posts = data["posts"];
          });
        } else {
          print("Error: ${data['message']}");
        }
      }
    } catch (e) {
      print("Error fetching feed: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF040B41),
      appBar: AppBar(
        backgroundColor: Color(0xFF040B41),
        title: Text("For You", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : _posts.isEmpty
          ? Center(child: Text("No posts yet", style: TextStyle(color: Colors.white54)))
          : ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          var post = _posts[index];
          return Card(
            color: Color(0xFF6850F6),
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(post["profile_pic"] ?? "https://via.placeholder.com/150"),
                  ),
                  title: Text(post["username"] ?? "Unknown", style: TextStyle(color: Colors.white)),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(post["image_url"], fit: BoxFit.cover),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(post["caption"] ?? "No caption", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}