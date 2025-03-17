import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Record & Summarize',
      theme: ThemeData(primarySwatch: Colors.purple),
      home: const RecordSummarizePage(),
    );
  }
}

class RecordSummarizePage extends StatefulWidget {
  const RecordSummarizePage({super.key});

  @override
  State<RecordSummarizePage> createState() => _RecordSummarizePageState();
}

class _RecordSummarizePageState extends State<RecordSummarizePage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String? _recordedFilePath;
  String _transcription = '';
  String _summary = '';
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  String _timerText = '00:00';

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        _recordingDuration += const Duration(seconds: 1);
        _timerText = _formatDuration(_recordingDuration);
      });
    });
  }

  void _showDebugDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(message)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _checkPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
  }

  Future<void> _startRecording() async {
    bool hasPermission = await _checkPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Microphone permission not granted")),
      );
      return;
    }

    final tempDir = Directory.systemTemp;
    _recordedFilePath = '${tempDir.path}/recording.m4a';
    await _recorder.startRecorder(
      toFile: _recordedFilePath,
      codec: Codec.aacMP4,
    );

    setState(() {
      _isRecording = true;
      // Hide transcription result by clearing it
      _transcription = '';
      _summary = '';
      _recordingDuration = Duration.zero;
      _timerText = '00:00';
    });
    _startTimer();
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    _timer?.cancel();
  }

  Future<void> _uploadAndSummarize() async {
    if (_recordedFilePath == null) return;

    final file = File(_recordedFilePath!);
    final uri = Uri.parse(
      "https://ropvyxordeaxskpwkqdo.supabase.co/functions/v1/speech-to-text",
    );

    const supabaseAnonKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJvcHZ5eG9yZGVheHNrcHdrcWRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAwNDY3ODUsImV4cCI6MjA1NTYyMjc4NX0.9dq9wjZwTmkRGI-GqEHEWNTixAL3t7MgPNQVCLm4S6I';

    final request =
        http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $supabaseAnonKey'
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final response = await request.send();
    Navigator.of(context).pop();

    final responseBody = await response.stream.bytesToString();

    setState(() {
      _recordedFilePath = null;
      _recordingDuration = Duration.zero;
      _timerText = '00:00';
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      setState(() {
        // Hide transcription result from user
        _transcription = '';
        _summary = data['summary'];
      });
    } else {
      _showDebugDialog(
        "Upload Failed",
        "Status Code: ${response.statusCode}\nResponse: $responseBody",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record & Summarize'),
        centerTitle: true,
        backgroundColor: Colors.purple,
      ),
      backgroundColor: Colors.purple,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.95,
                  height: 600, // Fixed height to maintain the same box size
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child:
                      _summary.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isRecording ||
                                    _recordedFilePath != null) ...[
                                  if (_isRecording)
                                    const Text(
                                      'Recording...',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.purple,
                                      ),
                                    ),
                                  Text(
                                    _timerText,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                  if (!_isRecording &&
                                      _recordedFilePath != null)
                                    const Text(
                                      'Recorded',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.purple,
                                      ),
                                    ),
                                ] else
                                  const Text(
                                    'Record audio to see summary',
                                    style: TextStyle(
                                      color: Colors.purple,
                                      fontSize: 18,
                                    ),
                                  ),
                              ],
                            ),
                          )
                          : Scrollbar(
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: const Text(
                                      'Summary:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple,
                                        fontSize: 21,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(_summary),
                                ],
                              ),
                            ),
                          ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20),
                      backgroundColor: Colors.white,
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      size: 30,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed:
                        (!_isRecording && _recordedFilePath != null)
                            ? _uploadAndSummarize
                            : null,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20),
                      backgroundColor: Colors.white,
                    ),
                    child: const Icon(
                      Icons.insert_drive_file,
                      size: 30,
                      color: Colors.purple,
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
