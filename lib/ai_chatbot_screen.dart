import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AIChatBotScreen extends StatefulWidget {
  final String userId;

  AIChatBotScreen({required this.userId});

  @override
  _AIChatBotScreenState createState() => _AIChatBotScreenState();
}

class _AIChatBotScreenState extends State<AIChatBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, String>> _messages = []; // Store chat messages

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": message});
      // For now, we just echo the user's message
      _messages.add({"role": "bot", "text": "AI says: $message"});
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF040B41),
      appBar: AppBar(
        backgroundColor: Color(0xFF040B41),
        title: Text("AI Chatbot", style: GoogleFonts.sen(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";
                return Container(
                  margin: EdgeInsets.only(bottom: 10),
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      msg["text"] ?? "",
                      style: GoogleFonts.sen(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          // Message Input
          Container(
            color: Colors.grey[900],
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
