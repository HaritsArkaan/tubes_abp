import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' show cos, sin, pi;

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late AnimationController _rotationController;

  // Food-related icons in a more minimal style
  final List<IconData> foodIcons = [
    Icons.restaurant_menu_outlined,
    Icons.local_cafe_outlined,
    Icons.cake_outlined,
    Icons.local_bar_outlined,
    Icons.fastfood_outlined,
    Icons.icecream_outlined,
    Icons.coffee_outlined,
    Icons.lunch_dining_outlined,
  ];

  @override
  void initState() {
    super.initState();

    // Single rotation animation for icons
    _rotationController = AnimationController(
      duration: const Duration(seconds: 30), // Slower rotation
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        height: size.height,
        width: size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFE8F5E9),
              Colors.green.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.06,
                vertical: size.height * 0.02,
              ),
              child: Column(
                children: [
                  // Logo
                  Image.asset(
                    'images/logo.png',
                    height: size.height * 0.06,
                  ),
                  SizedBox(height: size.height * 0.04),

                  // Profile Section with Rotating Icons
                  SizedBox(
                    height: size.width * 0.5,
                    width: size.width * 0.5,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Rotating icons
                        ...List.generate(foodIcons.length, (index) {
                          return AnimatedBuilder(
                            animation: _rotationController,
                            builder: (context, child) {
                              final angle = 2 * pi * index / foodIcons.length;
                              final rotationAngle = _rotationController.value * 2 * pi;
                              final radius = size.width * 0.2;
                              final x = cos(angle - rotationAngle) * radius;
                              final y = sin(angle - rotationAngle) * radius;

                              return Transform(
                                transform: Matrix4.translationValues(x, y, 0),
                                child: Container(
                                  padding: EdgeInsets.all(size.width * 0.02),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    foodIcons[index],
                                    color: const Color(0xFF4CAF50),
                                    size: size.width * 0.035,
                                  ),
                                ),
                              );
                            },
                          );
                        }),

                        // Static Profile Picture
                        Container(
                          width: size.width * 0.25,
                          height: size.width * 0.25,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(size.width * 0.125),
                            child: Image.asset(
                              'images/profile.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: size.height * 0.04),

                  // Rest of the code remains the same...
                  // (Stats, Input fields, Action Buttons)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAnimatedStat('24', 'Posts', size),
                      SizedBox(width: size.width * 0.08),
                      _buildAnimatedStat('12', 'Reviews', size),
                    ],
                  ),
                  SizedBox(height: size.height * 0.03),

                  _buildAnimatedTextField(
                    controller: _usernameController,
                    hint: 'Username',
                    icon: Icons.person_outline,
                    size: size,
                  ),
                  SizedBox(height: size.height * 0.02),
                  _buildAnimatedTextField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    size: size,
                  ),
                  SizedBox(height: size.height * 0.03),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.edit_outlined, size: size.width * 0.045),
                          label: Text(
                            'Edit Profile',
                            style: GoogleFonts.poppins(fontSize: size.width * 0.04),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(size.width * 0.03),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: size.width * 0.03),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.logout_outlined, size: size.width * 0.045),
                          label: Text(
                            'Log out',
                            style: GoogleFonts.poppins(fontSize: size.width * 0.04),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4CAF50),
                            side: const BorderSide(color: Color(0xFF4CAF50)),
                            padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(size.width * 0.03),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.02),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(size.width * 0.03),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: TextButton.icon(
                      onPressed: () => _showDeleteAccountDialog(context, size),
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red[700],
                        size: size.width * 0.045,
                      ),
                      label: Text(
                        'Delete Account',
                        style: GoogleFonts.poppins(
                          fontSize: size.width * 0.04,
                          color: Colors.red[700],
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(size.width * 0.03),
                        ),
                      ),
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

  // Helper methods remain the same...
  Widget _buildAnimatedStat(String value, String title, Size size) {
    return Container(
      width: size.width * 0.35,
      padding: EdgeInsets.symmetric(
        vertical: size.height * 0.015,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size.width * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: size.width * 0.05,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4CAF50),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: size.width * 0.035,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Size size,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size.width * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        style: GoogleFonts.poppins(fontSize: size.width * 0.04),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: size.width * 0.04,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF4CAF50),
            size: size.width * 0.05,
          ),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: const Color(0xFF4CAF50),
              size: size.width * 0.05,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(size.width * 0.03),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: size.width * 0.04,
            vertical: size.height * 0.02,
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context, Size size) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(size.width * 0.03),
        ),
        title: Text(
          'Delete Account',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.red[700],
          ),
        ),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              // Implement delete account logic here
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }
}