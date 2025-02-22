import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final String userId;
  final String? transactionId;

  OrderConfirmationScreen({required this.userId, this.transactionId});

  @override
  _OrderConfirmationScreenState createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  Map<String, dynamic>? _ticket;
  bool _isLoading = true;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchTicket();
  }

  /// ✅ **Fetch ticket details from Supabase**
  Future<void> _fetchTicket() async {
    try {
      final response = await supabase
          .from('tickets')
          .select('*')
          .eq(widget.transactionId != null ? 'transaction_id' : 'user_id',
          widget.transactionId ?? widget.userId)
          .maybeSingle(); // Fetch single ticket

      if (response != null) {
        setState(() {
          _ticket = response;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (error) {
      print("Error fetching ticket: $error");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF040B41),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : _ticket == null
            ? Text("No Ticket Found",
            style: GoogleFonts.sen(color: Colors.white, fontSize: 18))
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        supabase.storage
                            .from('event-banners')
                            .getPublicUrl(_ticket!['banner']),
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.network(
                                "https://via.placeholder.com/300"),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text("Your Order Was Successful!",
                        style: GoogleFonts.sen(
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text(
                      "Your ticket has been sent to your email with all details.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sen(fontSize: 14),
                    ),
                    SizedBox(height: 20),

                    // ✅ **Generate Barcode for Transaction ID**
                    BarcodeWidget(
                      barcode: Barcode.code128(),
                      data: _ticket!['transaction_id'] ??
                          "UNKNOWN_CODE",
                      width: 200,
                      height: 80,
                      drawText: false, // Hide auto text
                    ),
                    SizedBox(height: 10),
                    Text(
                      _ticket!['transaction_id'] ?? "UNKNOWN_CODE",
                      style: GoogleFonts.sen(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),

                    // ✅ **Continue Button**
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text("CONTINUE",
                          style: GoogleFonts.sen(
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
