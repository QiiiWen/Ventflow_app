import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // You can split long text into sections or keep it as one string
    const String introText =
        "Welcome to VentFlow!\n\n"
        "At VentFlow, we are passionate about making event management simple, efficient, and enjoyable. "
        "Our team consists of seasoned event planners, talented developers, and creative designers who "
        "have come together to build a powerful mobile application that caters to all your event management needs.\n\n"
        "Our Mission:\n\n"
        "Our mission is to transform the way events are organized and experienced. We strive to provide a comprehensive "
        "platform that empowers individuals and businesses to plan, execute, and manage events seamlessly.\n\n";

    const String outroText =
        "Join us in revolutionizing event management. Whether you are planning a small gathering or "
        "a large-scale conference, VentFlow is your go-to solution.\n\n"
        "Thank you for choosing VentFlow. Let's create unforgettable events together!";

    // We'll list out the bullet points for “What We Offer”:
    final List<String> offers = [
      "User-Friendly Interface: Intuitive design to help you navigate and use our app with ease.",
      "Comprehensive Tools: From guest lists and RSVPs to schedules and reminders, we've got you covered.",
      "Customization: Tailor your events to reflect your unique style and requirements.",
      "Real-Time Updates: Stay informed with live updates and notifications.",
      "Support: Our dedicated support team is here to help you every step of the way.",
    ];

    return Scaffold(
      // Matches the style from your ApplicationFormScreen
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
          // Adding padding using MediaQuery to account for iPhone notch and bottom safe area
          padding: EdgeInsets.only(
            top: MediaQuery
                .of(context)
                .padding
                .top + 20,
            bottom: MediaQuery
                .of(context)
                .padding
                .bottom + 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with back button and centered title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  // Centered Title
                  Text(
                    "About Us",
                    style: GoogleFonts.sen(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Placeholder to balance the row (adjust width as needed)
                  SizedBox(width: 48),
                ],
              ),
              SizedBox(height: 20),
              // Intro Text
              Text(
                introText,
                style: GoogleFonts.sen(fontSize: 16, color: Colors.white70),
              ),
              // What We Offer
              Text(
                "What We Offer:",
                style: GoogleFonts.sen(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              // Bullet points
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: offers.map((offer) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bullet icon
                        Text(
                          "•  ",
                          style: GoogleFonts.sen(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Offer text
                        Expanded(
                          child: Text(
                            offer,
                            style: GoogleFonts.sen(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              // Outro Text
              Text(
                outroText,
                style: GoogleFonts.sen(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
