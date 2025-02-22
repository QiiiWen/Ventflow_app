import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'profile_screen.dart';

class QRScannerScreen extends StatefulWidget {
  final String loggedInUserId;

  const QRScannerScreen({Key? key, required this.loggedInUserId}) : super(key: key);

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool isProcessing = false;

  void _handleScannedData(String scannedData, MobileScannerController controller) {
    if (isProcessing) return;

    final Uri? uri = Uri.tryParse(scannedData);

    if (uri != null && uri.scheme == "ventflow") {
      setState(() {
        isProcessing = true;
      });

      String? userId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;

      if (userId != null) {
        controller.stop(); // Stop scanning after a successful scan

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              userId: userId,
              loggedInUserId: widget.loggedInUserId,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    MobileScannerController scannerController = MobileScannerController();

    return Scaffold(
      backgroundColor: const Color(0xFF040B41),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Scan QR Code",
          style: GoogleFonts.sen(fontSize: 20, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            scannerController.stop();
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: (barcodeCapture) {
              final List<Barcode> barcodes = barcodeCapture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleScannedData(barcode.rawValue!, scannerController);
                  break; // Stop after first valid scan
                }
              }
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.all(15),
              color: Colors.black54,
              child: Text(
                "Point the camera at a VentFlow QR Code",
                style: GoogleFonts.sen(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
