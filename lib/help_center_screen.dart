import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ventflow/application_form_screen.dart';
import 'package:ventflow/report_event_screen.dart';
import 'EventDetailsScreen.dart';
import 'about_us_screen.dart';
import 'chatbot.dart';
import 'privacy_policy_screen.dart';
import 'terms_and_conditions_screen.dart';
import 'feedback_screen.dart';
import 'EventListScreen.dart'; // <-- Added import for the search results screen

class HelpCenterScreen extends StatefulWidget {
  final String userId;

  HelpCenterScreen({required this.userId});

  @override
  _HelpCenterScreenState createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  List<dynamic> _events = [];
  // Initialize Supabase client
  final supabase = Supabase.instance.client;

  // <-- Added TextEditingController for search
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchHelpEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Fetch events from Supabase to display under 'Report an Event'
  Future<void> _fetchHelpEvents() async {
    try {
      // Fetch all events from the 'events' table
      final List<dynamic> events = await supabase.from('events').select();
      setState(() {
        _events = events.map((event) {
          // Process the icon and banner paths to generate full URLs.
          String iconPath = (event['icon'] ?? '').trim();
          String bannerPath = (event['banner'] ?? '').trim();
          if (iconPath.startsWith('/')) iconPath = iconPath.substring(1);
          if (bannerPath.startsWith('/')) bannerPath = bannerPath.substring(1);
          final iconUrl = iconPath.isNotEmpty
              ? "https://ropvyxordeaxskpwkqdo.supabase.co/storage/v1/object/public/$iconPath"
              : "";
          final bannerUrl = bannerPath.isNotEmpty
              ? "https://ropvyxordeaxskpwkqdo.supabase.co/storage/v1/object/public/$bannerPath"
              : "";
          return {
            ...event,
            'icon': iconUrl,
            'banner': bannerUrl,
          };
        }).toList();
      });
    } catch (e) {
      print("Error fetching events: $e");
    }
  }

  // <-- Integrated search function from AttendeeScreen
  void _searchEvents(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventListScreen(
          events: _events.isNotEmpty ? _events : [],
          loggedInUserId: widget.userId,
          initialSearchQuery: query
        ),
      ),
    );
  }

  // <-- Clear search field function (as in AttendeeScreen)
  void _clearSearch() {
    setState(() {
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Gradient background covering entire screen.
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF040B41), Color(0xFF040B41)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // SafeArea with content.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button at the top.
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    // Title and subtitles.
                    Text(
                      "Help Centre",
                      style: GoogleFonts.sen(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Hello",
                      style: GoogleFonts.sen(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Your help is on the way",
                      style: GoogleFonts.sen(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 20),
                    // Search Field with integrated search functionality.
                    Container(
                      height: 50,
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          fillColor: Colors.white24,
                          filled: true,
                          hintText: "Search or ask something...",
                          hintStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.search, color: Colors.white),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.white),
                            onPressed: _clearSearch,
                          )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (query) => _searchEvents(query),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Report an Event Title.
                    Text(
                      "Report an Event",
                      style: GoogleFonts.sen(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    // List of events from Supabase.
                    _events.isEmpty
                        ? Text(
                      "No events available",
                      style: TextStyle(color: Colors.white70),
                    )
                        : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReportEventScreen(
                                  eventId: _events[index]['id'],
                                  eventName: _events[index]['name'] ?? 'Untitled',
                                ),
                              ),
                            );
                          },
                          child: _buildEventTile(_events[index]),
                        );
                      },
                    ),
                    SizedBox(height: 30),
                    // "Chat with AI now" button.
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF674DFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "Chat with AI now",
                          style: GoogleFonts.sen(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // 2x2 grid of help buttons.
                    _buildHelpButtonsGrid(),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Event tile widget for the Report an Event list.
  Widget _buildEventTile(dynamic event) {
    String title = event['name'] ?? 'Untitled';
    String location = event['location'] ?? 'Unknown';
    String banner = event['banner'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Color(0xFF674DFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (banner.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(10)),
              child: Image.network(
                banner,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.sen(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    location,
                    style: GoogleFonts.sen(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Grid with 4 equally sized buttons.
  Widget _buildHelpButtonsGrid() {
    final buttons = [
      {
        'icon': Icons.info_outline,
        'label': 'About us',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AboutUsScreen()),
        ),
      },
      {
        'icon': Icons.privacy_tip_outlined,
        'label': 'Privacy Policy',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()),
        ),
      },
      {
        'icon': Icons.rule,
        'label': 'Terms & Conditions',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TermsAndConditionsScreen()),
        ),
      },
      {
        'icon': Icons.feedback_outlined,
        'label': 'Send a feedback',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FeedbackScreen()),
        ),
      },
    ];

    return Container(
      height: 220,
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        physics: NeverScrollableScrollPhysics(),
        childAspectRatio: 1.8,
        children: buttons.map((btn) {
          return _buildHelpButton(
            icon: btn['icon'] as IconData,
            label: btn['label'] as String,
            onTap: btn['onTap'] as VoidCallback,
          );
        }).toList(),
      ),
    );
  }

  /// A single help button widget in the grid.
  Widget _buildHelpButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.sen(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
