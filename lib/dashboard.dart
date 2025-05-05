import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snack_hunt/services/auth_service.dart' show AuthService;
import 'config.dart';
import 'navbar.dart';
import 'models/snack.dart';
import 'services/api_snack.dart';
import 'services/api_review.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ScrollController _scrollController;
  bool _isScrolled = false;
  String _userName = 'Guest';

  // API service
  final ApiService _apiService = ApiService();

  // Data
  List<Snack> _snacks = [];
  List<Snack> _popularSnacks = [];
  List<Snack> _filteredSnacks = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';

  // Selected category
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Food', 'Drink', 'Dessert', 'Snack'];

  // For highlight carousel
  int _currentHighlightIndex = 0;
  Timer? _carouselTimer;
  final PageController _highlightPageController = PageController();

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  // Review statistics
  final ApiReview _apiReview = ApiReview();
  Map<int, double> _reviewRatings = {};
  bool _isLoadingReviewStats = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )
      ..forward();

    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _isScrolled = _scrollController.offset > 20;
        });
      });

    // Fetch username
    _fetchUserName();

    // Fetch data when the page loads
    _fetchSnacks();
  }

  // Start carousel timer
  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_popularSnacks.length > 1) {
        final nextPage = (_currentHighlightIndex + 1) % _popularSnacks.length;
        _highlightPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // Fetch review statistics for snacks
  Future<void> _fetchReviewStatistics() async {
    if (_snacks.isEmpty) return;

    setState(() {
      _isLoadingReviewStats = true;
    });

    try {
      // Create a temporary map to store the results
      Map<int, double> tempRatings = {};

      // Fetch review statistics for each snack
      for (var snack in _snacks) {
        try {
          final stats = await _apiReview.getReviewStatistics(snack.id);

          // Handle different response formats
          double averageRating = 0.0;
          if (stats is Map<String, dynamic>) {
            averageRating = (stats['averageRating'] ?? 0.0).toDouble();
          } else if (stats is List && stats.isNotEmpty && stats[0] is Map<String, dynamic>) {
            averageRating = (stats[0]['averageRating'] ?? 0.0).toDouble();
          }

          // Store the average rating
          tempRatings[snack.id] = averageRating;

          // Update UI if mounted
          if (mounted) {
            setState(() {
              _reviewRatings = Map.from(tempRatings);
            });
          }
        } catch (e) {
          print('Error fetching review statistics for snack ${snack.id}: $e');
          // Use the snack's rating as fallback
          tempRatings[snack.id] = snack.rating;
        }
      }

      // Final update with all ratings
      if (mounted) {
        setState(() {
          _reviewRatings = tempRatings;
          _isLoadingReviewStats = false;
        });
      }
    } catch (e) {
      print('Error fetching review statistics: $e');
      if (mounted) {
        setState(() {
          _isLoadingReviewStats = false;
        });
      }
    }
  }

  // Fetch snacks from API
  Future<void> _fetchSnacks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final snacks = await _apiService.getSnacks();

      // Sort by rating to get popular snacks
      final popularSnacks = List<Snack>.from(snacks)
        ..sort((a, b) => b.rating.compareTo(a.rating));

      setState(() {
        _snacks = snacks;
        _filteredSnacks = snacks;
        _popularSnacks = popularSnacks.take(10).toList(); // Top 10 rated snacks
        _isLoading = false;
      });

      // Start carousel timer after data is loaded
      _startCarouselTimer();

      // Fetch review statistics
      _fetchReviewStatistics();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load snacks. Please check your connection.';
        _isLoading = false;
      });
      print('Error: $e');
    }
  }

  // Filter snacks by category
  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _isLoading = true;
      _errorMessage = '';
    });

    // Clear search when changing categories
    _searchController.clear();
    _searchQuery = '';

    if (category == 'All') {
      _fetchSnacks();
    } else {
      _fetchSnacksByCategory(category);
    }
  }

  // Fetch snacks by category
  Future<void> _fetchSnacksByCategory(String category) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Convert category name to match the type field in the API
      // This ensures we're filtering by the correct type
      String typeFilter = category.toLowerCase();

      final snacks = await _apiService.getSnacksByCategory(typeFilter);

      setState(() {
        _snacks = snacks;
        _filteredSnacks = snacks;
        _isLoading = false;
      });

      // Apply search filter if there's an active search
      if (_searchQuery.isNotEmpty) {
        _searchSnacks(_searchQuery);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load snacks. Please check your connection.';
        _isLoading = false;
      });
      print('Error: $e');
    }
  }

  // Search snacks by name
  void _searchSnacks(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredSnacks = _snacks;
      } else {
        _filteredSnacks = _snacks
            .where((snack) => snack.name.toLowerCase().contains(_searchQuery))
            .toList();
      }
    });
  }

  void _fetchUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    print('Token: $token');
    if (token != null) {
      try {
        // Simpan token (opsional jika sudah tersimpan sebelumnya)
        await prefs.setString('jwt_token', token);

        // Pecah token menjadi 3 bagian
        final parts = token.split('.');
        if (parts.length != 3) {
          throw Exception('Token tidak valid');
        }

        // Decode payload
        final payload = base64Url.normalize(
            parts[1]); // normalisasi sebelum decode
        final decoded = utf8.decode(base64Url.decode(payload));

        // Parse JSON dari payload
        final payloadMap = json.decode(decoded);
        final userName = payloadMap['sub']; // ambil 'sub' dari payload

        // Update UI
        setState(() {
          _userName = userName ?? 'Guest';
        });

        print('Username (from sub): $_userName');
      } catch (e) {
        print('Gagal mem-parse token: $e');
        setState(() {
          _userName = 'Guest';
        });
      }
    } else {
      setState(() {
        _userName = 'Guest';
      });
    }
  }

  // Navigate to detail page
  void _navigateToDetailPage(Snack snack) {
    Navigator.pushNamed(
      context,
      '/detailJajanan',
      arguments: snack,
    );
  }

  // Navigate to profile page
  void _navigateToProfile() {
    Navigator.pushNamed(context, '/profile');
  }

  // Logout function
  Future<void> _logout() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.green.shade700),
                ),
                const SizedBox(width: 20),
                const Text("Logging out..."),
              ],
            ),
          ),
        );
      },
    );

    // Clear JWT token from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');

      // Close loading dialog and navigate to landing page
      Navigator.of(context).pop(); // Close dialog
      Navigator.of(context).pushNamedAndRemoveUntil(
          '/landing', (route) => false);
    } catch (e) {
      // Close loading dialog and show error
      Navigator.of(context).pop(); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show profile options
  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.green.shade100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.asset(
                    'images/profile.jpg',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.green.shade700,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'SnackHunt Member',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),
              ListTile(
                leading: Icon(
                  Icons.person_outline,
                  color: Colors.green.shade700,
                ),
                title: const Text('View Profile'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  _navigateToProfile();
                },
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  _logout();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _highlightPageController.dispose();
    _searchController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  // Add this method to show a category-specific loading indicator
  Widget _buildCategoryLoadingIndicator(BuildContext context) {
    final color = _selectedCategory == 'All'
        ? Colors.green.shade700
        : _selectedCategory == 'Food'
        ? Colors.orange
        : _selectedCategory == 'Drink'
        ? Colors.pink
        : _selectedCategory == 'Dessert'
        ? Colors.red
        : const Color(0xFFBE8C63);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading ${_selectedCategory.toLowerCase()} items...',
            style: TextStyle(
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }


// Add this new method to show a category-specific title
  Widget _buildCategoryTitle(BuildContext context) {
    if (_selectedCategory == 'All') {
      return const SizedBox.shrink(); // Don't show title for "All" category
    }

    final size = MediaQuery
        .of(context)
        .size;
    final color = _selectedCategory == 'Food'
        ? Colors.orange
        : _selectedCategory == 'Drink'
        ? Colors.pink
        : _selectedCategory == 'Dessert'
        ? Colors.red
        : const Color(0xFFBE8C63);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.01,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.04,
          vertical: size.height * 0.015,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              _selectedCategory == 'Food'
                  ? Icons.restaurant
                  : _selectedCategory == 'Drink'
                  ? Icons.local_drink
                  : _selectedCategory == 'Dessert'
                  ? Icons.cake
                  : Icons.fastfood,
              color: color,
            ),
            SizedBox(width: size.width * 0.02),
            Text(
              'Showing $_selectedCategory Items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                _filterByCategory('All');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Show All',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.refresh,
                      size: 14,
                      color: color,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading snacks...',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchSnacks,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final size = MediaQuery
        .of(context)
        .size;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size.width,
      decoration: BoxDecoration(
        color: const Color(0xFFD1E7D1),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(_isScrolled ? 0 : size.width * 0.08),
          bottomRight: Radius.circular(_isScrolled ? 0 : size.width * 0.08),
        ),
        boxShadow: _isScrolled
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ]
            : [],
      ),
      child: SafeArea(
        bottom: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.fromLTRB(
            size.width * 0.04,
            _isScrolled ? 8 : size.height * 0.01,
            size.width * 0.04,
            _isScrolled ? 12 : size.height * 0.03,
          ),
          child: Row(
            children: [
              // Logo with animation
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      (1 - _animationController.value) * -50,
                      0,
                    ),
                    child: Opacity(
                      opacity: _animationController.value,
                      child: child,
                    ),
                  );
                },
                child: SizedBox(
                  height: size.height * 0.03,
                  child: Image.asset(
                    'images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.fastfood_rounded,
                        size: size.height * 0.03,
                        color: Colors.green.shade700,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: size.width * 0.03),

              // Profile Section with animation
              Expanded(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        (1 - _animationController.value) * 20,
                      ),
                      child: Opacity(
                        opacity: _animationController.value,
                        child: child,
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      // Profile image with animated border - Now clickable
                      GestureDetector(
                        onTap: _showProfileOptions,
                        child: Container(
                          width: size.width * 0.1,
                          height: size.width * 0.1,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                size.width * 0.05),
                            child: Image.asset(
                              'images/profile.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return CircleAvatar(
                                  backgroundColor: Colors.green.shade200,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.green.shade700,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: size.width * 0.03),

                      // Greeting text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Hello, $_userName!',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E3E5C),
                              ),
                            ),
                            Text(
                              'Craving something delicious today?',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final size = MediaQuery
        .of(context)
        .size;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.02,
      ),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              (1 - _animationController.value) * -30,
              0,
            ),
            child: Opacity(
              opacity: _animationController.value,
              child: child,
            ),
          );
        },
        child: Container(
          height: size.height * 0.055,
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.grey, size: 20),
              SizedBox(width: size.width * 0.02),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "What's your taste craving today?",
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _searchSnacks('');
                      },
                    )
                        : null,
                  ),
                  onChanged: (value) {
                    _searchSnacks(value);
                  },
                  onSubmitted: (value) {
                    _searchSnacks(value);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final size = MediaQuery
        .of(context)
        .size;

    // Only show search results when there's a search query
    if (_searchQuery.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            (1 - _animationController.value) * 30,
          ),
          child: Opacity(
            opacity: _animationController.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: size.width * 0.04,
          vertical: size.height * 0.02,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Search Results',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  Text(
                    '${_filteredSnacks.length} found',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _filteredSnacks.isEmpty
                ? Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No snacks match "$_searchQuery"',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try a different search term or browse categories',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
                : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredSnacks.length > 5 ? 5 : _filteredSnacks
                  .length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final snack = _filteredSnacks[index];
                return ListTile(
                  onTap: () => _navigateToDetailPage(snack),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: snack.imageUrl.isNotEmpty
                        ? Image.network(
                      AppConfig.baseUrl + snack.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(
                              Icons.image_not_supported, color: Colors.grey),
                        );
                      },
                    )
                        : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(
                          Icons.image_not_supported, color: Colors.grey),
                    ),
                  ),
                  title: Text(
                    snack.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E3E5C),
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          snack.type,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        snack.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    'Rp${snack.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E3E5C),
                    ),
                  ),
                );
              },
            ),
            if (_filteredSnacks.length > 5)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      // Show all search results
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius
                              .circular(20)),
                        ),
                        builder: (context) => _buildFullSearchResults(context),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                    ),
                    child: Text(
                      'View all ${_filteredSnacks.length} results',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Full search results in a bottom sheet
  Widget _buildFullSearchResults(BuildContext context) {
    final size = MediaQuery
        .of(context)
        .size;

    return Container(
      height: size.height * 0.8,
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Search Results for "$_searchQuery"',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E3E5C),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _filteredSnacks.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final snack = _filteredSnacks[index];
                return ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToDetailPage(snack);
                  },
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: snack.imageUrl.isNotEmpty
                        ? Image.network(
                      AppConfig.baseUrl + snack.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(
                              Icons.image_not_supported, color: Colors.grey),
                        );
                      },
                    )
                        : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(
                          Icons.image_not_supported, color: Colors.grey),
                    ),
                  ),
                  title: Text(
                    snack.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E3E5C),
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          snack.type,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        snack.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    'Rp${snack.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E3E5C),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBottomSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Snacks',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3E5C),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3E5C),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _categories.map((category) {
              Color chipColor;
              switch (category) {
                case 'Food':
                  chipColor = Colors.orange;
                  break;
                case 'Drink':
                  chipColor = Colors.pink;
                  break;
                case 'Dessert':
                  chipColor = Colors.red;
                  break;
                case 'Snack':
                  chipColor = const Color(0xFFBE8C63);
                  break;
                default:
                  chipColor = Colors.green.shade700;
              }

              return FilterChip(
                label: Text(category),
                selected: _selectedCategory == category,
                onSelected: (selected) {
                  Navigator.pop(context);
                  _filterByCategory(category);
                },
                backgroundColor: Colors.grey[200],
                selectedColor: category == 'All'
                    ? Colors.green[100]
                    : chipColor.withOpacity(0.2),
                checkmarkColor: category == 'All'
                    ? Colors.green[700]
                    : chipColor,
                labelStyle: TextStyle(
                  color: _selectedCategory == category
                      ? (category == 'All' ? Colors.green[700] : chipColor)
                      : Colors.grey[700],
                  fontWeight: _selectedCategory == category
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _fetchSnacks(); // Reset filters
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedCategory = 'All';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                ),
                child: const Text('Reset Filters'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // New carousel highlight menu
  Widget _buildHighlightCarousel(BuildContext context) {
    final size = MediaQuery
        .of(context)
        .size;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            (1 - _animationController.value) * 30,
          ),
          child: Opacity(
            opacity: _animationController.value,
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: size.width,
            height: size.width * 0.5,
            margin: EdgeInsets.symmetric(
              horizontal: size.width * 0.04,
              vertical: size.height * 0.01,
            ),
            child: PageView.builder(
              controller: _highlightPageController,
              itemCount: _popularSnacks.length,
              onPageChanged: (index) {
                setState(() {
                  _currentHighlightIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final snack = _popularSnacks[index];
                return GestureDetector(
                  onTap: () => _navigateToDetailPage(snack),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Image with parallax effect
                        Positioned.fill(
                          child: Hero(
                            tag: 'snack_${snack.id}',
                            child: snack.imageUrl.isNotEmpty
                                ? Image.network(
                              AppConfig.baseUrl + snack.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'images/risoles.jpg',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey,
                                          size: 50,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            )
                                : Image.asset(
                              'images/risoles.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                      size: 50,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Gradient overlay
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Text with animation
                        Positioned(
                          left: size.width * 0.04,
                          bottom: size.width * 0.04,
                          right: size.width * 0.04,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                snack.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: size.width * 0.06,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: size.height * 0.005),
                              Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        snack.type,
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: size.width * 0.04,
                                        ),
                                      ),
                                      SizedBox(width: size.width * 0.02),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(
                                              12),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              (_reviewRatings[snack.id] ?? snack.rating).toStringAsFixed(1),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: size.width * 0.03,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // View details button
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'View details',
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 10,
                                          color: Colors.green.shade700,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Page indicator
          if (_popularSnacks.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _popularSnacks.length,
                      (index) =>
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentHighlightIndex == index ? 18 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentHighlightIndex == index
                              ? Colors.green.shade700
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    final size = MediaQuery
        .of(context)
        .size;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            (1 - _animationController.value) * 30,
          ),
          child: Opacity(
            opacity: _animationController.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.all(size.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E3E5C),
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.02),
            // Responsive grid layout for categories
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              childAspectRatio: 0.8,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _buildCategoryItem(context, 'Food', Colors.orange),
                _buildCategoryItem(context, 'Drink', Colors.pink),
                _buildCategoryItem(context, 'Dessert', Colors.red),
                _buildCategoryItem(context, 'Snack', const Color(0xFFBE8C63)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Replace the _buildCategoryItem method with this enhanced version
  Widget _buildCategoryItem(BuildContext context, String title, Color color) {
    final size = MediaQuery
        .of(context)
        .size;
    final itemSize = size.width * 0.15;
    final isSelected = _selectedCategory == title;

    return GestureDetector(
      onTap: () {
        // Filter by category with animation
        HapticFeedback.lightImpact(); // Add haptic feedback
        setState(() {
          _selectedCategory = title;
          _isLoading = true; // Show loading indicator
        });

        // Filter products by category
        _filterByCategory(title);

        // Scroll to category results
        if (title != 'All') {
          Future.delayed(const Duration(milliseconds: 300), () {
            _scrollController.animateTo(
                size.height * 0.4,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut
            );
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated container for the category icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: isSelected ? itemSize * 1.1 : itemSize,
              height: isSelected ? itemSize * 1.1 : itemSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color.withOpacity(0.3) : color.withOpacity(
                    0.1),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? color.withOpacity(0.4) : color
                        .withOpacity(0.2),
                    blurRadius: isSelected ? 12 : 8,
                    spreadRadius: isSelected ? 2 : 1,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: isSelected ? Border.all(color: color, width: 2) : null,
              ),
              child: ClipOval(
                child: Image.asset(
                  'images/${title.toLowerCase()}.png',
                  width: itemSize * 0.6,
                  height: itemSize * 0.6,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      title == 'Food'
                          ? Icons.restaurant
                          : title == 'Drink'
                          ? Icons.local_drink
                          : title == 'Dessert'
                          ? Icons.cake
                          : Icons.fastfood,
                      size: itemSize * 0.6,
                      color: color,
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: size.height * 0.01),
            // Animated text for the category name
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: isSelected ? size.width * 0.04 : size.width * 0.035,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : const Color(0xFF2E3E5C),
              ),
              child: Text(title),
            ),
            // Indicator dot for selected category
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isSelected ? 4 : 0,
              width: isSelected ? 20 : 0,
              margin: EdgeInsets.only(top: isSelected ? 4 : 0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Add this method to build the category results section
  Widget _buildCategoryResults(BuildContext context) {
    final size = MediaQuery
        .of(context)
        .size;

    // Only show category results when a specific category is selected and there's no search query
    if (_selectedCategory == 'All' || _searchQuery.isNotEmpty) {
      return const SizedBox.shrink();
    }

    // Get category-specific color
    Color categoryColor = _selectedCategory == 'Food'
        ? Colors.orange
        : _selectedCategory == 'Drink'
        ? Colors.pink
        : _selectedCategory == 'Dessert'
        ? Colors.red
        : const Color(0xFFBE8C63);

    // Get category-specific icon
    IconData categoryIcon = _selectedCategory == 'Food'
        ? Icons.restaurant
        : _selectedCategory == 'Drink'
        ? Icons.local_drink
        : _selectedCategory == 'Dessert'
        ? Icons.cake
        : Icons.fastfood;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            (1 - _animationController.value) * 30,
          ),
          child: Opacity(
            opacity: _animationController.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: size.width * 0.04,
          vertical: size.height * 0.02,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              categoryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: categoryColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    categoryColor.withOpacity(0.2),
                    categoryColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
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
                          color: categoryColor.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      categoryIcon,
                      color: categoryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_selectedCategory Category',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: categoryColor,
                          ),
                        ),
                        Text(
                          '${_filteredSnacks.length} items found',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _filterByCategory('All');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: categoryColor.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Show All',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: categoryColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.refresh,
                            size: 14,
                            color: categoryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category items
            _filteredSnacks.isEmpty
                ? Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No $_selectedCategory items available',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
                : Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _filteredSnacks.length > 4 ? 4 : _filteredSnacks
                    .length,
                itemBuilder: (context, index) {
                  final snack = _filteredSnacks[index];
                  return GestureDetector(
                    onTap: () => _navigateToDetailPage(snack),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product image
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                                child: snack.imageUrl.isNotEmpty
                                    ? Image.network(
                                  AppConfig.baseUrl + snack.imageUrl,
                                  height: size.width * 0.3,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: size.width * 0.3,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey),
                                    );
                                  },
                                )
                                    : Container(
                                  height: size.width * 0.3,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported,
                                      color: Colors.grey),
                                ),
                              ),
                              // Category badge
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: categoryColor.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        categoryIcon,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _selectedCategory,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Rating badge
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        (_reviewRatings[snack.id] ?? snack.rating).toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Product details
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  snack.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E3E5C),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rp${snack.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: categoryColor,
                                  ),
                                ),
                                // Removed the View Details button that was causing overflow
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // View all button
            if (_filteredSnacks.length > 4)
              Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () {
                    // Show all category items
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _buildFullCategoryResults(context),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          categoryColor.withOpacity(0.8),
                          categoryColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: categoryColor.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View All ${_filteredSnacks
                              .length} $_selectedCategory Items',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

// Add this method to show all category items in a bottom sheet
  Widget _buildFullCategoryResults(BuildContext context) {
    final size = MediaQuery
        .of(context)
        .size;

    // Get category-specific color
    Color categoryColor = _selectedCategory == 'Food'
        ? Colors.orange
        : _selectedCategory == 'Drink'
        ? Colors.pink
        : _selectedCategory == 'Dessert'
        ? Colors.red
        : const Color(0xFFBE8C63);

    // Get category-specific icon
    IconData categoryIcon = _selectedCategory == 'Food'
        ? Icons.restaurant
        : _selectedCategory == 'Drink'
        ? Icons.local_drink
        : _selectedCategory == 'Dessert'
        ? Icons.cake
        : Icons.fastfood;

    return Container(
      height: size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  categoryColor.withOpacity(0.2),
                  categoryColor.withOpacity(0.1),
                ],
              ),
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
                        color: categoryColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    categoryIcon,
                    color: categoryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All $_selectedCategory Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: categoryColor,
                        ),
                      ),
                      Text(
                        '${_filteredSnacks.length} items found',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Grid of items
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _filteredSnacks.length,
              itemBuilder: (context, index) {
                final snack = _filteredSnacks[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToDetailPage(snack);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product image
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: snack.imageUrl.isNotEmpty
                                  ? Image.network(
                                AppConfig.baseUrl + snack.imageUrl,
                                height: size.width * 0.3,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: size.width * 0.3,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_not_supported,
                                        color: Colors.grey),
                                  );
                                },
                              )
                                  : Container(
                                height: size.width * 0.3,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported,
                                    color: Colors.grey),
                              ),
                            ),
                            // Type badge
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      snack.type.toLowerCase() == 'food'
                                          ? Icons.restaurant
                                          : snack.type.toLowerCase() == 'drink'
                                          ? Icons.local_drink
                                          : snack.type.toLowerCase() ==
                                          'dessert'
                                          ? Icons.cake
                                          : Icons.fastfood,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      snack.type,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Rating badge
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (_reviewRatings[snack.id] ?? snack.rating).toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Product details
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                snack.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E3E5C),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rp${snack.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllProducts(BuildContext context) {
    final size = MediaQuery
        .of(context)
        .size;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            (1 - _animationController.value) * 30,
          ),
          child: Opacity(
            opacity: _animationController.value,
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'All Products',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E3E5C),
                  ),
                ),
                if (_snacks.length > 6)
                  TextButton(
                    onPressed: () {
                      // Show all products
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) =>
                            _buildAllProductsFullView(context),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: size.height * 0.02),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
            child: _snacks.isEmpty
                ? Center(
              child: Text(
                'No products available',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            )
                : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _snacks.length > 6 ? 6 : _snacks.length,
              itemBuilder: (context, index) {
                final snack = _snacks[index];
                return GestureDetector(
                  onTap: () => _navigateToDetailPage(snack),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product image
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: snack.imageUrl.isNotEmpty
                                  ? Image.network(
                                AppConfig.baseUrl + snack.imageUrl,
                                height: size.width * 0.3,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: size.width * 0.3,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_not_supported,
                                        color: Colors.grey),
                                  );
                                },
                              )
                                  : Container(
                                height: size.width * 0.3,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported,
                                    color: Colors.grey),
                              ),
                            ),
                            // Type badge
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      snack.type.toLowerCase() == 'food'
                                          ? Icons.restaurant
                                          : snack.type.toLowerCase() == 'drink'
                                          ? Icons.local_drink
                                          : snack.type.toLowerCase() ==
                                          'dessert'
                                          ? Icons.cake
                                          : Icons.fastfood,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      snack.type,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Rating badge
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (_reviewRatings[snack.id] ?? snack.rating).toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Product details
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                snack.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E3E5C),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rp${snack.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_snacks.length > 6)
            Padding(
              padding: EdgeInsets.all(size.width * 0.04),
              child: GestureDetector(
                onTap: () {
                  // Show all products
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => _buildAllProductsFullView(context),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.green.shade700.withOpacity(0.8),
                        Colors.green.shade700,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade700.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View All ${_snacks.length} Products',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

// Add a method to show all products in a full view
  Widget _buildAllProductsFullView(BuildContext context) {
    final size = MediaQuery
        .of(context)
        .size;

    return Container(
      height: size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.shade700.withOpacity(0.2),
                  Colors.green.shade700.withOpacity(0.1),
                ],
              ),
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
                        color: Colors.green.shade700.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.fastfood,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Products',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      Text(
                        '${_snacks.length} items found',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Grid of items
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _snacks.length,
              itemBuilder: (context, index) {
                final snack = _snacks[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToDetailPage(snack);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product image
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: snack.imageUrl.isNotEmpty
                                  ? Image.network(
                                AppConfig.baseUrl + snack.imageUrl,
                                height: size.width * 0.3,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: size.width * 0.3,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_not_supported,
                                        color: Colors.grey),
                                  );
                                },
                              )
                                  : Container(
                                height: size.width * 0.3,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported,
                                    color: Colors.grey),
                              ),
                            ),
                            // Type badge
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      snack.type.toLowerCase() == 'food'
                                          ? Icons.restaurant
                                          : snack.type.toLowerCase() == 'drink'
                                          ? Icons.local_drink
                                          : snack.type.toLowerCase() ==
                                          'dessert'
                                          ? Icons.cake
                                          : Icons.fastfood,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      snack.type,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Rating badge
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (_reviewRatings[snack.id] ?? snack.rating).toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Product details
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                snack.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E3E5C),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rp${snack.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

// Update the build method to include the category results section
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFD1E7D1).withOpacity(0.3),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.3],
                ),
              ),
            ),

            // Main content
            Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: const Interval(0.2, 1.0),
                          ),
                        ),
                        child: child,
                      );
                    },
                    child: _isLoading
                        ? _buildCategoryLoadingIndicator(context)
                        : _errorMessage.isNotEmpty
                        ? _buildErrorView()
                        : SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSearchBar(context),
                          _buildSearchResults(context),
                          // Search results section
                          if (_popularSnacks.isNotEmpty && _searchQuery.isEmpty)
                            _buildHighlightCarousel(context),
                          if (_searchQuery.isEmpty)
                            _buildCategories(context),
                          if (_searchQuery.isEmpty)
                            _buildCategoryResults(context),
                          // Category results section
                          if (_searchQuery.isEmpty && _selectedCategory ==
                              'All')
                            _buildAllProducts(context),
                          // Changed from _buildPopularPicks to _buildAllProducts
                          const SizedBox(height: 100),
                          // Space for bottom nav
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: const NavBar(),
      ),
    );
  }
}
