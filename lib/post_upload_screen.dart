import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PhotoUploadScreen extends StatefulWidget {
  final String userId;

  PhotoUploadScreen({required this.userId});

  @override
  _PhotoUploadScreenState createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  final supabase = Supabase.instance.client;
  List<AssetEntity> _galleryImages = [];
  List<File> _selectedImages = [];
  Map<int, TextEditingController> _captionControllers = {}; // Stores captions per image
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 500), _loadGalleryImages); // Delay to prevent possible UI conflicts
  }


  /// Load recent images from the gallery
  Future<void> _loadGalleryImages() async {
    print("🔍 Checking permissions...");

    // ✅ Request permissions for Android 10+
    final PermissionState ps = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        iosAccessLevel: IosAccessLevel.readWrite, // iOS full access
      ),
    );

    if (!ps.hasAccess) {
      print("❌ No permission! Asking again...");

      // ✅ Ask for permission again
      final PermissionState retryPs = await PhotoManager.requestPermissionExtend();
      if (!retryPs.hasAccess) {
        print("🚨 Permission still denied! Opening settings...");
        PhotoManager.openSetting(); // Opens settings if denied
        return;
      }
    }

    print("✅ Permission granted! Loading images...");

    // ✅ Load images after permission is granted
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (albums.isNotEmpty) {
      final List<AssetEntity> media = await albums[0].getAssetListPaged(page: 0, size: 50);
      setState(() {
        _galleryImages = media;
      });
      print("✅ Loaded ${_galleryImages.length} images from gallery.");
    } else {
      print("⚠️ No albums found.");
    }
  }



  /// Select multiple images
  Future<void> _selectImage(AssetEntity asset) async {
    final file = await asset.file;
    if (file != null) {
      setState(() {
        _selectedImages.add(file);
        _captionControllers[_selectedImages.length - 1] = TextEditingController(); // Create caption controller
      });
    }
  }

  /// Capture a new photo using the camera
  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
        _captionControllers[_selectedImages.length - 1] = TextEditingController(); // Create caption controller
      });
    }
  }

  /// Upload multiple images & captions to Supabase
  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    try {
      for (int i = 0; i < _selectedImages.length; i++) {
        final fileName = "${widget.userId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg";
        final filePath = "user-photos/$fileName";

        // Upload file to Supabase Storage
        await supabase.storage.from('user-photos').upload(filePath, _selectedImages[i]);

        // Generate public URL for the image
        final publicUrl = supabase.storage.from('user-photos').getPublicUrl(filePath);

        // Save metadata in the 'posts' table
        await supabase.from('posts').insert({
          'user_id': widget.userId,
          'image_url': publicUrl,
          'caption': _captionControllers[i]?.text ?? "",
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Posts uploaded successfully!")),
      );

      Navigator.pop(context, true); // Return to the previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error uploading posts: $e")),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("New Post", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _selectedImages.isEmpty || _isUploading ? null : _uploadImages,
            child: Text(
              _isUploading ? "Uploading..." : "Post",
              style: TextStyle(
                color: _selectedImages.isEmpty ? Colors.grey : Colors.blue,
                fontSize: 16,
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          /// Large Preview of Selected Images with Captions
          Expanded(
            child: _selectedImages.isEmpty
                ? Center(child: Text("No Images Selected", style: TextStyle(color: Colors.white)))
                : ListView.builder(
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 250,
                      color: Colors.black26,
                      child: Image.file(_selectedImages[index], fit: BoxFit.cover),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: TextField(
                        controller: _captionControllers[index],
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Write a caption...",
                          hintStyle: TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          /// Recent Gallery Selection Grid
          Container(
            height: 120,
            child: _galleryImages.isEmpty
                ? Center(child: Text("No images found", style: TextStyle(color: Colors.white)))
                : GridView.builder(
              padding: EdgeInsets.all(5),
              scrollDirection: Axis.horizontal,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _galleryImages.length + 1, // +1 for the camera button
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Camera Icon as First Item
                  return GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      color: Colors.black26,
                      child: Icon(Icons.camera_alt, color: Colors.white, size: 40),
                    ),
                  );
                } else {
                  // Display Gallery Images
                  return GestureDetector(
                    onTap: () => _selectImage(_galleryImages[index - 1]),
                    child: FutureBuilder<File?>(
                      future: _galleryImages[index - 1].file,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                          return Image.file(snapshot.data!, fit: BoxFit.cover);
                        }
                        return Container(color: Colors.black26);
                      },
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
