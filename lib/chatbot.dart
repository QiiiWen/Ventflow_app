import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(ChatbotApp());
}

class ChatbotApp extends StatelessWidget {
  const ChatbotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> messages = [];
  bool isThinking = false;

  // Supabase Edge Function URL
  final String chatbotUrl =
      "https://ropvyxordeaxskpwkqdo.supabase.co/functions/v1/chatbot";

  // Supabase API Key
  final String supabaseApiKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJvcHZ5eG9yZGVheHNrcHdrcWRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAwNDY3ODUsImV4cCI6MjA1NTYyMjc4NX0.9dq9wjZwTmkRGI-GqEHEWNTixAL3t7MgPNQVCLm4S6I";

  Future<void> sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    // Add the new user message to the conversation
    setState(() {
      messages.add({"sender": "user", "message": _controller.text});
      isThinking = true;
    });
    _scrollToBottom();

    String userMessage = _controller.text;
    _controller.clear();

    // Create a payload that includes the entire conversation history.
    final Map<String, dynamic> payload = {
      "conversation": messages,
      "message": userMessage,
    };

    try {
      print("📤 Sending request to: $chatbotUrl");
      final response = await http.post(
        Uri.parse(chatbotUrl),
        headers: {
          "Authorization": "Bearer $supabaseApiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      print("📥 Response Code: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        String botReply = jsonResponse["response"] ?? "No response from AI.";

        setState(() {
          messages.add({"sender": "bot", "message": botReply});
          isThinking = false;
        });
        _scrollToBottom();
      } else {
        setState(() {
          messages.add(
              {"sender": "bot", "message": "Error: Failed to fetch response."});
          isThinking = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print("❌ Request Error: $e");
      setState(() {
        messages.add({
          "sender": "bot",
          "message": "Error: Unable to connect to server."
        });
        isThinking = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Vent. AI"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple.shade800,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade900, Colors.deepPurple.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Chat messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  itemCount: messages.length + (isThinking ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length && isThinking) {
                      return TypingIndicator(); // Show typing animation
                    }
                    bool isUser = messages[index]["sender"] == "user";
                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        // Adjusted margin so that bubbles do not touch the screen edges.
                        margin: isUser
                            ? EdgeInsets.fromLTRB(30, 5, 10, 5)
                            : EdgeInsets.fromLTRB(10, 5, 30, 5),
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(
                          color: isUser
                              ? const Color.fromARGB(255, 159, 45, 241)
                              : const Color.fromARGB(255, 194, 101, 211),
                          // For user messages, angle the bottom-right; for bot messages, angle the bottom-left.
                          borderRadius: isUser
                              ? BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  topRight: Radius.circular(15),
                                  bottomLeft: Radius.circular(15),
                                  bottomRight: Radius.circular(3),
                                )
                              : BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  topRight: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                  bottomLeft: Radius.circular(3),
                                ),
                        ),
                        child: Text(
                          messages[index]["message"]!,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Chat Input Field
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.deepPurple.shade800),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Ask me something...",
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: Colors.white),
                      onPressed: sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// Typing Indicator Animation
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FadeTransition(
          opacity: _animation,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 194, 101, 211),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              "Typing...",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
