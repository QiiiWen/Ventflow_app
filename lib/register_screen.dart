import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


// Class for password requirements
class PasswordRequirement {
  final String text;
  bool isMet;
  bool showAsMet;
  PasswordRequirement({
    required this.text,
    this.isMet = false,
    this.showAsMet = false,
  });
}

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController  = TextEditingController();
  final TextEditingController emailController     = TextEditingController();
  final TextEditingController passwordController  = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  // Password visibility and requirement related variables
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showRequirements = false;
  late FocusNode _passwordFocusNode;
  List<PasswordRequirement> _requirements = [
    PasswordRequirement(text: '8+ characters'),
    PasswordRequirement(text: '1 uppercase letter'),
    PasswordRequirement(text: '1 number'),
    PasswordRequirement(text: '1 symbol (!@#\$&*~)'),
  ];
  late List<AnimationController> _animationControllers;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode = FocusNode();
    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus && passwordController.text.isEmpty) {
        setState(() {
          _showRequirements = false;
        });
      }
    });

    _animationControllers = List.generate(
      _requirements.length,
          (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300),
      ),
    );
  }


  @override
  void dispose() {
    _passwordFocusNode.dispose();
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<bool> _isUserRegistered(String email) async {
    final response = await supabase
        .from('users')
        .select('id')
        .eq('email', email)
        .maybeSingle();

    return response != null; // ✅ Returns true if user exists, false if not
  }

  Future<void> _registerUser() async {
    if (passwordController.text != confirmPasswordController.text) {
      _showMessage("Passwords do not match!", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      final firstName = firstNameController.text.trim();
      final lastName = lastNameController.text.trim();

      // ✅ Step 1: Check if user already exists
      final userExists = await _isUserRegistered(email);
      if (userExists) {
        _showMessage("Email already registered. Try logging in.", Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      // ✅ Step 2: Create user in Supabase Auth
      final response = await supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            "first_name": firstName,
            "last_name": lastName,
            "role": "attendee"
          }
      );

      final user = response.user;
      if (user == null) {
        _showMessage("Registration failed. Try again.", Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      final userId = user.id;

      // ✅ Step 3: Insert user details into the `users` table
      await supabase.from('users').insert({
        'id': userId,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'role': "attendee",
        'verified': false,
      });

      await supabase.from('user_profiles').insert({
        'user_id': userId,
        'username': email.split('@')[0], // Generate username from email
        'profile_pic': '',
        'location': '',
        'bio': '',
        'photos': '',
        'followers': 0,
        'following': 0,
        'created_at': DateTime.now().toIso8601String(),
        'is_private': false,
        'visible_to_public': true,
      });

      // ✅ Step 4: Show verification popup & auto-redirect to login
      _showVerificationPopup(email);
    } catch (error) {
      _showMessage(error.toString(), Colors.red);
    }

    setState(() => _isLoading = false);
  }


  // ✅ Show verification popup
  void _showVerificationPopup(String email) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.6,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  alignment: Alignment.centerLeft,
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(height: 20),
                Text(
                  "Account Verification",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sen(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.mail_outline, size: 100, color: Colors.black),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "A verification link has been sent to $email.\nPlease check your spam folder if you haven't received it.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sen(fontSize: 16, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // ✅ Auto-redirect to LoginScreen after 3 seconds
    Future.delayed(Duration(seconds: 8), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });
  }

  // ✅ Show message (error or success)
  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _updatePasswordStrength(String value) {
    final newMet = [
      value.length >= 8,
      value.contains(RegExp(r'[A-Z]')),
      value.contains(RegExp(r'[0-9]')),
      value.contains(RegExp(r'[!@#\$&*~]')),
    ];

    setState(() {
      for (int i = 0; i < _requirements.length; i++) {
        final wasMet = _requirements[i].isMet;
        if (newMet[i] != wasMet) {
          if (newMet[i]) {
            _handleMetRequirement(i);
          } else {
            _animationControllers[i].reset();
            _requirements[i].isMet = false;
            _requirements[i].showAsMet = false;
          }
        }
      }
    });
  }

  void _handleMetRequirement(int index) {
    if (!_requirements[index].showAsMet) {
      setState(() => _requirements[index].showAsMet = true);
      _animationControllers[index].reset();
      _animationControllers[index].forward().then((_) {
        Future.delayed(Duration(milliseconds: 700), () {
          if (mounted) {
            _animationControllers[index].reverse().then((_) {
              if (mounted) {
                setState(() {
                  _requirements[index].isMet = true;
                  _requirements[index].showAsMet = false;
                });
              }
            });
          }
        });
      });
    }
  }

  Widget _buildRequirementRow(PasswordRequirement req, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            req.showAsMet ? Icons.check_circle : Icons.remove_circle,
            color: color,
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            req.text,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
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
            colors: [Color(0xFF6B48FF), Color(0xFF0B0B42)],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                SizedBox(height: 10),
                Text(
                  "Register an\nAccount",
                  style: GoogleFonts.sen(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildTextField("First Name", firstNameController)),
                    SizedBox(width: 10),
                    Expanded(child: _buildTextField("Last Name", lastNameController)),
                  ],
                ),
                SizedBox(height: 15),
                _buildTextField("Email", emailController),
                SizedBox(height: 15),
                // Set Password field with onChanged and focusNode for requirements
                _buildTextField(
                  "Set Password",
                  passwordController,
                  isPassword: true,
                  onChanged: (value) {
                    _updatePasswordStrength(value);
                    setState(() {
                      _showRequirements = value.isNotEmpty;
                    });
                  },
                  focusNode: _passwordFocusNode,
                ),
                SizedBox(height: 5),
                // Password requirements widget
                Visibility(
                  visible: _showRequirements,
                  child: Column(
                    children: _requirements.map((req) {
                      if (req.isMet) return SizedBox.shrink();
                      final index = _requirements.indexOf(req);
                      return AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        child: req.showAsMet
                            ? FadeTransition(
                          key: ValueKey('met-$index'),
                          opacity: _animationControllers[index],
                          child: _buildRequirementRow(req, Colors.green),
                        )
                            : _buildRequirementRow(req, Colors.red),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 15),
                _buildTextField("Retype Password", confirmPasswordController, isPassword: true),
                SizedBox(height: 20),
                Center(
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _registerUser,
                    child: Text("Agree & Continue", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Modified _buildTextField to support onChanged, focusNode, and password visibility toggling.
  Widget _buildTextField(String label, TextEditingController controller,
      {bool isPassword = false, Function(String)? onChanged, FocusNode? focusNode}) {
    return TextField(
      controller: controller,
      obscureText: isPassword
          ? (label == "Set Password" ? _obscurePassword : _obscureConfirmPassword)
          : false,
      onChanged: onChanged,
      focusNode: focusNode,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white24,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            (label == "Set Password" ? _obscurePassword : _obscureConfirmPassword)
                ? Icons.visibility_off
                : Icons.visibility,
            color: Colors.white70,
          ),
          onPressed: () {
            setState(() {
              if (label == "Set Password") {
                _obscurePassword = !_obscurePassword;
              } else {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              }
            });
          },
        )
            : null,
      ),
    );
  }
}
