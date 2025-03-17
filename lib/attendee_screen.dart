import 'dart:convert'; // CHANGED: Added for JSON decoding
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_screen.dart';
import 'EventDetailsScreen.dart';
import 'EventListScreen.dart';

class AttendeeScreen extends StatefulWidget {
  final String firstName;
  final String userId;

  AttendeeScreen({required this.firstName, required this.userId});

  @override
  _AttendeeScreenState createState() => _AttendeeScreenState();
}

class _AttendeeScreenState extends State<AttendeeScreen> {
  List<dynamic> _events = [];
  List<dynamic> _recommendedEvents =
      []; // CHANGED: New variable for recommended events
  TextEditingController _searchController = TextEditingController();
  final supabase = Supabase.instance.client;

  String? userProfilePic;
  String userLocation = "Unknown Location";

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchEvents();
    _fetchRecommendedEvents(); // CHANGED: Call to fetch recommended events
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await supabase
          .from('user_profiles')
          .select('profile_pic, location')
          .eq('user_id', widget.userId)
          .maybeSingle();

      if (response == null) {
        print("⚠️ No user profile found for user_id: ${widget.userId}");
        return;
      }

      String? profilePicPath = response['profile_pic'];
      String? profilePicUrl;
      if (profilePicPath != null && profilePicPath.isNotEmpty) {
        profilePicUrl =
            "https://ropvyxordeaxskpwkqdo.supabase.co/storage/v1/object/public/user-profile/$profilePicPath";
      }

      String fetchedLocation = response['location'] ?? "Unknown Location";
      if (fetchedLocation.trim().isEmpty) {
        fetchedLocation = "Unknown Location";
      }

      setState(() {
        userProfilePic = profilePicUrl;
        userLocation = fetchedLocation;
      });

