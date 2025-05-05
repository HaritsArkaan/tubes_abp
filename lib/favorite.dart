import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:like_button/like_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'navbar.dart';
import 'detailJajanan.dart';
import 'models/favorite.dart';
import 'models/snack.dart';
import 'models/reviewStatistic.dart';
import 'services/api_favorite.dart';
import 'services/api_snack.dart';
import 'services/api_review.dart';
import 'config.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({Key? key}) : super(key: key);

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';

  // User data
  int _userId = 0;
  String _token = '';

  // API services
  final ApiFavorite _apiFavorite = ApiFavorite();
  final ApiService _apiSnack = ApiService();
  final ApiReview _apiReview = ApiReview();

  // Data storage
  List<Favorite> _favorites = [];
  Map<int, Snack> _snacks = {};
  Map<int, ReviewStatistic> _reviewStats = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('username');

      if (userData != null) {
        final userId = prefs.getInt('user_id');
        final token = prefs.getString('jwt_token') ?? '';

        if (mounted) {
          setState(() {
            _userId = userId!;
            _token = token;
          });

          await _loadFavorites();
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isError = true;
            _errorMessage = 'User not logged in';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = 'Failed to load user data: $e';
        });
      }
      print('Error loading user data: $e');
    }
  }

  // Load favorites and related data
  Future<void> _loadFavorites() async {
    try {
      if (_userId == 0 || _token.isEmpty) {
        throw Exception('User ID or token is missing');
      }

      setState(() {
        _isLoading = true;
        _isError = false;
      });

      // Fetch favorites
      final favorites = await _apiFavorite.getFavoritesByUserId(_userId, _token);

      if (mounted) {
        setState(() {
          _favorites = favorites;
        });

        // Fetch snack details for each favorite
        await _fetchSnackDetails();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = 'Failed to load favorites: $e';
        });
      }
      print('Error loading favorites: $e');
    }
  }

  // Fetch snack details for all favorites
  Future<void> _fetchSnackDetails() async {
    try {
      final futures = <Future>[];

      for (final favorite in _favorites) {
        futures.add(_fetchSnackDetail(favorite.snackId));
      }

      await Future.wait(futures);

      // After all snacks are fetched, fetch review statistics
      await _fetchReviewStatistics();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = 'Failed to load snack details: $e';
        });
      }
      print('Error fetching snack details: $e');
    }
  }

  // Fetch a single snack detail
  Future<void> _fetchSnackDetail(int snackId) async {
    try {
      final snack = await _apiSnack.getSnackById(snackId);

      if (mounted) {
        setState(() {
          _snacks[snackId] = snack;
        });
      }
    } catch (e) {
      print('Error fetching snack $snackId: $e');
    }
  }

  // Fetch review statistics for all snacks
  Future<void> _fetchReviewStatistics() async {
    try {
      if (_snacks.isEmpty) {
        print('No snacks to fetch review statistics for');
        return;
      }

      print('Fetching review statistics for ${_snacks.length} snacks');

      final futures = <Future>[];

      for (final snackId in _snacks.keys) {
        futures.add(_fetchReviewStatistic(snackId));
      }

      await Future.wait(futures);
    } catch (e) {
      print('Error fetching review statistics: $e');
    }
  }

  // Fetch review statistics for a single snack
  Future<void> _fetchReviewStatistic(int snackId) async {
    try {
      final response = await _apiReview.getReviewStatistics(snackId);

      ReviewStatistic? stats;
      if (response is Map<String, dynamic>) {
        stats = ReviewStatistic.fromJson(response);
      } else if (response is List && response.isNotEmpty) {
        stats = ReviewStatistic.fromJson(response[0]);
      }

      if (stats != null && mounted) {
        setState(() {
          _reviewStats[snackId] = stats!;
        });
      }
    } catch (e) {
      print('Error fetching review statistics for snack $snackId: $e');
    }
  }

  // Toggle favorite status
  Future<void> _toggleFavorite(int snackId) async {
    try {
      // Here you would call the API to toggle the favorite status
      // For now, we'll just remove it from the local list
      setState(() {
        _favorites.removeWhere((favorite) => favorite.snackId == snackId);
        _snacks.remove(snackId);
        _reviewStats.remove(snackId);
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from favorites'),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error toggling favorite: $e');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update favorite: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFFF5F9F5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.05,
                  vertical: size.height * 0.02,
                ),
                child: Row(
                  children: [
                    // Back button
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Color(0xFF4CAF50),
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title with animation
                    Text(
                      'Favorite',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4CAF50),
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideX(
                      begin: -0.1,
                      end: 0,
                      curve: Curves.easeOutQuad,
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingGrid(size)
                    : _isError
                    ? _buildErrorView()
                    : _favorites.isEmpty
                    ? _buildEmptyView()
                    : _buildFavoritesGrid(size),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const NavBar(),
    );
  }

  // Build loading grid with shimmer effect
  Widget _buildLoadingGrid(Size size) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
      child: MasonryGridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 15,
        crossAxisSpacing: 12,
        itemCount: 9,
        itemBuilder: (context, i) {
          return _buildShimmerItem(size, i);
        },
      ),
    );
  }

  // Build shimmer loading item
  Widget _buildShimmerItem(Size size, int i) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: size.width * (0.25 + (i % 3) * 0.05),
            width: size.width * 0.3,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: size.width * 0.2,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 10,
            width: size.width * 0.15,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  // Build error view
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadFavorites,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // Build empty view
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.favorite_border,
            color: Color(0xFF4CAF50),
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            'No Favorites Yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding your favorite snacks!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Explore Snacks'),
          ),
        ],
      ),
    );
  }

  // Build favorites grid
  Widget _buildFavoritesGrid(Size size) {
    return RefreshIndicator(
      color: const Color(0xFF4CAF50),
      onRefresh: _loadFavorites,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
        child: MasonryGridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 15,
          crossAxisSpacing: 12,
          itemCount: _favorites.length,
          itemBuilder: (context, index) {
            final favorite = _favorites[index];
            final snack = _snacks[favorite.snackId];
            final stats = _reviewStats[favorite.snackId];

            if (snack == null) {
              return const SizedBox.shrink();
            }

            return _buildFavoriteItem(snack, stats, size, index)
                .animate()
                .fadeIn(
              delay: Duration(milliseconds: 50 * index),
              duration: 400.ms,
            )
                .slideY(
              begin: 0.1,
              end: 0,
              delay: Duration(milliseconds: 50 * index),
              curve: Curves.easeOutQuad,
            );
          },
        ),
      ),
    );
  }

  // Build favorite item
  Widget _buildFavoriteItem(Snack snack, ReviewStatistic? stats, Size size, int index) {
    // Vary the height slightly for visual interest
    final heightFactor = 0.25 + (index % 3) * 0.05;
    final rating = stats?.averageRating ?? 0.0;
    final reviewCount = stats?.reviewCount ?? 0;

    return GestureDetector(
      onTap: () {
        // Navigate to detail page
        Navigator.pushNamed(
          context,
          '/detailJajanan',
          arguments: snack,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food image with favorite button
          Stack(
            children: [
              // Food image
              Hero(
                tag: 'food_${snack.id}',
                child: Container(
                  height: size.width * heightFactor,
                  width: size.width * 0.3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
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
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: '${AppConfig.baseUrl}${snack.imageUrl}',
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.error, color: Colors.red),
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // Favorite button
              Positioned(
                right: 5,
                bottom: 5,
                child: LikeButton(
                  size: size.width * 0.06,
                  isLiked: true, // Always true since this is the favorites page
                  circleColor: const CircleColor(
                    start: Color(0xFF4CAF50),
                    end: Color(0xFF66BB6A),
                  ),
                  bubblesColor: const BubblesColor(
                    dotPrimaryColor: Color(0xFF4CAF50),
                    dotSecondaryColor: Color(0xFF66BB6A),
                  ),
                  likeBuilder: (bool isLiked) {
                    return Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? const Color(0xFF4CAF50) : Colors.grey,
                      size: size.width * 0.05,
                    );
                  },
                  onTap: (isLiked) async {
                    await _toggleFavorite(snack.id);
                    return false; // We handle the state change manually
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Food name
          Text(
            snack.name,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Rating
          Row(
            children: [
              const Icon(
                Icons.star,
                color: Color(0xFFFFD700),
                size: 14,
              ),
              const SizedBox(width: 2),
              Text(
                '$rating ($reviewCount)',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
