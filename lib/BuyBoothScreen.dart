import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BuyBoothScreen extends StatefulWidget {
  final String eventId;
  final String userId;
  final List<String> selectedBooths;

  const BuyBoothScreen({
    Key? key,
    required this.eventId,
    required this.userId,
    required this.selectedBooths,
  }) : super(key: key);

  @override
  _BuyBoothScreenState createState() => _BuyBoothScreenState();
}

class _BuyBoothScreenState extends State<BuyBoothScreen> {
  bool _isProcessing = false; // ✅ Added loading state

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    await Future.delayed(Duration(seconds: 2)); // Simulate processing time

    setState(() {
      _isProcessing = false;
    });

    // ✅ Show success dialog AFTER setState is complete
    if (!mounted) return; // ✅ Prevent showing dialog if widget is destroyed
    showDialog(
      context: context, // ✅ Make sure `context` is valid
      builder: (BuildContext dialogContext) { // Use new context
        return AlertDialog(
          title: Text("Payment Successful 🎉"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 80),
              SizedBox(height: 10),
              Text("Your booth has been successfully booked!"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // ✅ Use `dialogContext`
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Confirm Booth Payment", style: GoogleFonts.sen())),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Icon(Icons.credit_card, color: Colors.blueAccent, size: 80)),

            SizedBox(height: 20),
            Text("Proceed to payment to finalize your booth reservation.",
                style: GoogleFonts.sen(fontSize: 18, fontWeight: FontWeight.bold)),

            Divider(height: 30, thickness: 1),

            _buildInfoRow(Icons.event, "Event ID", widget.eventId),
            _buildInfoRow(Icons.confirmation_number, "Booth(s)", widget.selectedBooths.join(', ')),

            SizedBox(height: 40),

            Center(
              child: _isProcessing
                  ? CircularProgressIndicator() // ✅ Show loading animation
                  : ElevatedButton.icon(
                onPressed: _processPayment,
                icon: Icon(Icons.payment, color: Colors.white),
                label: Text("Complete Payment", style: GoogleFonts.sen(fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700], size: 22),
          SizedBox(width: 10),
          Text(title, style: GoogleFonts.sen(fontSize: 16, fontWeight: FontWeight.w600)),
          Spacer(),
          Text(value, style: GoogleFonts.sen(fontSize: 16, color: Colors.grey[800])),
        ],
      ),
    );
  }
}
