import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_screen.dart';
import 'attendee_screen.dart';
import 'sponsor_screen.dart';
import 'exhibitor_screen.dart';
import 'speaker_screen.dart';
import 'email_request.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;
  bool isLoading = false;

  final supabase = Supabase.instance.client;

  /// ✅ **Login with Supabase Auth**
  Future<void> login() async {
    setState(() => isLoading = true);

    try {
      print("🔍 Attempting login for: ${emailController.text}");

      // 🔹 **Step 1: Authenticate User**
      final response = await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      print("✅ Supabase Response: $response");

      final user = response.user;
      if (user == null) {
        throw "Invalid email or password";
      }

      print("✅ Login Successful! User ID: ${user.id}");

      // 🔹 **Step 2: Fetch User Role**
      final userData = await supabase
          .from('users')
          .select('role, first_name, id')
          .eq('email', user.email!)
          .maybeSingle();

      print("✅ User Data: $userData"); // Debugging Log

      if (userData == null) {
        throw "User data not found in database.";
      }

      String role = userData['role'];
      String firstName = userData['first_name'];
      String userId = userData['id'].toString(); // ✅ Convert to String

      // 🔹 **Step 3: Navigate to the Correct Screen Based on Role**
      Widget nextScreen;
      if (role == "attendee") {
        nextScreen = AttendeeScreen(firstName: firstName, userId: userId);
      } else if (role == "sponsor") {
        nextScreen = SponsorScreen();
      } else if (role == "exhibitor") {
        nextScreen = ExhibitorScreen();
      } else if (role == "speaker") {
        nextScreen = SpeakerScreen();
      } else {
        nextScreen = AttendeeScreen(firstName: firstName, userId: userId);
      }

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => nextScreen));
    } catch (error) {
      print("❌ Login failed: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6850F6), Color(0xFF040B41)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Login",
                    textAlign: TextAlign.left,
                    style: GoogleFonts.sen(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Smart tool for business event management",
                    style: GoogleFonts.sen(fontSize: 20, color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  // ✅ **Email Input**
                  TextField(
                    controller: emailController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white24,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 10),
                  // ✅ **Password Input**
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white24,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: rememberMe,
                            onChanged: (value) {
                              setState(() {
                                rememberMe = value!;
                              });
                            },
                          ),
                          Text("Remember Me", style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                          );
                        },
                        child: Text("Forgot Password?", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // ✅ **Login Button**
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: 120, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: isLoading ? null : login,
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.black)
                          : Text("LOG IN", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen()));
                      },
                      child: Text("Don't have an account? Sign Up Here", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
