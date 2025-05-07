import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snack_hunt/config.dart';
import 'models/snack.dart';
import 'models/review.dart';
import 'models/reviewStatistic.dart';
import 'services/api_review.dart';
import 'navbar.dart'; // Import the existing NavBar

class FoodDetailPage extends StatefulWidget {
  const FoodDetailPage({Key? key}) : super(key: key);

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _heartController;
  late AnimationController _scrollAnimController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isFavorite = false;
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;

  // API service
  final ApiReview _apiReview = ApiReview();

  // State variables
  List<Review> _reviews = [];
  ReviewStatistic? _reviewStatistic;
  bool _isLoadingReviews = true;
  bool _isLoadingStats = true;
  String? _errorMessage;

  // User state
  bool _isGuestMode = true;

  @override
  void initState() {
    super.initState();

    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scrollAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scrollController.addListener(_onScroll);

    _animationController.forward();

    // Check if user is in guest mode
    _checkGuestMode();
  }

  // Check if user is in guest mode - FIXED
  Future<void> _checkGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check for jwt_token directly - this is the primary indicator of login status
      final token = prefs.getString('jwt_token');

      // Only consider guest mode if explicitly set AND no token exists
      // final isExplicitlyGuest = prefs.getBool('is_guest_mode') ?? false;

