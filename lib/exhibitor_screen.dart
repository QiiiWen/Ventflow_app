import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Exhibitor_EventDetailsScreen.dart';

class ExhibitorScreen extends StatefulWidget {
  final String firstName;
  final String userId;

  const ExhibitorScreen({super.key, required this.firstName, required this.userId});

  @override
  _ExhibitorScreenState createState() => _ExhibitorScreenState();
}

class _ExhibitorScreenState extends State<ExhibitorScreen> {
  List<dynamic> _events = [];
  List<dynamic> _filteredEvents = [];
  bool _isLoading = true;
  bool _hasError = false;
  final TextEditingController _searchController = TextEditingController();
  final supabase = Supabase.instance.client;

  String cleanBannerUrl(String bannerPath) {
    return "https://ropvyxordeaxskpwkqdo.supabase.co/storage/v1/object/public/${bannerPath.trim().replaceAll(RegExp(r'[\n\r%0A]'), '')}";
  }

  String cleanStorageUrl(String path) {
    return "https://ropvyxordeaxskpwkqdo.supabase.co/storage/v1/object/public/${path.trim().replaceAll(RegExp(r'[\n\r%0A]'), '')}";
  }


  @override
  void initState() {
    super.initState();
    _fetchExhibitorEvents();
  }

  Future<void> _fetchExhibitorEvents() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await supabase
          .from('events')
          .select('id, name, location, category, price, icon, banner, created_at, booths (id, booth_number, status)')
          .order('created_at', ascending: false);

      print("🟢 Response: $response");

      if (response == null || response.isEmpty) {
        print("⚠️ No events found.");
      }

      if (mounted) {
        setState(() {
          _events = response ?? [];
          _filteredEvents = response ?? [];
          _isLoading = false;
        });
      }
    } catch (error) {
      print("❌ Error fetching events: $error");
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _events = [];
          _filteredEvents = [];
        });
      }
    }
    String cleanBannerUrl(String bannerPath) {
      return "https://ropvyxordeaxskpwkqdo.supabase.co/storage/v1/object/public/${bannerPath.trim().replaceAll(RegExp(r'[\n\r%0A]'), '')}";
    }
  }

  void _filterEvents(String query) {
    setState(() {
      _filteredEvents = _events
          .where((event) => event['name'].toLowerCase().contains(query.toLowerCase()) ||
          event['location'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _joinEvent(dynamic event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Exhibitor_EventDetailsScreen(
          eventId: event['id'],
          userId: widget.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040B41),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Exhibitor Events",
                style: GoogleFonts.sen(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                onChanged: _filterEvents,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search events...",
                  hintStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white24,
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _hasError
                    ? Center(
                  child: Text(
                    "❌ Error loading events. Please try again.",
                    style: TextStyle(color: Colors.redAccent, fontSize: 16),
                  ),
                )
                    : _filteredEvents.isEmpty
                    ? Center(
                  child: Text(
                    "No exhibitor events found.",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
                    : ListView.builder(
                  itemCount: _filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = _filteredEvents[index];
                    return Card(
                      color: Colors.white10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (event['banner'] != null && event['banner'].isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                              child: Image.network(
                                cleanBannerUrl(event['banner']), // ✅ Use the function here
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (event['icon'] != null && event['icon'].isNotEmpty)
                                      Image.network(
                                        cleanStorageUrl(event['icon']), // ✅ Clean icon URL
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      )
                                    else
                                      const Icon(Icons.event, color: Colors.white, size: 40),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            event['name'],
                                            style: const TextStyle(
                                                color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            event['location'],
                                            style: const TextStyle(color: Colors.white70),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      event['price'] != null && event['price'] > 0
                                          ? "RM ${event['price']}"
                                          : "Free",
                                      style: const TextStyle(
                                          color: Colors.green, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => _joinEvent(event),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text("Join Event", style: TextStyle(fontSize: 16, color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
