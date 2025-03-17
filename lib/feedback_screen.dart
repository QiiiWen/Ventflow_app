import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackScreen extends StatefulWidget {
  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  // Text controllers for the form fields
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();

  // Ratings
  int _experienceRating = 0; // 1–5 stars
  int _easeOfAccomplishment = 1; // 1–5 scale

  // Initialize the Supabase client
  final supabase = Supabase.instance.client;

  Future<void> _submitFeedback() async {
    final topic = _topicController.text.trim();
    final feedbackText = _feedbackController.text.trim();
    final primaryGoal = _goalController.text.trim();

    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a topic')),
      );
      return;
    }

    final Map<String, dynamic> feedbackData = {
      'topic': topic,
      'rating': _experienceRating,
      'feedback_text': feedbackText,
      'primary_goal': primaryGoal,
      'ease_of_accomplishment': _easeOfAccomplishment,
    };

    try {
      // Insert returns a list of inserted rows.
      final List<dynamic> response = await supabase
          .from('feedback')
          .insert([feedbackData])
          .select();

      if (response.isNotEmpty) {
        // Success: clear fields and reset ratings.
        _topicController.clear();
        _feedbackController.clear();
        _goalController.clear();
        setState(() {
          _experienceRating = 0;
          _easeOfAccomplishment = 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feedback submitted successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit feedback.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }



  @override
  void dispose() {
    _topicController.dispose();
    _feedbackController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBody ensures our gradient fills behind system UI
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        // Full-screen gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF040B41), Color(0xFF040B41)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Back button and title text
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Send a Feedback Form",
                                  style: GoogleFonts.sen(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        // Main Content
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1) Topic Input
                              Text(
                                "First, what would you like to tell us about?",
                                style: GoogleFonts.sen(fontSize: 16, color: Colors.white70),
                              ),
                              SizedBox(height: 5),
                              TextField(
                                controller: _topicController,
                                style: TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  hintText: "Please write here...",
                                  hintStyle: TextStyle(color: Colors.grey),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              // 2) Experience Rating
                              Text(
                                "How was your experience?",
                                style: GoogleFonts.sen(fontSize: 16, color: Colors.white70),
                              ),
                              SizedBox(height: 5),
                              Row(
                                children: List.generate(5, (index) {
                                  return IconButton(
                                    icon: Icon(
                                      index < _experienceRating ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 30,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _experienceRating = index + 1;
                                      });
                                    },
                                  );
                                }),
                              ),
                              // Additional Feedback Input
                              Text(
                                "We'd love to hear your feedback. What was positive? What can we improve?",
                                style: GoogleFonts.sen(fontSize: 14, color: Colors.white70),
                              ),
                              SizedBox(height: 5),
                              TextField(
                                controller: _feedbackController,
                                maxLines: 3,
                                style: TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  hintText: "Please write here...",
                                  hintStyle: TextStyle(color: Colors.grey),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              // 3) Primary Goal Input
                              Text(
                                "What was your primary goal for today's visit?",
                                style: GoogleFonts.sen(fontSize: 16, color: Colors.white70),
                              ),
                              SizedBox(height: 5),
                              TextField(
                                controller: _goalController,
                                style: TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  hintText: "Please write here...",
                                  hintStyle: TextStyle(color: Colors.grey),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              // 4) Ease of Accomplishment (Radio Buttons)
                              Text(
                                "How easy was it to accomplish that goal?",
                                style: GoogleFonts.sen(fontSize: 16, color: Colors.white70),
                              ),
                              SizedBox(height: 5),
                              Row(
                                children: List.generate(5, (index) {
                                  int value = index + 1;
                                  return Row(
                                    children: [
                                      Radio<int>(
                                        value: value,
                                        groupValue: _easeOfAccomplishment,
                                        activeColor: Colors.amber,
                                        onChanged: (val) {
                                          setState(() {
                                            _easeOfAccomplishment = val ?? 1;
                                          });
                                        },
                                      ),
                                      Text("$value", style: TextStyle(color: Colors.white)),
                                    ],
                                  );
                                }),
                              ),
                              SizedBox(height: 20),
                              // Submit Button
                              Center(
                                child: ElevatedButton(
                                  onPressed: _submitFeedback,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF674DFF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                  ),
                                  child: Text(
                                    "Submit",
                                    style: GoogleFonts.sen(fontSize: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                        // Spacer to push content to fill available height
                        Expanded(child: Container()),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
