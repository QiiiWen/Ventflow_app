import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'EventDetailsScreen.dart';
import 'OnGoingEventDetailsPage.dart';

class OngoingEventsScreen extends StatefulWidget {
  final String userId;


  OngoingEventsScreen({required this.userId});

  @override
  _OngoingEventsScreenState createState() => _OngoingEventsScreenState();
}

class _OngoingEventsScreenState extends State<OngoingEventsScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _ongoingEvents = [];
  List<dynamic> _ticketsPurchased = [];
  List<dynamic> _recommendedEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  /// ✅ **Fetch Ongoing Events, Purchased Tickets & Recommendations**
  Future<void> _fetchData() async {
    try {
      // 🔹 Get tickets user purchased
      final ticketsResponse = await supabase
          .from('tickets')
          .select('event_id')
          .eq('user_id', widget.userId);

      List<int> eventIds = ticketsResponse.map<int>((ticket) => ticket['event_id']).toList();

      // 🔹 Fetch All Events & Manually Filter
      final allEventsResponse = await supabase
          .from('events')
          .select('*');

      // ✅ Manually filter events
      final ongoingEvents = allEventsResponse
          .where((event) => eventIds.contains(event['id']) && event['status'] == 'ongoing')
          .toList();

      final ticketedEvents = allEventsResponse
          .where((event) => eventIds.contains(event['id']))
          .toList();

      final recommendedEvents = allEventsResponse
          .where((event) => !eventIds.contains(event['id']) && event['status'] != 'past')
          .toList()
          .take(5) // Limit recommendations
          .toList();

      setState(() {
        _ongoingEvents = ongoingEvents;
        _ticketsPurchased = ticketedEvents;
        _recommendedEvents = recommendedEvents;
        _isLoading = false;
      });

      print("✅ Ongoing Events: $_ongoingEvents");
      print("✅ Tickets Purchased: $_ticketsPurchased");
      print("✅ Recommended Events: $_recommendedEvents");
    } catch (error) {
      print("❌ Error fetching data: $error");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6850F6), Color(0xFF040B41)],
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Ongoing Events"),
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: Colors.white))
                  : _ongoingEvents.isEmpty
                  ? _buildEmptyState("No Ongoing Events Today.")
                  : _buildEventsList(_ongoingEvents),

              SizedBox(height: 20),

              _buildSectionTitle("Your Tickets"),
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: Colors.white))
                  : _ticketsPurchased.isEmpty
                  ? _buildEmptyState("No tickets purchased yet.")
                  : _buildEventsList(_ticketsPurchased, showStatus: true),

              SizedBox(height: 20),

              _buildSectionTitle("Recommended Events"),
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: Colors.white))
                  : _recommendedEvents.isEmpty
                  ? _buildEmptyState("No recommendations available.")
                  : _buildHorizontalEventSlider(_recommendedEvents),
            ],
          ),
        ),
      ),
    );
  }

  /// 🏷 **Section Title**
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.sen(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  /// ❌ **Empty State Widget**
  Widget _buildEmptyState(String message) {
    return Center(
      child: Container(
        width: double.infinity,
        height: 150,
        padding: EdgeInsets.all(15),
        margin: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Text(message, style: GoogleFonts.sen(color: Colors.black, fontSize: 16)),
      ),
    );
  }

  /// 📌 **Event List Widget**
  Widget _buildEventsList(List<dynamic> events, {bool showStatus = false}) {
    return Column(
      children: events.map((event) => _buildEventCard(event, showStatus: showStatus)).toList(),
    );
  }

  Widget _buildHorizontalEventSlider(List<dynamic> events) {
    return SizedBox(
      height: 250, // Adjust height for better spacing
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        itemBuilder: (context, index) {
          var event = events[index];

          // ✅ Extract event details
          String eventName = event['name'] ?? "Unnamed Event";
          String eventLocation = event['location'] ?? "Unknown Location";
          String eventDate = event['date'] ?? "Unknown Date";

          // ✅ Clean up the banner URL to prevent empty image issues
          String bannerPath = event['banner']?.trim() ?? '';
          if (bannerPath.isNotEmpty && bannerPath.startsWith("/")) {
            bannerPath = bannerPath.substring(1);
          }
          String imageUrl = "https://ropvyxordeaxskpwkqdo.supabase.co/storage/v1/object/public/event-banners/$bannerPath";

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailsScreen(eventId: event['id'], userId: widget.userId),
                ),
              );
            },
            child: Container(
              width: 220,
              margin: EdgeInsets.only(right: 10),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📸 **Event Image with Error Handling**
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 120,
                          color: Colors.grey[300],
                          child: Icon(Icons.image_not_supported, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 4),
                  // 📌 **Event Details**
                  Text(eventName, style: GoogleFonts.sen(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 13, color: Colors.white),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(eventLocation, style: TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  SizedBox(height: 3),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  /// 🎟 **Event Card Widget** (Updated to Row Layout)
  Widget _buildEventCard(dynamic event, {bool showStatus = false, bool allowPurchase = false}) {
    // ✅ Trim and sanitize the icon path
    String iconPath = event['icon']?.trim() ?? '';
    if (iconPath.isNotEmpty && iconPath.startsWith('/')) {
      iconPath = iconPath.substring(1); // Remove leading slash if any
    }

    // ✅ Construct the correct Supabase public URL for the icon
    String iconUrl = "https://ropvyxordeaxskpwkqdo.supabase.co/storage/v1/object/public/$iconPath";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OngoingEventDetailsScreen(eventId: event['id'], userId: widget.userId),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 📸 **Event Icon**
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                iconUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print("⚠️ Failed to load icon: $iconUrl");
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: Icon(Icons.broken_image, color: Colors.grey[600]),
                  );
                },
              ),
            ),
            SizedBox(width: 10),

            // 📄 **Event Details**
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['name'],
                    style: GoogleFonts.sen(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "${event['date']}",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  if (showStatus)
                    Text(
                      "Status: ${event['status']}",
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
