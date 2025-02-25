import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final String userId;
  final String? transactionId;

  const OrderConfirmationScreen({
    required this.userId,
    this.transactionId,
    Key? key,
  }) : super(key: key);

  @override
  _OrderConfirmationScreenState createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  Map<String, dynamic>? _ticket;
  Map<String, dynamic>? _event;
  bool _isLoading = true;
  final supabase = Supabase.instance.client;
  String? transactionId;

  @override
  void initState() {
    super.initState();

    // ✅ Store transactionId from widget
    transactionId = widget.transactionId;

    // ✅ Debugging: Print transaction ID
    print("🔎 Received transactionId: $transactionId");

    // ✅ Delay fetching to ensure transactionId is assigned
    Future.delayed(Duration(milliseconds: 500), () {
      _fetchTicket();
    });
  }

  Future<void> _fetchTicket() async {
    try {
      print("🔎 Fetching ticket with:");
      print("    🆔 userId: ${widget.userId}");
      print("    🆔 transactionId: $transactionId");

      // Fetch ticket by transactionId or userId
      final response = (transactionId != null && transactionId!.isNotEmpty)
          ? await supabase
          .from('tickets')
          .select('*')
          .eq('transaction_id', transactionId!) // ✅ Fetch by transaction_id
          .maybeSingle()
          : await supabase
          .from('tickets')
          .select('*')
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // Fetch event data using event_id from the ticket
      if (response != null) {
        final eventResponse = await supabase
            .from('events')
            .select('*')
            .eq('id', response['event_id']) // Get the event data based on event_id
            .maybeSingle();

        print("✅ Event response: $eventResponse");

        if (eventResponse != null) {
          setState(() {
            _ticket = response;  // Ticket data
            _event = eventResponse;  // Event data
            _isLoading = false;
          });
        }
      } else {
        print("⚠️ No ticket found!");
        setState(() => _isLoading = false);
      }
    } catch (error) {
      print("❌ Error fetching ticket or event: $error");
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
            ? Text(
          "No Ticket Found",
          style: GoogleFonts.sen(color: Colors.white, fontSize: 18),
        )
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
                    // ✅ Handle Image Loading and Null Check
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _event != null && _event!['banner'] != null
                          ? Image.network(
                        supabase.storage
                            .from('event-banners')  // Supabase bucket name
                            .getPublicUrl(_event!['banner']?.trim() ?? ''),  // Trim the path to remove extra spaces or newlines
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                          : Container(),  // No image, just empty if no banner exists
                    ),

                    SizedBox(height: 20),
                    Text(
                      "Thank Your For Your Purchase!",
                      style: GoogleFonts.sen(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    if (_ticket != null &&
                        _ticket!['transaction_id'] != null &&
                        _ticket!['transaction_id'].isNotEmpty)
                      Column(
                        children: [
                          Text(
                            "${_ticket!['transaction_id']}",
                            style: GoogleFonts.sen(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 20),

                          // ✅ **Generate Barcode for Transaction ID**
                          BarcodeWidget(
                            barcode: Barcode.code128(), // Barcode type
                            data: _ticket!['transaction_id'], // Transaction ID for the barcode
                            width: 200,
                            height: 80,
                            drawText: false, // Don't draw text on the barcode
                          ),
                        ],
                      )
                    else
                      Text(
                        "Transaction ID not available",
                        style: GoogleFonts.sen(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red),
                      ),
                    SizedBox(height: 20),
                    Text(
                      "Your ticket has been sent to your email with all details.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sen(fontSize: 14),
                    ),
                    SizedBox(height: 20),

                    // ✅ **Continue Button**
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "continue",
                        style: GoogleFonts.sen(
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
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
