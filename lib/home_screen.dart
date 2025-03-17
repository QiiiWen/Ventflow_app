import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'attendee_screen.dart';
import 'profile_screen.dart';
import 'ongoingevents_screen.dart';
import 'for_you_page.dart';
import 'chatbot.dart';
import 'speaker_screen.dart';
import 'application_form_screen.dart';
import 'sttalt.dart'; // Record Summarize Page
import 'exhibitor_screen.dart';

class HomeScreen extends StatefulWidget {
  final String firstName;
  final String userId;
  final String role;

  HomeScreen({required this.firstName, required this.userId, required this.role});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isExpanded = false;

  late AnimationController _animationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _fabAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isExpanded = false;
      _animationController.reverse();
    });
  }

  void _toggleFAB() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }
  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              _getHomeScreen(),
              OngoingEventsScreen(userId: widget.userId),
              ForYouPage(userId: widget.userId),
              ChatbotApp(),
              ProfileScreen(userId: widget.userId, loggedInUserId: widget.userId),
            ],
          ),

          // Expandable Buttons - Above FAB
          Positioned(
            bottom: 40,
            child: IgnorePointer(
              ignoring: !_isExpanded,
              child: AnimatedOpacity(
                opacity: _isExpanded ? 1.0 : 0.0,
                duration: Duration(milliseconds: 200),
                child: Column(
                  children: [
                    _buildExpandableButton(
                      icon: Icons.chat,
                      color: Colors.blue,
                      onPressed: () => _onItemTapped(3), // ✅ Now switches to ChatbotApp
                      heroTag: "chatbot",
                    ),
                    SizedBox(height: 10),
                    _buildExpandableButton(
                      icon: Icons.mic,
                      color: Colors.green,
                      onPressed: () => _navigateTo(RecordSummarizePage()),
                      heroTag: "record",
                    ),
                    SizedBox(height: 10),
                    if (widget.role == "speaker")
                      _buildExpandableButton(
                        icon: Icons.article,
                        color: Colors.red,
                        onPressed: () => _navigateTo(ApplicationFormScreen()),
                        heroTag: "application",
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ✅ Floating Action Button for Extra Features
      floatingActionButton: FloatingActionButton(
        heroTag: "expandable_fab",
        backgroundColor: Colors.purple,
        onPressed: _toggleFAB,
        child: RotationTransition(
          turns: _fabAnimation,
          child: Icon(_isExpanded ? Icons.close : Icons.add, color: Colors.white, size: 28),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ✅ Bottom Navigation Bar (Now includes Chatbot)
      bottomNavigationBar: BottomAppBar(
        color: Color(0xFF040B41),
        shape: CircularNotchedRectangle(),
        notchMargin: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, "", 0),
              _buildNavItem(Icons.event, "", 1),
              SizedBox(width: 50),
              _buildNavItem(Icons.explore, "", 2), // ✅ Now navigates to ChatbotApp
              _buildNavItem(Icons.person, "", 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String heroTag,
  }) {
    return FloatingActionButton(
      heroTag: heroTag,
      backgroundColor: color,
      mini: true, // ✅ Smaller button size
      child: Icon(icon, color: Colors.white),
      onPressed: onPressed,
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _selectedIndex == index ? Colors.white : Colors.white54, size: 28),
          SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _getHomeScreen() {
    if (widget.role == "attendee") {
      return AttendeeScreen(firstName: widget.firstName, userId: widget.userId);
    } else if (widget.role == "speaker") {
      return SpeakerScreen(firstName: widget.firstName, userId: widget.userId);
    }
    else if (widget.role == "exhibitor") {
      return ExhibitorScreen(firstName: widget.firstName, userId: widget.userId);
    }
    return Center(child: Text("Role not recognized", style: GoogleFonts.sen(color: Colors.white)));
  }
}
