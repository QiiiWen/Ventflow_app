import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApplicationFormScreen extends StatefulWidget {
  @override
  _ApplicationFormScreenState createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  // Removed _titleController since we are using a dropdown now.
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();

  bool _agreedToTerms = false;
  bool _isSubmitting = false;

  // List of events fetched from Supabase.
  List<dynamic> _events = [];
  // Currently selected event.
  dynamic _selectedEvent;

  // Initialize Supabase client.
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  /// Fetch available events from Supabase.
  Future<void> _fetchEvents() async {
    try {
      final List<dynamic> data = await supabase.from('events').select();
      setState(() {
        _events = data;
        if (_events.isNotEmpty) {
          _selectedEvent = _events[0];
        }
      });
    } catch (e) {
      print("Error fetching events: $e");
    }
  }

  Future<void> _submitApplication() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You must agree to the terms and conditions")),
      );
      return;
    }
    if (_selectedEvent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select an event.")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Insert data using the selected event's id.
      final List<dynamic> data = await supabase.from('applications').insert([
        {
          'contact_name': _contactNameController.text,
          'contact_number': _contactNumberController.text,
          'event_id': _selectedEvent['id'], // Use event id instead of title text.
          'description': _descriptionController.text,
          'requirements': _requirementsController.text,
          'availability': _availabilityController.text,
        }
      ]).select();

      setState(() {
        _isSubmitting = false;
      });

      // Debug logging.
      print("Inserted data: $data");

      if (data.isNotEmpty) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Submission failed, try again!")),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      print("Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submission failed, try again!")),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.deepPurpleAccent,
          title: Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 10),
              Text("Success!",
                  style: GoogleFonts.sen(fontSize: 22, color: Colors.white)),
            ],
          ),
          content: Text(
            "Your application has been received. You will be notified within 24 hours. Thank you!",
            style: GoogleFonts.sen(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Okay",
                    style:
                    GoogleFonts.sen(color: Colors.green, fontSize: 18)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _contactNameController.dispose();
    _contactNumberController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _availabilityController.dispose();
    super.dispose();
  }

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
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                "Application Form",
                style: GoogleFonts.sen(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Be the speaker at your preferred event!",
                style: GoogleFonts.sen(fontSize: 16, color: Colors.white70),
              ),
              SizedBox(height: 20),
              _buildTextField(_contactNameController, "Contact name"),
              _buildTextField(_contactNumberController, "Contact Number"),
              // Dropdown field for selecting event.
              _buildEventDropdown(),
              _buildTextField(
                  _descriptionController, "Brief Summary / Description"),
              _buildTextField(_requirementsController, "Special Requirements"),
              _buildTextField(_availabilityController, "Availability"),
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreedToTerms = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      "I agree to the terms and conditions of speaking at this event.",
                      style: GoogleFonts.sen(color: Colors.white70),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isSubmitting ? null : _submitApplication,
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  "SUBMIT",
                  style:
                  GoogleFonts.sen(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          enabledBorder:
          OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
          focusedBorder:
          OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        ),
      ),
    );
  }

  /// Build a dropdown menu populated with the available events.
  Widget _buildEventDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<dynamic>(
        decoration: InputDecoration(
          labelText: "Select Interested Event",
          labelStyle: TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white70)),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white)),
        ),
        dropdownColor: Color(0xFF040B41),
        style: TextStyle(color: Colors.white),
        value: _selectedEvent,
        items: _events.map((event) {
          return DropdownMenuItem(
            value: event,
            child: Text(event['name'] ?? 'Untitled'),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedEvent = value;
          });
        },
      ),
    );
  }
}
