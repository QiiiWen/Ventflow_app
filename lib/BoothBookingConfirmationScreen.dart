import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'BuyBoothScreen.dart';

class BoothBookingConfirmationScreen extends StatefulWidget {
  final int eventId;
  final String userId;
  final int boothId;

  const BoothBookingConfirmationScreen({
    Key? key,
    required this.eventId,
    required this.userId,
    required this.boothId,
  }) : super(key: key);

  @override
  _BoothBookingConfirmationScreenState createState() => _BoothBookingConfirmationScreenState();
}

class _BoothBookingConfirmationScreenState extends State<BoothBookingConfirmationScreen> {
  Map<String, dynamic>? _booth;
  bool _isLoading = true;
  bool _hasError = false;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchBoothDetails();
  }

  /// ✅ Fetch booked booth details from database
  Future<void> _fetchBoothDetails() async {
    try {
      final response = await supabase
          .from('booths')
          .select('booth_number, size, price, description, features')
          .eq('id', widget.boothId)
          .single();

      if (mounted) {
        setState(() {
          _booth = response;
          _isLoading = false;
        });
      }
    } catch (error) {
      print("❌ Error fetching booth details: $error");
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Booth Booking Confirmation")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hasError || _booth == null
          ? Center(child: Text("❌ Error loading booth details"))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Icon(Icons.check_circle, color: Colors.green, size: 100)),
            SizedBox(height: 20),
            Center(
              child: Text(
                "Booth Successfully Reserved!",
                style: GoogleFonts.sen(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),

            // ✅ Booth Details
            Card(
              elevation: 2,
              color: Colors.white,
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 5),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("📍 Booth Number: ${_booth!['booth_number']}",
                        style: GoogleFonts.sen(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("📏 Size: ${_booth!['size'] ?? 'Not specified'}",
                        style: GoogleFonts.sen(fontSize: 14)),
                    SizedBox(height: 8),
                    Text("💰 Price: RM ${_booth!['price']}",
                        style: GoogleFonts.sen(fontSize: 14)),
                    SizedBox(height: 8),
                    Text("📌 Description: ${_booth!['description'] ?? 'No description'}",
                        style: GoogleFonts.sen(fontSize: 14)),
                    SizedBox(height: 8),
                    Text("🔹 Features: ${( _booth!['features'] as List?)?.join(', ') ?? 'No features available'}",
                        style: GoogleFonts.sen(fontSize: 14)),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BuyBoothScreen(
                        eventId: widget.eventId.toString(),
                        userId: widget.userId,
                        selectedBooths: [widget.boothId.toString()],
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: Text("Proceed to Payment", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
