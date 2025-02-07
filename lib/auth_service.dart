import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String apiUrl = "http://your-localhost-url/login.php";

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {"success": false, "message": "Server error"};
    }
  }
}
