import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'attendee_screen.dart';
import 'profile_screen.dart';
import 'ongoingevents_screen.dart';
import 'for_you_page.dart';
import 'chatbot.dart'; // ✅ Import AI Chatbot screen

class HomeScreen extends StatefulWidget {
  final String firstName;
  final String userId;
  final String role;

  HomeScreen({required this.firstName, required this.userId, required this.role});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Tracks active tab

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // ✅ **Only Attendee's Screens** + AI Chat
    _screens = [
      AttendeeScreen(firstName: widget.firstName, userId: widget.userId),
      OngoingEventsScreen(userId: widget.userId), // Ongoing purchased events
      ForYouPage(userId: widget.userId),        // Social feed
      ChatbotApp(),     // AI Chat
      ProfileScreen(userId: widget.userId, loggedInUserId: widget.userId),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF040B41),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: "Ongoing",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: "For You",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: "AI Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
