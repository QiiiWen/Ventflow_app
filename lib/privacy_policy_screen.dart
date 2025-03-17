import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF040B41), Color(0xFF040B41)],
          ),
        ),
        child: SingleChildScrollView(
          // Use MediaQuery padding to respect the notch and bottom area.
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with back button and centered title
              Row(
                children: [
                  // Back Button
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  // Expanded title in center
                  Expanded(
                    child: Center(
                      child: Text(
                        "Privacy Policy",
                        style: GoogleFonts.sen(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  // Invisible icon to balance the row
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.transparent),
                    onPressed: () {},
                  ),
                ],
              ),
              SizedBox(height: 20),
              // Effective Date
              Text(
                "Effective Date: 1 Jan 2024",
                style: GoogleFonts.sen(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 20),
              // Main content
              Text(
                "VentFlow is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application (the \"App\"). Please read this policy carefully to understand our practices regarding your personal data.",
                style: GoogleFonts.sen(fontSize: 16, color: Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                "1. Information We Collect",
                style: GoogleFonts.sen(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Personal Information: We may collect personal information such as your name, email address, phone number, and event details when you register for an account or use our services.\n\n"
                    "Usage Data: We collect information about your interactions with the App, including the pages you visit, the features you use, and the time and date of your visits.\n\n"
                    "Device Information: We collect information about the device you use to access the App, including the hardware model, operating system, and device identifiers.",
                style: GoogleFonts.sen(fontSize: 16, color: Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                "2. How We Use Your Information",
                style: GoogleFonts.sen(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "We use the information we collect to:\n\n"
                    "- Provide, operate, and maintain the App\n"
                    "- Improve, personalize, and expand our services\n"
                    "- Communicate with you, including sending updates and promotional materials\n"
                    "- Monitor and analyze usage and trends to improve user experience\n"
                    "- Detect, prevent, and address technical issues",
                style: GoogleFonts.sen(fontSize: 16, color: Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                "3. Sharing Your Information",
                style: GoogleFonts.sen(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "We do not share your personal information with third parties except:\n\n"
                    "- With your consent\n"
                    "- For external processing (e.g., service providers who assist us)\n"
                    "- To comply with legal obligations\n"
                    "- To protect our rights and safety, or the rights and safety of our users",
                style: GoogleFonts.sen(fontSize: 16, color: Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                "4. Data Security",
                style: GoogleFonts.sen(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "We implement appropriate security measures to protect your personal information from unauthorized access, disclosure, alteration, and destruction. However, no internet or electronic storage method is 100% secure.",
                style: GoogleFonts.sen(fontSize: 16, color: Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                "5. Your Rights",
                style: GoogleFonts.sen(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Depending on your location, you may have the following rights regarding your personal information:",
                style: GoogleFonts.sen(fontSize: 16, color: Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                "6. Changes to This Privacy Policy",
                style: GoogleFonts.sen(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy on this page. You are advised to review this Privacy Policy periodically for any changes.",
                style: GoogleFonts.sen(fontSize: 16, color: Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                "Contact Us",
                style: GoogleFonts.sen(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "If you have any questions about this Privacy Policy, please contact us at [Contact Information].",
                style: GoogleFonts.sen(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
