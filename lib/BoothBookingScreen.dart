import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'BoothBookingConfirmationScreen.dart';

class BoothBookingScreen extends StatefulWidget {
  final int eventId;
  final String userId;

  const BoothBookingScreen({
    Key? key,
    required this.eventId,
    required this.userId,
  }) : super(key: key);

  @override
  _BoothBookingScreenState createState() => _BoothBookingScreenState();
}

class _BoothBookingScreenState extends State<BoothBookingScreen> {
  List<dynamic> _booths = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isBooking = false;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchAvailableBooths();
  }

  /// ✅ Fetch available booths for the event
  Future<void> _fetchAvailableBooths() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await supabase
          .from('booths')
          .select('id, booth_number, size, price, description, features, status')
          .eq('event_id', widget.eventId)
          .eq('status', 'available')
          .order('booth_number', ascending: true);

      if (mounted) {
        setState(() {
          _booths = response;
          _isLoading = false;
        });
      }
    } catch (error) {
      print("❌ Error fetching booths: $error");
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _bookBooth(int boothId) async {
    if (_isBooking) return;
    setState(() => _isBooking = true);

    try {
      print("🟢 Booking booth ID: $boothId for user ${widget.userId} in event ${widget.eventId}");

      // ✅ Insert into booth_bookings table
      final bookingResponse = await supabase.from('booth_bookings').insert({
        'booth_id': boothId,
        'exhibitor_id': widget.userId,
        'event_id': widget.eventId,
        'status': 'reserved'
      }).select(); // Add select() to check what was inserted

      print("✅ Booth booked successfully! Booking response: $bookingResponse");

      // ✅ Update booth status to "reserved"
      final updateResponse = await supabase.from('booths')
          .update({'status': 'reserved'})
          .eq('id', boothId)
          .select(); // Add select() to check what was updated

      print("✅ Booth status updated! Update response: $updateResponse");

      // ✅ Navigate to BoothBookingConfirmationScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BoothBookingConfirmationScreen(
            eventId: widget.eventId,
            userId: widget.userId,
            boothId: boothId,
          ),
        ),
      );
    } catch (error) {
      print("❌ Error booking booth: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error booking booth. Try again!")),
      );
    } finally {
      setState(() => _isBooking = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Book a Booth")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hasError
          ? Center(child: Text("❌ Error loading booths"))
          : _booths.isEmpty
          ? Center(child: Text("No available booths for this event."))
          : ListView.builder(
        itemCount: _booths.length,
        itemBuilder: (context, index) {
          final booth = _booths[index];

          return Card(
            color: Colors.white,
            elevation: 2,
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: ListTile(
              title: Text(
                "Booth ${booth['booth_number']} - ${booth['size'] ?? 'Not specified'}",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("💰 RM ${booth['price']?.toString() ?? 'Not available'}"),
                  Text("📌 ${booth['description'] ?? 'No description available'}"),
                  Text("🔹 Features: ${(booth['features'] as List?)?.join(', ') ?? 'No features available'}"),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () => _bookBooth(booth['id']),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text("Book", style: TextStyle(color: Colors.white)),
              ),
            ),
          );
        },
      ),
    );
  }
}
