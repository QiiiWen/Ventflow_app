import 'dart:math';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';


class OngoingEventDetailsScreen extends StatefulWidget {
  final int eventId;
  final String userId;


  OngoingEventDetailsScreen({required this.eventId, required this.userId});

  @override
  _OngoingEventDetailsScreenState createState() => _OngoingEventDetailsScreenState();
}

class _OngoingEventDetailsScreenState extends State<OngoingEventDetailsScreen> {
  Map<String, dynamic>? _event;
  Map<String, dynamic>? _ticket;
  ValueNotifier<Duration> _remainingTime = ValueNotifier(Duration());
  Timer? _timer;
  LatLng? _eventLocation;
  double _distanceInKm = 0.0;
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _fetchEventDetails();
  }

  Future<bool> _hasValidTicket(int eventId, String userId) async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('tickets')
        .select('status')
        .eq('event_id', eventId)
        .eq('user_id', userId)
        .maybeSingle();

    if (response != null && response['status'] == 'Paid') {
      return true; // User has a valid ticket
    }
    return false; // No valid ticket
  }

  Future<void> _fetchEventDetails() async {
    final supabase = Supabase.instance.client;

    try {
      final eventResponse = await supabase
          .from('events')
          .select()
          .eq('id', widget.eventId)
          .single();

      final ticketResponse = await supabase
          .from('tickets')
          .select('*')
          .eq('event_id', widget.eventId)
          .eq('user_id', widget.userId)
          .maybeSingle();

      if (eventResponse != null) {
        setState(() {
          String? bannerPath = eventResponse['banner']?.trim();

          // ✅ Remove leading "/" to prevent double slashes
          if (bannerPath?.startsWith("/") ?? false) {
            bannerPath = bannerPath!.substring(1);
          }

          // ✅ Construct proper Supabase storage URLs
          final bannerUrl = (bannerPath != null && bannerPath.isNotEmpty)
              ? "https://ropvyxordeaxskpwkqdo.supabase.co/storage/v1/object/public/event-banners/$bannerPath"
              : null;

          _event = {
            ...eventResponse, // Keep all event fields
            'banner': bannerUrl, // ✅ Corrected URL
          };

          _ticket = ticketResponse; // ✅ Store ticket details too

          _startCountdown();
          _setEventLocation();
        });

        print("✅ Event Details Fetched Successfully:");
        print("🖼 Event Banner URL: ${_event!['banner']}");
        print("🎟 Ticket Code: ${_ticket != null ? _ticket!['ticket_code'] : 'No ticket found'}");

      }
    } catch (error) {
      print("❌ Error fetching event details: $error");
    }
  }

  void _openGoogleMaps() async {
    if (_eventLocation == null) {
      print("⚠ Location is not available!");
      return;
    }

    final googleMapsUrl =
        "google.navigation:q=${_eventLocation!.latitude},${_eventLocation!.longitude}&mode=d";
    final webUrl =
        "https://www.google.com/maps/search/?api=1&query=${_eventLocation!.latitude},${_eventLocation!.longitude}";

    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(Uri.parse(webUrl))) {
      await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
    } else {
      print("⚠ Could not open Google Maps");
    }
  }

  void _setEventLocation() async {
    if (_event == null) return;

    double? lat = _event!['latitude'];
    double? lng = _event!['longitude'];

    if (lat != null && lng != null) {
      setState(() {
        _eventLocation = LatLng(lat, lng);
      });
    } else {
      setState(() {
        _eventLocation = LatLng(3.1390, 101.6869); // Default to KL
      });
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _distanceInKm = _calculateDistance(
            position.latitude,
            position.longitude,
            lat ?? 3.1390,
            lng ?? 101.6869);
      });
    } catch (e) {
      print("⚠ Error fetching user location: $e");
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double radius = 6371;
    double dLat = (lat2 - lat1) * (pi / 180.0);
    double dLon = (lon2 - lon1) * (pi / 180.0);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) *
            cos(lat2 * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c;
  }

  void _startCountdown() {
    if (_event == null) return;

    DateTime eventDate = DateTime.parse(_event!['date']);
    _remainingTime.value = eventDate.difference(DateTime.now());

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (now.isBefore(eventDate)) {
        _remainingTime.value = eventDate.difference(now);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_event == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 250,
                  width: double.infinity,
                  child: _event!['banner'] != null && _event!['banner']!.isNotEmpty
                      ? Image.network(
                    _event!['banner']!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print("❌ Image failed to load: $error");
                      return SizedBox(); // Returns an empty container instead of a placeholder
                    },
                  )
                      : SizedBox(), // No placeholder, just an empty space
                ),
                Positioned(
                  top: 160,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ValueListenableBuilder<Duration>(
                        valueListenable: _remainingTime,
                        builder: (context, remainingTime, child) {
                          return Text(
                            "${remainingTime.inDays.toString().padLeft(2, '0')} : "
                                "${(remainingTime.inHours % 24).toString().padLeft(2, '0')} : "
                                "${(remainingTime.inMinutes % 60).toString().padLeft(2, '0')} : "
                                "${(remainingTime.inSeconds % 60).toString().padLeft(2, '0')}",
                            style: GoogleFonts.sen(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          );
                        },
                      ),
                      SizedBox(height: 4),
                      Text("DAYS    HOURS    MINUTES    SECONDS",
                          style: GoogleFonts.sen(fontSize: 12, color: Colors.white)),
                    ],
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 20,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            // **Event Information**
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_event!['name'], style: GoogleFonts.sen(fontSize: 22, fontWeight: FontWeight.bold)),

                  SizedBox(height: 5),

                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: AssetImage('assets/profile.jpg'),
                        radius: 14,
                      ),
                      SizedBox(width: 8),
                      Text("Organized by ${_event!['organizer']}",
                          style: GoogleFonts.sen(fontSize: 14, color: Colors.grey[600])),
                      Spacer(),
                    ],
                  ),

                  SizedBox(height: 10),

                  // **Date & Time**
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 5),
                      Text(
                        DateFormat('EEE, MMM d, yyyy - hh:mm a').format(DateTime.parse(_event!['date'])),
                        style: GoogleFonts.sen(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  // **Location**
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _event!['location'],
                          style: GoogleFonts.sen(fontSize: 14, color: Colors.grey[700]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  // **Attendee Information**
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 5),
                      Text(
                        "${_event!['attendees_limit']} slots",
                        style: GoogleFonts.sen(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  if (_ticket != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("Your Ticket",
                            style: GoogleFonts.sen(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple)),
                        SizedBox(height: 10),
                        BarcodeWidget(
                          barcode: Barcode.code128(),
                          data: _ticket!['ticket_code'],
                          width: double.infinity,
                          height: 80,
                          drawText: false,
                        ),
                        SizedBox(height: 5),
                        Text("${_ticket!['ticket_code']}",
                            style: GoogleFonts.sen(
                                fontSize: 14, color: Colors.deepPurple)),
                      ],
                    )
                  else
                    Center(
                      child: Text("No ticket found",
                          style:
                          TextStyle(color: Colors.red, fontSize: 16)),
                    ),

                  SizedBox(height: 15),

                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // **Details Section**
                        Text("Details", style: GoogleFonts.sen(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                        SizedBox(height: 5),
                        Text(_event!['description'], style: GoogleFonts.sen(fontSize: 14, color: Colors.grey[700])),

                        // **Map Section**
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("About the Venue", style: GoogleFonts.sen(fontSize: 16, fontWeight: FontWeight.bold)),
                            TextButton(
                              onPressed: () => _openGoogleMaps(),
                              child: Text("Get Destination", style: GoogleFonts.sen(color: Colors.deepPurple)),
                            ),
                          ],
                        ),

                        SizedBox(height: 10),

                        // **Flutter Map - Show Real Location**
                        if (_eventLocation != null)
                          Container(
                            height: 200,
                            child: FlutterMap(
                              options: MapOptions(
                                center: _eventLocation!,
                                zoom: 14.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                  subdomains: ['a', 'b', 'c'],
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      width: 80.0,
                                      height: 80.0,
                                      point: _eventLocation!,
                                      builder: (ctx) => Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        else
                          Center(child: CircularProgressIndicator()),

                        SizedBox(height: 10),

                        Text(
                          _distanceInKm > 0
                              ? "${_distanceInKm.toStringAsFixed(2)} km distance from your home"
                              : "Fetching location...",
                          style: GoogleFonts.sen(fontSize: 14, color: Colors.grey[700]),
                        ),

                        Text(_event!['location'], style: GoogleFonts.sen(fontSize: 14, color: Colors.grey[600])),

                        SizedBox(height: 20),

                      ],

                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
