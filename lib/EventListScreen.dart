import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'EventDetailsScreen.dart';
import 'profile_screen.dart';

class EventListScreen extends StatefulWidget {
  final List<dynamic> events;  // ✅ Accepts event list
  final String initialSearchQuery;
  final String loggedInUserId;

  EventListScreen({required this.events, required this.loggedInUserId, this.initialSearchQuery = ""});

  @override
  _EventListScreenState createState() => _EventListScreenState();
}


class _EventListScreenState extends State<EventListScreen> {
  List<dynamic> _filteredEvents = [];
  List<dynamic> _filteredUsers = [];
  TextEditingController _searchController = TextEditingController();
  bool _isSearchingUsers = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  /// 🔹 Fetch Events from Supabase
  Future<void> _fetchEvents() async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.from('events').select('*').order('date', ascending: true);

      setState(() {
        _filteredEvents = response.map((event) {
          String iconPath = event['icon']?.trim() ?? "";
          String bannerPath = event['banner']?.trim() ?? "";

          // ✅ Ensure paths don't have extra slashes
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
        _isLoading = false;
      });

      print("✅ Events fetched successfully: $_filteredEvents");
    } catch (error) {
      print("❌ Error fetching events: $error");
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 🔍 Search Events & Users
  void _searchEvents(String query) {
    if (query.isEmpty) {
      setState(() {
        _fetchEvents();
        _filteredUsers = [];
        _isSearchingUsers = false;
      });
      return;
    }

    // ✅ Filter Events by Name
    setState(() {
      _filteredEvents = _filteredEvents.where((event) {
        return event['name'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    });

  }
  /// ❌ Clear Search
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _fetchEvents();
      _filteredUsers = [];
      _isSearchingUsers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF040B41),
      appBar: AppBar(
        backgroundColor: Color(0xFF040B41),
        elevation: 0,
        title: Text(
          "",
          style: GoogleFonts.sen(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search events or users...",
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.search, color: Colors.white),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: Icon(Icons.clear, color: Colors.white), onPressed: _clearSearch)
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: _searchEvents,
            ),
          ),

          // 📌 Show Users if Searching Users
          _isSearchingUsers
              ? Expanded(child: _buildUserSearchResults())
              : Expanded(child: _isLoading ? _buildLoadingIndicator() : _buildEventSearchResults()),
        ],
      ),
    );
  }

  /// 🔄 Loading Indicator
  Widget _buildLoadingIndicator() {
    return Center(child: CircularProgressIndicator(color: Colors.white));
  }

  /// 🏆 Build Event Results
  Widget _buildEventSearchResults() {
    return _filteredEvents.isEmpty
        ? _buildEmptyState("No events found")
        : ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredEvents.length,
      itemBuilder: (context, index) {
        return _buildEventCard(_filteredEvents[index]);
      },
    );
  }

  /// 🔍 Build User Results
  Widget _buildUserSearchResults() {
    return _filteredUsers.isEmpty
        ? _buildEmptyState("No users found")
        : ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        return _buildUserCard(_filteredUsers[index]);
      },
    );
  }

  /// ❌ No Results Widget
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: GoogleFonts.sen(color: Colors.white, fontSize: 18)),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _clearSearch,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
            child: Text("Reset Search"),
          ),
        ],
      ),
    );
  }

  /// 🧑 User Card
  Widget _buildUserCard(dynamic user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(user['profile_pic'] ?? "https://via.placeholder.com/150"),
      ),
      title: Text(user['username'], style: GoogleFonts.sen(color: Colors.white)),
      subtitle: Text(user['location'] ?? "Unknown", style: TextStyle(color: Colors.white70)),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: user['id'], loggedInUserId: widget.loggedInUserId),
          ),
        );
      },
    );
  }

  /// 🎟 Event Card
  /// 🎟 Event Card
  Widget _buildEventCard(dynamic event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EventDetailsScreen(eventId: event['id'], userId: widget.loggedInUserId)),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8), // Add border radius
            child: Image.network(
              event['icon'],
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.broken_image, size: 50, color: Colors.grey);
              },
            ),
          ),
          title: Text(event['name'], style: GoogleFonts.sen(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          subtitle: Text(event['location'], style: TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }
}
