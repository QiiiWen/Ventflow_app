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

  /// ✅ **Save Ticket Details to Supabase**
  Future<void> _confirmTicketPurchase() async {
    try {
      final response = await supabase.from('tickets').insert({
        'user_id': widget.userId,
        'event_id': widget.eventId,
        'quantity': _quantity,
        'total_price': _finalAmount,
        'status': 'Paid',
      }).select().single();

      if (response != null) {
        String transactionId = response['id'].toString();

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

                  // ✅ **Quantity Selector**
                  _buildQuantitySelector(),

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

  /// 📌 **Quantity Selector**
  Widget _buildQuantitySelector() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF6850F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Quantity:", style: GoogleFonts.sen(fontSize: 18, color: Colors.white)),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove_circle_outline, color: Colors.white),
                onPressed: () => setState(() => _quantity = (_quantity > 1) ? _quantity - 1 : 1),
              ),
              Text("$_quantity", style: GoogleFonts.sen(fontSize: 18, color: Colors.white)),
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: Colors.white),
                onPressed: () => setState(() => _quantity++),
              ),
            ],
          ),
        ],
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
          _buildOrderRow("Tickets", "\RM${widget.eventPrice.toStringAsFixed(2)}"),
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
