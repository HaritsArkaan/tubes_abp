import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' show cos, sin, pi;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:snack_hunt/config.dart';
import 'services/api_review.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

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

  // User data
  int _userId = 0;
  String _username = '';
  String _password = '';
  int _postsCount = 0;
  int _reviewsCount = 0;
  bool _isLoading = true;

  // API service
  final ApiReview _apiReview = ApiReview();

  @override
  void initState() {
    super.initState();

    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // Single rotation animation for icons
    _rotationController = AnimationController(
      duration: const Duration(seconds: 30), // Slower rotation
      vsync: this,
    )..repeat();

    // Pulse animation for profile picture
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Load user data
    _loadUserData();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user ID and token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final token = prefs.getString('jwt_token');
      final username = prefs.getString('username');
      final password = prefs.getString('password') ?? '';

      if (userId == null || token == null) {
        // Handle not logged in state
        print('User not logged in');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Set user ID, username and password
      setState(() {
        _userId = userId;
        _username = username ?? '';
        _password = password;
      });

      // Fetch posts count (jajanan added by user)
      try {
        final postsResponse = await http.get(
          Uri.parse('${AppConfig.baseUrl}/api/snacks/user/$userId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (postsResponse.statusCode == 200) {
          final List<dynamic> posts = json.decode(postsResponse.body);
          setState(() {
            _postsCount = posts.length;
          });
          print('Posts count: $_postsCount');
        } else {
          print('Failed to fetch posts: ${postsResponse.statusCode}');
          print('Response body: ${postsResponse.body}');
        }
      } catch (e) {
        print('Error fetching posts: $e');
      }

      // Fetch reviews using the endpoint from the image
      try {
        final reviewsResponse = await http.get(
          Uri.parse('${AppConfig.baseUrl}/reviews/user/$userId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (reviewsResponse.statusCode == 200) {
          final List<dynamic> reviews = json.decode(reviewsResponse.body);
          setState(() {
            _reviewsCount = reviews.length;
          });
          print('Reviews count: $_reviewsCount');
        } else {
          print('Failed to fetch reviews: ${reviewsResponse.statusCode}');
          print('Response body: ${reviewsResponse.body}');
        }
      } catch (e) {
        print('Error fetching reviews: $e');
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showEditProfileDialog() {
    final TextEditingController _usernameController = TextEditingController(text: _username);
    final TextEditingController _passwordController = TextEditingController(text: _password);
    bool _obscurePassword = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 8,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      const Color(0xFFF1F8E9).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Color(0xFF4CAF50),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Edit Profile',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Username field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _usernameController,
                        style: GoogleFonts.poppins(fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: 'Username',
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: Color(0xFF4CAF50),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // // Password field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.poppins(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF4CAF50),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF4CAF50),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Batal',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _updateProfile(
                                _usernameController.text,
                                _passwordController.text,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Simpan',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms).scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1, 1),
              duration: 300.ms,
              curve: Curves.easeOutBack,
            );
          },
        );
      },
    );
  }

  Future<void> _updateProfile(String newUsername, String newPassword) async {
    // Validasi input
    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Username tidak boleh kosong'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Memperbarui profil...',
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );

      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('User not logged in');
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'username': newUsername,
      };

      // Add password only if it's not empty
      if (newPassword.isNotEmpty) {
        requestBody['password'] = newPassword;
      }

      print('Updating profile with: $requestBody');

      // Send update request
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/users/$_userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Update profile response status: ${response.statusCode}');
      print('Update profile response body: ${response.body}');

      if (response.statusCode == 200) {
        // Update stored username and password
        await prefs.setString('username', newUsername);
        await prefs.setString('password', newPassword);

        // Update state
        setState(() {
          _username = newUsername;
          _password = newPassword;
        });

        // Show success dialog
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sukses',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
            content: Text(
              'Profil berhasil diperbarui!',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(color: const Color(0xFF4CAF50)),
                ),
              ),
            ],
          ),
        );
      } else {
        print('Failed to update profile: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Gagal memperbarui profil: ${e.toString()}',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.logout,
              color: Color(0xFF4CAF50),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Logout',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun ini?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(color: const Color(0xFF4CAF50)),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (shouldLogout) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('jwt_token');
        await prefs.remove('user_id');
        await prefs.remove('username');
        await prefs.remove('password');

        // Navigate to login page
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      } catch (e) {
        print('Error during logout: $e');
      }
    }
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
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.06,
                vertical: size.height * 0.02,
              ),
              child: Column(
                children: [
                  // App Bar with Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'images/logo.png',
                        height: size.height * 0.05,
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms).moveY(
                    begin: -20,
                    end: 0,
                    duration: 500.ms,
                    curve: Curves.easeOutQuad,
                  ),
                  SizedBox(height: size.height * 0.03),

                  // Profile Header
                  Container(
                    padding: EdgeInsets.all(size.width * 0.06),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          spreadRadius: 0,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Profile Picture with Rotating Icons
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

                              // Static Profile Picture with pulse animation
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Container(
                                    width: size.width * 0.25 + (_pulseController.value * 5),
                                    height: size.width * 0.25 + (_pulseController.value * 5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF4CAF50).withOpacity(0.2 + (_pulseController.value * 0.1)),
                                          blurRadius: 10 + (_pulseController.value * 5),
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(size.width * 0.125 + (_pulseController.value * 2.5)),
                                      child: Image.asset(
                                        'images/profile.jpg',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: size.height * 0.02),

                        // Username
                        Text(
                          _username,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        // User ID
                        Text(
                          'ID: $_userId',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 800.ms).moveY(
                    begin: 20,
                    end: 0,
                    duration: 800.ms,
                    curve: Curves.easeOutQuad,
                  ),
                  SizedBox(height: size.height * 0.03),

                  // Stats Cards
                  _isLoading
                      ? Center(
                    child: CircularProgressIndicator(
                      color: const Color(0xFF4CAF50),
                    ),
                  )
                      : Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.restaurant_menu,
                          title: 'Posts',
                          value: _postsCount.toString(),
                          color: const Color(0xFF4CAF50),
                          size: size,
                        ),
                      ),
                      SizedBox(width: size.width * 0.04),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.star,
                          title: 'Reviews',
                          value: _reviewsCount.toString(),
                          color: const Color(0xFFFF9800),
                          size: size,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 1000.ms).moveY(
                    begin: 20,
                    end: 0,
                    duration: 1000.ms,
                    curve: Curves.easeOutQuad,
                  ),
                  SizedBox(height: size.height * 0.03),

                  // Account Information Card
                  Container(
                    padding: EdgeInsets.all(size.width * 0.06),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          spreadRadius: 0,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFF4CAF50),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Account Information',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: size.height * 0.02),

                        // Username display
                        _buildInfoItem(
                          icon: Icons.person_outline,
                          title: 'Username',
                          value: _username,
                          size: size,
                        ),
                        SizedBox(height: size.height * 0.015),

                        // Password display
                        _buildInfoItem(
                          icon: Icons.lock_outline,
                          title: 'Password',
                          value: '********',
                          size: size,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 1200.ms).moveY(
                    begin: 20,
                    end: 0,
                    duration: 1200.ms,
                    curve: Curves.easeOutQuad,
                  ),
                  SizedBox(height: size.height * 0.03),

                  // Action Buttons
                  Container(
                    padding: EdgeInsets.all(size.width * 0.06),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          spreadRadius: 0,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.settings,
                                color: Color(0xFF4CAF50),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Account Settings',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: size.height * 0.02),

                        // Edit Profile Button
                        _buildActionButton(
                          icon: Icons.edit,
                          title: 'Edit Profile',
                          color: const Color(0xFF4CAF50),
                          onTap: _showEditProfileDialog,
                          size: size,
                        ),
                        SizedBox(height: size.height * 0.015),

                        // Logout Button
                        _buildActionButton(
                          icon: Icons.logout,
                          title: 'Logout',
                          color: const Color(0xFF4CAF50),
                          onTap: _logout,
                          size: size,
                        ),
                        SizedBox(height: size.height * 0.015),

                        // Delete Account Button
                        _buildActionButton(
                          icon: Icons.delete_outline,
                          title: 'Delete Account',
                          color: Colors.red[700]!,
                          onTap: () => _showDeleteAccountDialog(context, size),
                          size: size,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 1400.ms).moveY(
                    begin: 20,
                    end: 0,
                    duration: 1400.ms,
                    curve: Curves.easeOutQuad,
                  ),
                  SizedBox(height: size.height * 0.03),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Size size,
  }) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(height: size.height * 0.01),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required Size size,
    bool isPassword = false,
  }) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4CAF50),
              size: 20,
            ),
          ),
          SizedBox(width: size.width * 0.03),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isPassword && value == 'Masukkan password baru' ? Colors.grey[400] : Colors.black87,
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required Function() onTap,
    required Size size,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(size.width * 0.04),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 5,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            SizedBox(width: size.width * 0.03),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context, Size size) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.red[700],
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Delete Account',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
          ],
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
