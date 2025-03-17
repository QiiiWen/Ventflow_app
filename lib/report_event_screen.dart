import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportEventScreen extends StatefulWidget {
  final int eventId;
  final String eventName;

  ReportEventScreen({required this.eventId, required this.eventName});

  @override
  _ReportEventScreenState createState() => _ReportEventScreenState();
}

class _ReportEventScreenState extends State<ReportEventScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImage;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();
  final supabase = Supabase.instance.client;

  /// Pick an image from the gallery.
  Future<void> _pickImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  /// Capture an image using the camera.
  Future<void> _takePhoto() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error taking photo: $e");
    }
  }

  /// Submit the report by uploading the image (if any) and inserting the report details into Supabase.
  Future<void> _submitReport() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please describe the issue.", style: GoogleFonts.sen())),
      );
      return;
    }
    setState(() {
      _isSubmitting = true;
    });

    String? imageUrl;
    try {
      if (_selectedImage != null) {
        final fileName = 'report_${widget.eventId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final fileBytes = await _selectedImage!.readAsBytes();
        // Upload the image to the "event-reports" bucket.
        await supabase
            .storage
            .from('event-reports')
            .uploadBinary(fileName, fileBytes);
        // Retrieve the public URL for the uploaded image.
        imageUrl = supabase.storage.from('event-reports').getPublicUrl(fileName);
      }

      final reportData = {
        'event_id': widget.eventId,
        'issue_description': _descriptionController.text.trim(),
        'image_url': imageUrl ?? '',
      };

      final List<dynamic> response = await supabase
          .from('event_reports')
          .insert([reportData])
          .select();

      if (response.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Report submitted successfully.", style: GoogleFonts.sen())),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Submission failed, try again.", style: GoogleFonts.sen())),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e", style: GoogleFonts.sen())),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final minHeight = mediaQuery.size.height - mediaQuery.padding.top - mediaQuery.padding.bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Report Event Issue",
          style: GoogleFonts.sen(color: Colors.white, fontSize: 20),
        ),
      ),
      body: Stack(
        children: [
          // Background gradient.
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF040B41), Color(0xFF040B41)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Main content.
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Indication of which event is being reported.
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Reporting for: ${widget.eventName}",
                          style: GoogleFonts.sen(fontSize: 16, color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Image preview.
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                            : Center(
                          child: Text(
                            "No image selected",
                            style: GoogleFonts.sen(color: Colors.white70),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      // Row with Gallery and Camera buttons.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImageFromGallery,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF674DFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            icon: Icon(Icons.photo, color: Colors.white),
                            label: Text("Gallery", style: GoogleFonts.sen(color: Colors.white)),
                          ),
                          ElevatedButton.icon(
                            onPressed: _takePhoto,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF674DFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            icon: Icon(Icons.camera_alt, color: Colors.white),
                            label: Text("Camera", style: GoogleFonts.sen(color: Colors.white)),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      // Description field.
                      TextField(
                        controller: _descriptionController,
                        maxLines: 5,
                        style: GoogleFonts.sen(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Describe the issue",
                          labelStyle: GoogleFonts.sen(color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Submit button.
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF674DFF),
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isSubmitting
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text("Submit Report", style: GoogleFonts.sen(fontSize: 18, color: Colors.white)),
                        ),
                      ),
                      Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
