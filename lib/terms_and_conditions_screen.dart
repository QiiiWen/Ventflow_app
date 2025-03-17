import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This is the full text you provided, broken into paragraphs for clarity.
    // You can also store it as one long string if you prefer.
    const String effectiveDate = "Effective Date: 1 Jan 2024\n\n";
    const String welcomeText =
        "Welcome to VentFlow. These Terms and Conditions (\"Terms\") govern your use of our mobile application (the \"App\"). "
        "By accessing or using the App, you agree to be bound by these Terms. If you do not agree to these Terms, please do not use the App.\n\n";

    const String section1 =
        "1. Use of the App\n"
        "• You must be at least [insert age] years old to use the App.\n"
        "• You agree to use the App only for lawful purposes and in accordance with these Terms.\n"
        "• You agree not to use the App in any way that could harm us or any third party.\n\n";

    const String section2 =
        "2. User Accounts\n"
        "• You may need to create an account to use certain features of the App.\n"
        "• You agree to provide accurate and complete information when creating an account.\n"
        "• You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account.\n\n";

    const String section3 =
        "3. Intellectual Property\n"
        "All content, features, and functionality of the App, including text, graphics, logos, and software, are the property of VentFlow or its licensors and are protected by intellectual property laws.\n"
        "You may not reproduce, distribute, modify, or create derivative works from any content on the App without our prior written consent.\n\n";

    const String section4 =
        "4. Disclaimers\n"
        "The App is provided \"as is\" and \"as available\" without warranties of any kind, either express or implied.\n"
        "We do not warrant that the App will be uninterrupted, secure, or error-free.\n\n";

    const String section5 =
        "5. Limitation of Liability\n"
        "To the fullest extent permitted by law, we will not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the App.\n"
        "Our total liability to you for any claims arising out of or related to these Terms or the App shall not exceed the amount you paid us, if any, for access to and use of the App.\n\n";

    const String section6 =
        "6. Governing Law\n"
        "These Terms shall be governed by and construed in accordance with the laws of [Your Country/State], without regard to its conflict of law principles.\n\n";

    const String section7 =
        "7. Changes to These Terms\n"
        "We may modify these Terms at any time. We will notify you of any changes by posting the new Terms on the App. "
        "Your continued use of the App after such changes constitutes your acceptance of the new Terms.\n\n";

    const String contactText =
        "Contact Us\n"
        "If you have any questions about these Terms, please contact us at [Contact Information].";

    return Scaffold(
      // Matches the style from your other screens
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
                        "Terms & Conditions",
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
              // Content
              Text(
                effectiveDate,
                style: GoogleFonts.sen(fontSize: 16, color: Colors.white70),
              ),
              Text(
                welcomeText,
                style: GoogleFonts.sen(fontSize: 16, color: Colors.white70),
              ),
              Text(
                section1,
                style: GoogleFonts.sen(fontSize: 16, color: Colors.white70),
              ),
              Text(
                section2,
                style: GoogleFonts.sen(fontSize: 16, color: Colors.white70),
              ),
              Text(
                section3,
                style: GoogleFonts.sen(fontSize: 16, color: Colors.white70),
              ),
              Text(
                section4,
                style: GoogleFonts.sen(fontSize: 16, color: Colors.white70),
              ),
              Text(
                section5,
                style: GoogleFonts.sen(fontSize: 16, color: Colors.white70),
              ),
              Text(
                section6,
                style: GoogleFonts.sen(fontSize: 16, color: Colors.white70),
              ),
              Text(
                section7,
                style: GoogleFonts.sen(fontSize: 16, color: Colors.white70),
              ),
              Text(
                contactText,
                style: GoogleFonts.sen(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
