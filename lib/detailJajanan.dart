import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import 'package:glassmorphism/glassmorphism.dart';

// Add this class to handle the review functionality
class ReviewModel {
  final String userName;
  final int rating;
  final String comment;
  final String? avatarUrl;
  final DateTime date;

  ReviewModel({
    required this.userName,
    required this.rating,
    required this.comment,
    this.avatarUrl,
    DateTime? date,
  }) : date = date ?? DateTime.now();
}

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

  // List to store reviews
  List<ReviewModel> _reviews = [
    ReviewModel(
      userName: 'Jay',
      rating: 5,
      comment: 'Lorem ipsum dolor sit amet consectetur. Quisque varius suspendisse sed diam imperdiet eget.',
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ReviewModel(
      userName: 'Jeno',
      rating: 4,
      comment: 'Lorem ipsum dolor sit amet consectetur. Quisque varius suspendisse sed diam imperdiet eget.',
      date: DateTime.now().subtract(const Duration(days: 5)),
    ),
    ReviewModel(
      userName: 'Angga',
      rating: 3,
      comment: 'Lorem ipsum dolor sit amet consectetur. Quisque varius suspendisse sed diam imperdiet eget.',
      date: DateTime.now().subtract(const Duration(days: 7)),
    ),
    ReviewModel(
      userName: 'Jennie',
      rating: 4,
      comment: 'Lorem ipsum dolor sit amet consectetur. Quisque varius suspendisse sed diam imperdiet eget.',
      date: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

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

  // Show the Add Review dialog
  void _showAddReviewDialog() {
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFF1F8E9),
                      const Color(0xFFDCEDC8),
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
                        onPressed: () {
                          if (_selectedRating > 0 && _reviewController.text.isNotEmpty) {
                            // Add the review
                            setState(() {
                              _reviews.add(
                                ReviewModel(
                                  userName: 'You', // You could replace with actual user name
                                  rating: _selectedRating.round(),
                                  comment: _reviewController.text,
                                ),
                              );
                            });
                            Navigator.pop(context);

                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.white),
                                    const SizedBox(width: 12),
                                    const Text('Review added successfully!'),
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
                          } else {
                            // Show error message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.error, color: Colors.white),
                                    const SizedBox(width: 12),
                                    const Text('Please add a rating and review text'),
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
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
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
              title: _showTitle ? const Text(
                'Risoles Momo',
                style: TextStyle(
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
                GestureDetector(
                  onTap: () {
                    // Share functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sharing this food...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
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
                    child: const Icon(
                      Icons.share,
                      color: Colors.white,
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
            tag: 'food-image',
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              child: Stack(
                children: [
                  // Image
                  CachedNetworkImage(
                    imageUrl: 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80',
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
                  if (_isFavorite)
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
                                      child: const Center(
                                        child: Text(
                                          'RISOLE',
                                          style: TextStyle(
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
                                          const Text(
                                            'Risoles Momo',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
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

                                    // Favorite Button (on mobile)
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
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: _isFavorite ? Colors.red.withOpacity(0.1) : Colors.white,
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
                                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                                          color: _isFavorite ? Colors.red : const Color(0xFF8BC34A),
                                          size: 24,
                                        ),
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
                                  child: Row(
                                    children: [
                                      RatingBar.builder(
                                        initialRating: 5,
                                        minRating: 1,
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
                                        '5/5',
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '(22 reviews)',
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
                                              '98%',
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
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  const Color(0xFF8BC34A),
                                                  const Color(0xFF689F38),
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
                                                const Text(
                                                  'Rp 5.000',
                                                  style: TextStyle(
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
                                            _buildTag('Food', Icons.fastfood),
                                            const SizedBox(width: 8),
                                            _buildTag('Salty', Icons.restaurant),
                                            const SizedBox(width: 8),
                                            _buildTag('Snack', Icons.lunch_dining),
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
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  const Color(0xFF8BC34A),
                                                  const Color(0xFF689F38),
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
                                                  'Sukapura Blok 16',
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
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  const Color(0xFF8BC34A),
                                                  const Color(0xFF689F38),
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
                                                  '082208120322',
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

                                // Add Review Button with animation
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: 1),
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutBack,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: Container(
                                        width: double.infinity,
                                        height: 55,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              const Color(0xFF8BC34A),
                                              const Color(0xFF689F38),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF8BC34A).withOpacity(0.3),
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
                                                  const Icon(
                                                    Icons.rate_review,
                                                    color: Colors.white,
                                                    size: 24,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Text(
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
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.5,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  children: _reviews.map((review) => _buildReviewCard(
                                    review.userName,
                                    review.rating,
                                    review.comment,
                                    review.date,
                                  )).toList(),
                                ),

                                // Add some bottom padding for the navbar
                                const SizedBox(height: 80),
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
        bottomNavigationBar: const NavBar(selectedIndex: 1),
    );
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

  Widget _buildReviewCard(String name, int rating, String comment, DateTime date) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                      color: _getAvatarColor(name).withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: _getAvatarColor(name),
                  child: Text(
                    name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _formatDate(date),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Rating stars
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 14,
              );
            }),
          ),

          const SizedBox(height: 8),

          // Comment
          Expanded(
            child: Text(
              comment,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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

// Include the NavBar class we created earlier
class NavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int)? onItemSelected;

  const NavBar({
    Key? key,
    this.selectedIndex = 0,
    this.onItemSelected,
  }) : super(key: key);

  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> with TickerProviderStateMixin {
  late int _selectedIndex;
  late AnimationController _selectionController;
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;

  final List<GlobalKey> _navItemKeys = List.generate(4, (_) => GlobalKey());
  Offset _rippleCenter = Offset.zero;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;

    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _rippleAnimation = CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOutQuart,
    );
  }

  @override
  void dispose() {
    _selectionController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(NavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = widget.selectedIndex;
      });
      _selectionController.reset();
      _selectionController.forward();
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      // Get the position of the tapped item for ripple effect
      if (_navItemKeys[index].currentContext != null) {
        final RenderBox box = _navItemKeys[index].currentContext!.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero);
        final size = box.size;

        setState(() {
          _rippleCenter = Offset(
            position.dx + size.width / 2,
            position.dy + size.height / 2,
          );
          _selectedIndex = index;
        });

        _rippleController.reset();
        _rippleController.forward();

        if (widget.onItemSelected != null) {
          widget.onItemSelected!(index);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Adjust height based on bottom padding (for devices with notches)
    final navbarHeight = math.max(65, 65 + (bottomPadding > 0 ? bottomPadding - 10 : 0));

    return Container(
      height: navbarHeight.toDouble(),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8BC34A),
            Color(0xFF689F38),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ripple effect
          AnimatedBuilder(
            animation: _rippleAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(screenWidth, navbarHeight.toDouble()),
                painter: RipplePainter(
                  center: _rippleCenter,
                  radius: _rippleAnimation.value * screenWidth * 0.8,
                  color: Colors.white.withOpacity(0.1),
                ),
              );
            },
          ),

          // Nav items
          SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.add_circle_outline, Icons.add_circle, 'Add new'),
                _buildNavItem(2, Icons.favorite_border_rounded, Icons.favorite_rounded, 'Favorite'),
                _buildNavItem(3, Icons.photo_library_outlined, Icons.photo_library, 'My Review'),
              ],
            ),
          ),

          // Indicator line at the top of selected item
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            top: 0,
            left: _getIndicatorPosition(),
            child: Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 3,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getIndicatorPosition() {
    if (_navItemKeys.isEmpty || _navItemKeys[_selectedIndex].currentContext == null) {
      return 0;
    }

    final RenderBox box = _navItemKeys[_selectedIndex].currentContext!.findRenderObject() as RenderBox;
    final position = box.localToGlobal(Offset.zero);
    final size = box.size;

    return position.dx + (size.width - 40) / 2;
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      key: _navItemKeys[index],
      onTap: () => _onItemTapped(index),
      child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive sizing based on available width
            final itemWidth = math.min(85, constraints.maxWidth / 4.5);
            final iconSize = math.min(26, itemWidth * 0.35);
            final fontSize = math.min(12, itemWidth * 0.16);

            return Container(
              width: itemWidth.toDouble(),
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: isSelected ? 1.0 : 0.0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: value * math.pi * (index == 1 ? 0.5 : 0.05),
                          child: Icon(
                            value > 0.5 ? filledIcon : outlineIcon,
                            color: Colors.white,
                            size: iconSize + (value * 2), // Slightly larger when selected
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSelected ? fontSize.toDouble() + 1 : fontSize.toDouble(),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      letterSpacing: 0.2,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }
      ),
    );
  }
}

// Custom painter for ripple effect
class RipplePainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color color;

  RipplePainter({
    required this.center,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.radius != radius ||
        oldDelegate.color != color;
  }
}