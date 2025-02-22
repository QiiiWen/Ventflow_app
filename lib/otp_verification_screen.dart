import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'change_password_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  OTPVerificationScreen({required this.email});

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  List<TextEditingController> otpControllers =
  List.generate(6, (index) => TextEditingController());
  List<FocusNode> otpFocusNodes = List.generate(6, (index) => FocusNode());
  bool isLoading = false;
  final supabase = Supabase.instance.client;

  // ✅ Verify OTP with Supabase Auth
  Future<void> verifyOTP() async {
    String otp = otpControllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      _showMessage("Please enter a 6-digit OTP", Colors.red);
      return;
    }

    setState(() => isLoading = true);

    try {
      // ✅ Verify OTP using Supabase Auth
      final response = await supabase.auth.verifyOTP(
        type: OtpType.email,
        email: widget.email,
        token: otp,
      );

      if (response.user != null) {
        _showMessage("OTP verified!", Colors.green);

        // ✅ Navigate to Change Password Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChangePasswordScreen(email: widget.email)),
        );
      } else {
        throw "Invalid OTP, try again!";
      }
    } catch (error) {
      _showMessage(error.toString(), Colors.red);
    }

    setState(() => isLoading = false);
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6850F6), Color(0xFF040B41)],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 60),
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              SizedBox(height: 20),
              Text("Verify OTP", style: GoogleFonts.sen(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("Enter the 6-digit code sent to your email", style: GoogleFonts.sen(fontSize: 16, color: Colors.white70)),
              SizedBox(height: 5),
              Text(widget.email, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              SizedBox(height: 30),
              Text("Enter OTP", style: GoogleFonts.sen(fontSize: 16, color: Colors.white70)),
              SizedBox(height: 10),

              // 🔹 OTP Input Fields (6-digit)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Center(
                      child: TextField(
                        controller: otpControllers[index],
                        focusNode: otpFocusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: TextStyle(color: Colors.white, fontSize: 24),
                        decoration: InputDecoration(counterText: "", border: InputBorder.none),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            FocusScope.of(context).requestFocus(otpFocusNodes[index + 1]);
                          }
                        },
                      ),
                    ),
                  );
                }),
              ),

              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: isLoading ? null : verifyOTP,
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("VERIFY", style: GoogleFonts.sen(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