      if (mounted) {
        setState(() {
          // User is in guest mode if they have no token OR they're explicitly in guest mode
          _isGuestMode = token == null;

          // Debug output to help troubleshoot
          print('Login status check: token=${token != null}, _isGuestMode=$_isGuestMode');
        });
      }
    } catch (e) {
      print('Error checking guest mode: $e');
      // Default to guest mode if there's an error
      if (mounted) {
        setState(() {
          _isGuestMode = true;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the snack from route arguments
    final snack = ModalRoute.of(context)?.settings.arguments as Snack?;

    if (snack != null) {
      // Fetch review statistics and reviews
      _fetchReviewStatistics(snack.id);
      _fetchReviews(snack.id);
    }
  }

  // Fetch review statistics
  Future<void> _fetchReviewStatistics(int snackId) async {
    if (!mounted) return;

    setState(() {
      _isLoadingStats = true;
      _errorMessage = null;
    });

    try {
      final dynamic response = await _apiReview.getReviewStatistics(snackId);

      if (response is Map<String, dynamic>) {
        if (mounted) {
          setState(() {
            _reviewStatistic = ReviewStatistic.fromJson(response);
            _isLoadingStats = false;
          });
        }
      } else if (response is List && response.isNotEmpty && response[0] is Map<String, dynamic>) {
        if (mounted) {
          setState(() {
            _reviewStatistic = ReviewStatistic.fromJson(response[0]);
            _isLoadingStats = false;
          });
        }
      } else {
        // Handle unexpected response format
        if (mounted) {
          setState(() {
            _reviewStatistic = ReviewStatistic(reviewCount: 0, averageRating: 0.0);
            _isLoadingStats = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching review statistics: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load review statistics';
          _isLoadingStats = false;
          _reviewStatistic = ReviewStatistic(reviewCount: 0, averageRating: 0.0);
        });
      }
    }
  }

  // Fetch reviews
  Future<void> _fetchReviews(int snackId) async {
    if (!mounted) return;

    setState(() {
      _isLoadingReviews = true;
      _errorMessage = null;
    });

    try {
      final reviews = await _apiReview.getReviewsBySnackId(snackId);

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });

        // Fetch user names for each review
        for (var review in reviews) {
          _cacheUserName(review.userId.toString());
        }
      }
    } catch (e) {
      print('Error fetching reviews: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load reviews';
          _isLoadingReviews = false;
        });
      }
    }
  }

  // Add this method to cache user names
  Future<void> _cacheUserName(String userId) async {
    try {
      // This is where you would call your user API to get the user details
      // For example:
      // final userDetails = await _userApiService.getUserDetails(int.parse(userId));
      // final userName = userDetails.name;

      // For now, we'll use a placeholder
      final userName = '$userId';

      // Cache the user name
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username_$userId', userName);
    } catch (e) {
      print('Error caching user name: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.offset > 180 && !_showTitle) {
      setState(() {
        _showTitle = true;
      });
      _scrollAnimController.forward();
    } else if (_scrollController.offset <= 180 && _showTitle) {
      setState(() {
        _showTitle = false;
      });
      _scrollAnimController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _heartController.dispose();
    _scrollAnimController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Show login prompt dialog
  void _showLoginPrompt(String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF1F8E9),
                  Color(0xFFDCEDC8),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8BC34A).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      feature == 'favorite' ? Icons.favorite : Icons.rate_review,
                      color: const Color(0xFF8BC34A),
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Login Required',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF689F38),
                  ),
                ),
                const SizedBox(height: 16),

                // Message
                Text(
                  feature == 'favorite'
                      ? 'You need to login to add this snack to your favorites.'
                      : 'You need to login to write a review.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.of(context).pushNamed('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8BC34A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Login Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Cancel Button
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Maybe Later',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show the Add Review dialog
  void _showAddReviewDialog() {
    // If in guest mode, show login prompt instead
    if (_isGuestMode) {
      _showLoginPrompt('review');
      return;
    }

    // Get the snack from route arguments BEFORE showing the dialog
    final Snack snack = ModalRoute.of(context)!.settings.arguments as Snack;

    double _selectedRating = 0;
    final TextEditingController _reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF1F8E9),
                      Color(0xFFDCEDC8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title with animation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Add Your Review',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF689F38),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: Lottie.network(
                            'https://assets5.lottiefiles.com/packages/lf20_touohxv0.json',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Rating
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Your Rating',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Star Rating
                    Center(
                      child: RatingBar.builder(
                        initialRating: 0,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemSize: 40,
                        unratedColor: Colors.amber.withOpacity(0.3),
                        itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
                        itemBuilder: (context, _) => const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                        ),
                        onRatingUpdate: (rating) {
                          setState(() {
                            _selectedRating = rating;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Review Text
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Your Review',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Review Text Field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF8BC34A).withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8BC34A).withOpacity(0.05),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _reviewController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Share your thoughts about this food...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          contentPadding: const EdgeInsets.all(16),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_selectedRating > 0 && _reviewController.text.isNotEmpty) {
                            // Show loading indicator
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Row(
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Submitting your review...'),
                                  ],
                                ),
                                backgroundColor: Color(0xFF8BC34A),
                                duration: Duration(seconds: 30), // Long duration as we'll dismiss it manually
                              ),
                            );

                            try {
                              // Get the current user ID from SharedPreferences
                              final prefs = await SharedPreferences.getInstance();
                              final userId = prefs.getInt('user_id');
                              final token = prefs.getString('jwt_token');

                              if (userId == null || token == null) {
                                throw Exception('User not logged in');
                              }

                              // Use the snack object captured before showing the dialog
                              // No need to get it from ModalRoute again

                              final review = Review(
                                id: 0,
                                userId: userId,
                                snackId: snack.id,
                                rating: _selectedRating,
                                content: _reviewController.text,
                              );

                              // Call the API to create the review
                              await _apiReview.createReview(review, token);

                              // Dismiss the loading snackbar
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white),
                                      SizedBox(width: 12),
                                      Text('Review added successfully!'),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF8BC34A),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: const EdgeInsets.all(12),
                                ),
                              );

                              // Refresh the reviews and statistics
                              if (mounted) {
                                final snack = ModalRoute.of(context)?.settings.arguments as Snack?;
                                if (snack != null) {
                                  _fetchReviewStatistics(snack.id);
                                  _fetchReviews(snack.id);
                                }
                              }
                            } catch (e) {
                              // Dismiss the loading snackbar
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();

                              // Show error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.error, color: Colors.white),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text('Failed to add review: ${e.toString()}')),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: const EdgeInsets.all(12),
                                ),
                              );
                              final snack = ModalRoute.of(context)?.settings.arguments as Snack?;
                              print('Error adding review: $e');
                            }
                          } else {
                            // Show error message for invalid input
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.error, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text('Please add a rating and review text'),
                                  ],
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.all(12),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8BC34A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Submit Review',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      // Refresh the UI after dialog is closed
      final snack = ModalRoute.of(context)?.settings.arguments as Snack?;
      if (snack != null) {
        _fetchReviewStatistics(snack.id);
        _fetchReviews(snack.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the height of the bottom navigation bar
    // This is an estimate - adjust if your NavBar has a different height
    final navBarHeight = 80.0;
    final snack = ModalRoute.of(context)!.settings.arguments as Snack;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AnimatedBuilder(
          animation: _scrollAnimController,
          builder: (context, child) {
            return AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: _showTitle ? GlassmorphicContainer(
                width: MediaQuery.of(context).size.width,
                height: 56 + MediaQuery.of(context).padding.top,
                borderRadius: 0,
                blur: 10,
                alignment: Alignment.bottomCenter,
                border: 0,
                linearGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.2),
                  ],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
              ) : null,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _showTitle
                        ? const Color(0xFF8BC34A)
                        : const Color(0xFF8BC34A).withOpacity(0.8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              title: _showTitle ? Text(
                snack.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Color.fromARGB(150, 0, 0, 0),
                    ),
                  ],
                ),
              ) : null,
              actions: [
                // Only show favorite button if not in guest mode
                if (!_isGuestMode)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isFavorite = !_isFavorite;
                      });
                      if (_isFavorite) {
                        _heartController.reset();
                        _heartController.forward();
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _showTitle
                            ? Colors.white.withOpacity(0.3)
                            : const Color(0xFF8BC34A).withOpacity(0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
              ],
            );
          },
        ),
      ),
      body: Stack(
        children: [
          // Background Image with Gradient Overlay
          Hero(
            tag: 'food-image-${snack.id}',
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              child: Stack(
                children: [
                  // Image
                  CachedNetworkImage(
                    imageUrl: '${AppConfig.baseUrl}${snack.imageUrl}',
                    fit: BoxFit.cover,
                    height: double.infinity,
                    width: double.infinity,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // Heart animation when favorited
                  if (_isFavorite && !_isGuestMode)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _heartController,
                        builder: (context, child) {
                          return _heartController.value > 0
                              ? Opacity(
                            opacity: _heartController.value < 0.5
                                ? _heartController.value * 2
                                : 1 - ((_heartController.value - 0.5) * 2),
                            child: Center(
                              child: Icon(
                                Icons.favorite,
                                color: Colors.red.withOpacity(0.8),
                                size: 100 + (_heartController.value * 50),
                              ),
                            ),
                          )
                              : const SizedBox.shrink();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Spacer to push content down
                SizedBox(height: MediaQuery.of(context).size.height * 0.35),

                // Main Content Card
                Expanded(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          // Add padding at the bottom to account for the navbar
                          padding: EdgeInsets.only(bottom: navBarHeight + 20),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Food Title and Favorite
                                Row(
                                  children: [
                                    // Logo with 3D effect
                                    Container(
                                      height: 50,
                                      width: 50,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.orange,
                                            Colors.deepOrange,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.orange.withOpacity(0.4),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          snack.name[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15),

                                    // Title
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            snack.name,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          // Only show Top Rated badge if conditions are met
                                          if (_reviewStatistic != null &&
                                              _reviewStatistic!.averageRating > 4.5 &&
                                              _reviewStatistic!.reviewCount >= 5)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF8BC34A).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Top Rated',
                                                style: TextStyle(
                                                  color: Color(0xFF689F38),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    // Favorite Button (on mobile) - Modified for guest mode
                                    GestureDetector(
                                      onTap: () {
                                        if (_isGuestMode) {
                                          // Show login prompt for guests
                                          _showLoginPrompt('favorite');
                                        } else {
                                          setState(() {
                                            _isFavorite = !_isFavorite;
                                          });
                                          if (_isFavorite) {
                                            _heartController.reset();
                                            _heartController.forward();
                                          }
                                        }
                                      },
                                      child: Stack(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: _isFavorite && !_isGuestMode
                                                  ? Colors.red.withOpacity(0.1)
                                                  : Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey.withOpacity(0.2),
                                                  spreadRadius: 1,
                                                  blurRadius: 3,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              _isFavorite && !_isGuestMode
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: _isFavorite && !_isGuestMode
                                                  ? Colors.red
                                                  : _isGuestMode
                                                  ? Colors.grey
                                                  : const Color(0xFF8BC34A),
                                              size: 24,
                                            ),
                                          ),

                                          // Lock icon overlay for guest mode
                                          if (_isGuestMode)
                                            Positioned(
                                              right: 0,
                                              bottom: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[100],
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.lock,
                                                  color: Colors.grey,
                                                  size: 10,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Rating and Reviews Count
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.grey[50]!,
                                        Colors.grey[100]!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 4,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: _isLoadingStats
                                      ? const Center(
                                    child: SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF8BC34A),
                                      ),
                                    ),
                                  )
                                      : Row(
                                    children: [
                                      RatingBar.builder(
                                        initialRating: _reviewStatistic?.averageRating ?? 0,
                                        minRating: 0,
                                        direction: Axis.horizontal,
                                        allowHalfRating: true,
                                        itemCount: 5,
                                        itemSize: 20,
                                        ignoreGestures: true,
                                        itemPadding: const EdgeInsets.symmetric(horizontal: 1.0),
                                        itemBuilder: (context, _) => const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                        ),
                                        onRatingUpdate: (rating) {},
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${_reviewStatistic?.averageRating.toStringAsFixed(1) ?? "0.0"}/5',
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '(${_reviewStatistic?.reviewCount ?? 0} reviews)',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8BC34A).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.thumb_up_alt,
                                              size: 14,
                                              color: Color(0xFF8BC34A),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _reviewStatistic?.averageRating != null && _reviewStatistic!.averageRating > 0
                                                  ? '${((_reviewStatistic!.averageRating / 5) * 100).toInt()}%'
                                                  : '0%',
                                              style: TextStyle(
                                                color: Colors.grey[800],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Price and Tags
                                Row(
                                  children: [
                                    // Price with animated background
                                    TweenAnimationBuilder<double>(
                                      tween: Tween<double>(begin: 0, end: 1),
                                      duration: const Duration(milliseconds: 1000),
                                      curve: Curves.elasticOut,
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: 0.8 + (0.2 * value),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Color(0xFF8BC34A),
                                                  Color(0xFF689F38),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF8BC34A).withOpacity(0.3),
                                                  blurRadius: 8,
                                                  spreadRadius: 0,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.monetization_on,
                                                  size: 18,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Rp ${snack.price.toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 12),

                                    // Tags
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        child: Row(
                                          children: [
                                            _buildTag(snack.type, _getIconForType(snack.type)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Location and Contact
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.grey[50]!,
                                        Colors.grey[100]!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // Location
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Color(0xFF8BC34A),
                                                  Color(0xFF689F38),
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF8BC34A).withOpacity(0.3),
                                                  blurRadius: 8,
                                                  spreadRadius: 0,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.location_on,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Location',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  snack.location,
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF8BC34A).withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.directions,
                                              color: Color(0xFF8BC34A),
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 16),
                                        child: Divider(
                                          color: Color(0xFFE0E0E0),
                                          thickness: 1,
                                        ),
                                      ),

                                      // Phone
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Color(0xFF8BC34A),
                                                  Color(0xFF689F38),
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF8BC34A).withOpacity(0.3),
                                                  blurRadius: 8,
                                                  spreadRadius: 0,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.phone,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Phone',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  snack.contact,
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF8BC34A).withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.call,
                                              color: Color(0xFF8BC34A),
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Add Review Button with animation - Modified for guest mode
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: 1),
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutBack,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            height: 55,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: _isGuestMode
                                                    ? [Colors.grey[300]!, Colors.grey[400]!]
                                                    : [
                                                  const Color(0xFF8BC34A),
                                                  const Color(0xFF689F38),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: _isGuestMode
                                                      ? Colors.grey.withOpacity(0.3)
                                                      : const Color(0xFF8BC34A).withOpacity(0.3),
                                                  blurRadius: 8,
                                                  spreadRadius: 0,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: _showAddReviewDialog,
                                                borderRadius: BorderRadius.circular(16),
                                                splashColor: Colors.white.withOpacity(0.1),
                                                highlightColor: Colors.white.withOpacity(0.1),
                                                child: Center(
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.rate_review,
                                                        color: Colors.white,
                                                        size: 24,
                                                      ),
                                                      SizedBox(width: 12),
                                                      Text(
                                                        'Write a Review',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Lock icon overlay for guest mode
                                          if (_isGuestMode)
                                            Positioned(
                                              right: 16,
                                              top: 0,
                                              bottom: 0,
                                              child: Center(
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.9),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.lock,
                                                    color: Colors.grey,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 24),

                                // Reviews Header
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Reviews',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8BC34A).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFF8BC34A).withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Text(
                                        'View All',
                                        style: TextStyle(
                                          color: Color(0xFF689F38),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Reviews
                                _isLoadingReviews
                                    ? Center(
                                  child: SizedBox(
                                    height: 100,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const CircularProgressIndicator(
                                          color: Color(0xFF8BC34A),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Loading reviews...',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                    : _reviews.isEmpty
                                    ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.rate_review_outlined,
                                        color: Color(0xFF8BC34A),
                                        size: 48,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No reviews yet',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _isGuestMode
                                            ? 'Login to be the first to review this snack!'
                                            : 'Be the first to review this snack!',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                    : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _reviews.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final review = _reviews[index];
                                    return _buildReviewCard(
                                      review.userId.toString(),
                                      review.rating.toInt(),
                                      review.content,
                                      DateTime.now(), // Assuming the API doesn't provide a date
                                    );
                                  },
                                ),

                                // Guest mode indicator - Only show if in guest mode
                                if (_isGuestMode)
                                  Container(
                                    margin: const EdgeInsets.only(top: 24),
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'You are in guest mode. Login to add favorites and write reviews.',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pushNamed('/login');
                                          },
                                          style: TextButton.styleFrom(
                                            backgroundColor: const Color(0xFF8BC34A),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Login',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Use extendBody to make the body extend behind the navbar
      extendBody: true,
      bottomNavigationBar: const NavBar(),
    );
  }

  // Helper method to get icon based on food type
  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'drink':
        return Icons.local_drink;
      case 'dessert':
        return Icons.cake;
      case 'snack':
        return Icons.fastfood;
      case 'food':
        return Icons.restaurant;
      default:
        return Icons.fastfood;
    }
  }

  Widget _buildTag(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF8BC34A).withOpacity(0.8),
            const Color(0xFF689F38).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8BC34A).withOpacity(0.2),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String userId, int rating, String comment, DateTime date) {
    // Fetch user name from the API or local storage based on userId
    // This is a placeholder - in a real app, you would get the actual user name
    String userName = "User"; // Default name if we can't get the real name

    // Try to get the user name from SharedPreferences or other local storage
    _getUserName(userId).then((name) {
      if (name != null && name.isNotEmpty) {
        userName = name;
      }
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and rating
          Row(
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getAvatarColor(userName).withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: _getAvatarColor(userName),
                  child: Text(
                    userName.isNotEmpty ? userName[0] : "?",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(date),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Rating stars
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // Comment
          Text(
            comment,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

// Add this method to fetch user name from userId
  Future<String?> _getUserName(String userId) async {
    try {
      // First try to get from local cache
      final prefs = await SharedPreferences.getInstance();
      String? cachedName = prefs.getString('username_$userId');

      if (cachedName != null && cachedName.isNotEmpty) {
        return cachedName;
      }

      // If not in cache, try to fetch from API
      // This is where you would call your user API to get the user details
      // For example:
      // final userDetails = await _userApiService.getUserDetails(int.parse(userId));
      // return userDetails.name;

      // For now, we'll return a placeholder based on userId
      return 'User $userId';
    } catch (e) {
      print('Error fetching user name: $e');
      return null;
    }
  }

  Color _getAvatarColor(String name) {
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    // Simple hash function to get consistent color for the same name
    int hash = 0;
    for (var i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }

    return colors[hash.abs() % colors.length];
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
