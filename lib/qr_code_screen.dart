import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QRCodeScreen extends StatefulWidget {
  final String userId;

  const QRCodeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _QRCodeScreenState createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  final supabase = Supabase.instance.client;
  String? qrData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQRCode();
  }

  /// 📥 **Fetch QR Code from Supabase**
  Future<void> _fetchQRCode() async {
    try {
      final response = await supabase
          .from('user_profiles')
          .select('qr_code_url')
          .eq('user_id', widget.userId)
          .maybeSingle();

      setState(() {
        qrData = response?['qr_code_url'] ?? "ventflow://profile/${widget.userId}";
        isLoading = false;
      });

      print("✅ QR Code Loaded: $qrData");
    } catch (e) {
      print("❌ Error fetching QR Code: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  /// 🔄 **Generate and Store New QR Code**
  Future<void> _generateAndStoreQRCode() async {
    setState(() {
      isLoading = true;
    });

    String newQRData = "ventflow://profile/${widget.userId}";

    try {
      await supabase
          .from('user_profiles')
          .update({'qr_code_url': newQRData})
          .eq('user_id', widget.userId);

      setState(() {
        qrData = newQRData;
        isLoading = false;
      });

      print("✅ QR Code Updated: $newQRData");
    } catch (e) {
      print("❌ Error updating QR Code: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040B41), // Dark blue background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "My QR Code",
          style: GoogleFonts.sen(fontSize: 20, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _generateAndStoreQRCode, // ✅ Regenerate QR Code
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : Center(
        child: Container(
          width: 350,
          padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Scan this QR to view\nyour profile",
                style: GoogleFonts.sen(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              QrImageView(
                data: qrData ?? "ventflow://profile/${widget.userId}",
                version: QrVersions.auto,
                size: 250,
                gapless: false,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _generateAndStoreQRCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: Text("Regenerate QR Code"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