      print("✅ Profile Picture URL: $userProfilePic");
      print("📍 Fetched Location: $userLocation");
    } catch (e) {
      print("❌ Error fetching profile: $e");
    }
  }

  // ✅ Fetch events from Supabase
  Future<void> _fetchEvents() async {
    try {
      final response = await supabase.from('events').select();

      setState(() {
        _events = response.map((event) {
          String iconPath = event['icon']?.trim() ?? "";
          String bannerPath = event['banner']?.trim() ?? "";
          if (iconPath.startsWith('/')) iconPath = iconPath.substring(1);
          if (bannerPath.startsWith('/')) bannerPath = bannerPath.substring(1);

          final iconUrl = iconPath.isNotEmpty
              ? "https://ropvyxordeaxskpwkqdo.supabase.co/storage/v1/object/public/$iconPath"
              : null;
          final bannerUrl = bannerPath.isNotEmpty
              ? "https://ropvyxordeaxskpwkqdo.supabase.co/storage/v1/object/public/$bannerPath"
              : null;

          print("📸 Event Icon URL: $iconUrl");
          print("🖼 Event Banner URL: $bannerUrl");

          return {
            ...event,
            'icon': iconUrl,
            'banner': bannerUrl,
          };
        }).toList();
      });

      print("✅ Events fetched successfully: $_events");
    } catch (error) {
      print("❌ Error fetching events: $error");
    }
  }

  // CHANGED: New function to fetch recommended events from the edge function
  Future<void> _fetchRecommendedEvents() async {

    try {
      final recommendedResponse =
          await supabase.functions.invoke('get_top_events', body: {});
      List<dynamic> recommendedEvents = [];
      if (recommendedResponse.data != null) {
        // CHANGED: Decode the JSON string returned from the edge function
        final decodedData = json.decode(recommendedResponse.data);
        if (decodedData is List) {
          // CHANGED: Process each event to update icon and banner URLs
          recommendedEvents = decodedData.map((event) {
            String iconPath = (event['icon'] ?? "").trim();
            String bannerPath = (event['banner'] ?? "").trim();
            if (iconPath.startsWith('/')) iconPath = iconPath.substring(1);
            if (bannerPath.startsWith('/'))
              bannerPath = bannerPath.substring(1);
            final iconUrl = iconPath.isNotEmpty
                ? "https://ropvyxordeaxskpwkqdo.supabase.co/storage/v1/object/public/$iconPath"
                : null;
            final bannerUrl = bannerPath.isNotEmpty
                ? "https://ropvyxordeaxskpwkqdo.supabase.co/storage/v1/object/public/$bannerPath"
                : null;
            return {
              ...event,
              'icon': iconUrl,
              'banner': bannerUrl,
            };
          }).toList();
        } else {
          print("Decoded data is not a list: $decodedData");
        }
      }
      setState(() {
        _recommendedEvents = recommendedEvents;
      });
      print("✅ Recommended Events fetched: $_recommendedEvents");
    } catch (error) {
      print("❌ Error fetching recommended events: $error");
    }
  }

  void _navigateToEventDetails(dynamic event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsScreen(
          eventId: event['id'],
          userId: widget.userId,
        ),
      ),
    );
  }

  void _searchEvents(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventListScreen(
          events: _events.isNotEmpty ? _events : [],
          loggedInUserId: widget.userId,
          initialSearchQuery: query,
        ),
      ),
    );
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF040B41),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // **Header Section**
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                color: Color(0xFF040B41),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🧑‍ Profile Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(
                                  userId: widget.userId,
                                  loggedInUserId: widget.userId,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white24,
                                backgroundImage: userProfilePic != null
                                    ? NetworkImage(userProfilePic!)
                                    : null,
                                child: userProfilePic == null
                                    ? Icon(Icons.person,
                                        color: Colors.white, size: 30)
                                    : null,
                              ),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Hi, ${widget.firstName}",
                                      style: GoogleFonts.sen(
                                          fontSize: 20, color: Colors.white)),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          color: Colors.blue, size: 14),
                                      Text(
                                        userLocation,
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.notifications_none,
                            color: Colors.white, size: 28),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Find Amazing Events",
                      style: GoogleFonts.sen(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    // 🔍 Search Bar
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12)),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Search Events",
                          hintStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.search, color: Colors.white),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.white),
                                  onPressed: _clearSearch)
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                        ),
                        onSubmitted: (query) => _searchEvents(query),
                      ),
                    ),
                  ],
                ),
              ),

              // **Events For You Section**
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF6850F6),
                  borderRadius: BorderRadius.only(
                      topRight: Radius.circular(15),
                      topLeft: Radius.circular(15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Events For You"),
                    SizedBox(height: 10),
                    _buildHorizontalEventSlider(_events.take(5).toList()),
                  ],
                ),
              ),

              // **Trending Events Section**
              Container(
                padding: EdgeInsets.all(20),
                color: Color(0xFF6850F6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Trending Events"),
                    SizedBox(height: 10),
                    // CHANGED: Use _recommendedEvents from edge function if available, fallback to _events.reversed.take(5).toList()
                    _buildTrendingEventList(
                      _recommendedEvents.isNotEmpty
                          ? _recommendedEvents
                          : _events.reversed.take(5).toList(),
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

  /// 🎟 **Horizontal Sliding Events (For 'Events For You')**
  Widget _buildHorizontalEventSlider(List<dynamic> events) {
    return events.isEmpty
        ? Center(
            child: Text("No events found",
                style: TextStyle(color: Colors.white70)))
        : SizedBox(
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: events.length,
              itemBuilder: (context, index) {
                return _buildEventCard(events[index], isHorizontal: true);
              },
            ),
          );
  }

  /// 📌 **Event Card for Lists**
  Widget _buildEventCard(dynamic event, {bool isHorizontal = false}) {
    return GestureDetector(
      onTap: () => _navigateToEventDetails(event),
      child: Container(
        margin: EdgeInsets.only(
            right: isHorizontal ? 10 : 0, bottom: isHorizontal ? 0 : 10),
        width: isHorizontal ? 230 : double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black38,
                blurRadius: 4,
                spreadRadius: 2,
                offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // **Banner Image**
            Padding(
              padding: EdgeInsets.all(8),
              child: Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    event['banner'],
                    width: double.infinity,
                    height: 130,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.broken_image,
                          size: 50, color: Colors.grey);
                    },
                  ),
                ),
              ),
            ),
            // **Event Details**
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event['name'],
                      style: GoogleFonts.sen(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 13, color: Colors.blue),
                      SizedBox(width: 5),
                      Text(event['location'],
                          style: TextStyle(color: Colors.black, fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.black54),
                      SizedBox(width: 5),
                      Text(event['date'],
                          style: TextStyle(color: Colors.black)),
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

  /// 🏆 **Section Header (Ensures Only One Exists)**
  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: GoogleFonts.sen(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => EventListScreen(
                    events: _events, loggedInUserId: widget.userId)),
          ),
          child: Text("See all", style: TextStyle(color: Colors.blue)),
        ),
      ],
    );
  }

  /// 🔥 **Trending Event List**
  Widget _buildTrendingEventList(List<dynamic> events) {
    return events.isEmpty
        ? Center(
            child: Text("No events found",
                style: TextStyle(color: Colors.white70)))
        : Column(
            children:
                events.map((event) => _buildTrendingEventCard(event)).toList(),
          );
  }

  /// 🛠 **Trending Event Card**
  Widget _buildTrendingEventCard(dynamic event) {
    return GestureDetector(
      onTap: () => _navigateToEventDetails(event),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        height: 115,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 2,
                offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                event['icon'],
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.broken_image, size: 80, color: Colors.grey);
                },
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event['name'],
                      style: GoogleFonts.sen(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(event['location'],
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text(event['date'],
                      style: TextStyle(color: Colors.black, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
