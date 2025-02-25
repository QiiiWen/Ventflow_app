import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'dart:convert';
import 'OrderConfirmationScreen.dart';

class BuyTicketScreen extends StatefulWidget {
  final int eventId;
  final String eventName;
  final String userId;
  final double eventPrice;
  final String organizer;
  final String bannerUrl;

  BuyTicketScreen({
    required this.eventId,
    required this.eventName,
    required this.userId,
    required this.eventPrice,
    required this.organizer,
    required this.bannerUrl,
  });

  @override
  _BuyTicketScreenState createState() => _BuyTicketScreenState();
}

class _BuyTicketScreenState extends State<BuyTicketScreen> {
  int _quantity = 1;
  bool _isProcessing = false;
  final supabase = Supabase.instance.client;

  double get _totalPrice => _quantity * widget.eventPrice;
  double get _serviceFee => _totalPrice * 0.06;
  double get _finalAmount => _totalPrice + _serviceFee + 1.00;

  Future<String?> _createPaymentIntent() async {
    try {
      final response = await supabase.functions.invoke('create_payment', body: {
        'amount': (_finalAmount * 100).toInt(),
      });

      print("📢 Supabase Response: $response"); // Debugging log

      if (response == null || !response.data.containsKey('clientSecret')) {
        print("❌ Error: Response is null or missing 'clientSecret'");
        return null;
      }

      return response.data['clientSecret'];
    } catch (error) {
      print("❌ Error creating payment intent: $error");
      return null;
    }
  }




  /// ✅ **Handle Stripe Payment**
  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      // 🔹 Step 1: Get Payment Intent from Supabase
      String? clientSecret = await _createPaymentIntent();
      if (clientSecret == null) throw Exception("Failed to get payment intent");

      // 🔹 Step 2: Initialize Stripe Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: "VentFlow",
        ),
      );

      // 🔹 Step 3: Show Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // 🔹 Step 4: Confirm Ticket Purchase in Supabase
      await _confirmTicketPurchase();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment failed: $e")),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmTicketPurchase() async {
    try {
      // ✅ Step 1: Check if the user already has a ticket for this event
      final existingTicket = await supabase
          .from('tickets')
          .select('id')
          .eq('user_id', widget.userId)
          .eq('event_id', widget.eventId)
          .maybeSingle(); // Returns null if no ticket exists

      if (existingTicket != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You have already purchased a ticket for this event!")),
        );
        return;
      }

      // ✅ Step 2: Generate a unique ticket code & transaction ID
      String ticketCode = _generateTicketCode();
      String transactionId = _generateTransactionId();

      // ✅ Step 3: Insert the new ticket with a transaction ID
      final response = await supabase.from('tickets').insert({
        'user_id': widget.userId,
        'event_id': widget.eventId,
        'quantity': 1,
        'total_price': _finalAmount,
        'status': 'Paid',
        'ticket_code': ticketCode,
        'transaction_id': transactionId, // 🔹 Include generated transaction ID
      }).select().single();

      if (response != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(
              userId: widget.userId,
              transactionId: transactionId,
            ),
          ),
        );
      } else {
        throw Exception("Purchase failed. No ticket generated.");
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error confirming ticket: $error")),
      );
    }
  }

  String _generateTicketCode() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random rnd = Random();
    return List.generate(10, (index) => chars[rnd.nextInt(chars.length)]).join();
  }

  String _generateTransactionId() {
    return "TXN${DateTime.now().millisecondsSinceEpoch}";
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF040B41),
      appBar: AppBar(
        backgroundColor: Color(0xFF040B41),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Your Order",
                style: GoogleFonts.sen(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(widget.bannerUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.eventName, style: GoogleFonts.sen(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 5),
                  Text("Organized by ${widget.organizer}", style: GoogleFonts.sen(fontSize: 14, color: Colors.white60)),
                  SizedBox(height: 20),

                  // ✅ **Order Summary**
                  _buildOrderSummary(),

                  SizedBox(height: 20),

                  // ✅ **Pay Now Button**
                  _isProcessing
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _processPayment,
                    child: Center(
                      child: Text("PAY", style: GoogleFonts.sen(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📌 **Order Summary**
  Widget _buildOrderSummary() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF6850F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildOrderRow("Ticket (1)", "\RM${widget.eventPrice.toStringAsFixed(2)}"),
          _buildOrderRow("Order Processing Fee", "\RM1.00"),
          Divider(color: Colors.white24),
          _buildOrderRow("Service Fees (6%)", "\RM${_serviceFee.toStringAsFixed(2)}"),
          _buildOrderRow("Total", "\RM${_finalAmount.toStringAsFixed(2)}", isTotal: true),
        ],
      ),
    );
  }

  Widget _buildOrderRow(String title, String price, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.sen(fontSize: 16, color: Colors.white)),
        Text(price, style: GoogleFonts.sen(fontSize: 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: Colors.white)),
      ],
    );
  }
}
