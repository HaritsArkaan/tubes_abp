import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navbar.dart';
import 'config.dart';
import 'models/review.dart';
import 'models/snack.dart';
import 'models/reviewStatistic.dart';
import 'services/api_review.dart';
import 'services/api_snack.dart';

class MyReviewPage extends StatefulWidget {
  const MyReviewPage({Key? key}) : super(key: key);

  @override
  State<MyReviewPage> createState() => _MyReviewPageState();
}

class _MyReviewPageState extends State<MyReviewPage> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // API services
  final ApiReview _reviewService = ApiReview();
  final ApiService _snackService = ApiService();
  final ApiReview _reviewStatService = ApiReview();

  // Data
  List<Review> _reviews = [];
  Map<int, Snack> _snacks = {};
  Map<int, ReviewStatistic> _reviewStats = {};

  @override
  void initState() {
    super.initState();
    _fetchUserReviews();
  }

  // Fetch reviews by user ID
  Future<void> _fetchUserReviews() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Get user ID from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final userId = prefs.getInt('user_id');

      if (userId == null || token == null) {
        throw Exception('User ID or Token not found. Please log in again.');
      }

      // Fetch reviews by user ID
      final reviews = await _reviewService.getReviewsByUserId(userId, token)
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      if (!mounted) return;

      setState(() {
        _reviews = reviews;
      });

      // Fetch snack details and review statistics for each review
      await _fetchSnackDetails();

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load reviews: ${e.toString()}';
        print('Error fetching reviews: $e');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fetch snack details for each review
  Future<void> _fetchSnackDetails() async {
    if (_reviews.isEmpty) return;

    try {
      // Step 1: First fetch all snack details
      print('Fetching snack details for ${_reviews.length} reviews');
      for (final review in _reviews) {
        await _fetchSnackDetail(review.snackId);
      }

      // Step 2: Only after all snacks are fetched, fetch review statistics
      print('Snacks loaded: ${_snacks.length}. Now fetching review statistics.');
      if (_snacks.isNotEmpty) {
        await _fetchReviewStatistics();
      } else {
        print('No snacks were loaded, skipping review statistics fetch.');
      }
    } catch (e) {
      print('Error fetching additional data: $e');
      // Continue even if some requests fail
    }
  }

  // Fetch snack detail by ID
  Future<void> _fetchSnackDetail(int snackId) async {
    try {
      final snack = await _snackService.getSnackById(snackId)
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Snack detail request timed out');
        },
      );
      print('snack: ${snack.id}');

      if (mounted) {
        setState(() {
          _snacks[snackId] = snack;
        });
      }
    } catch (e) {
      print('Error fetching snack $snackId: $e');
      // Don't set error state, just log it
    }
  }

  // Fetch review statistics by snack ID
  Future<void> _fetchReviewStatistics() async {
    if (_snacks.isEmpty) {
      print('No snacks to fetch review statistics for.');
      return;
    }
    if (!mounted) return;

    try {
      print('Fetching review statistics for ${_snacks.length} snacks');
      for (var snackId in _snacks.keys) {
        if (!mounted) return; // Check if still mounted before each API call

        try {
          print('Fetching review statistics for snack ID: $snackId');
          final response = await _reviewStatService.getReviewStatistics(snackId)
              .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException('Review stats request timed out');
            },
          );

          print('Raw review statistics response for snack $snackId: $response');

          if (!mounted) return;

          // Handle different response formats
          if (response is Map<String, dynamic>) {
            setState(() {
              _reviewStats[snackId] = ReviewStatistic.fromJson(response);
            });
            print('Processed review stats for snack ${snackId} from Map: ${_reviewStats[snackId]?.reviewCount}, ${_reviewStats[snackId]?.averageRating}');
          } else if (response is List && response.isNotEmpty) {
            setState(() {
              _reviewStats[snackId] = ReviewStatistic.fromJson(response[0]);
            });
            print('Processed review stats for snack ${snackId} from List: ${_reviewStats[snackId]?.reviewCount}, ${_reviewStats[snackId]?.averageRating}');
          } else {
            print('Unexpected response format for snack ${snackId}: $response');
            // Create default stats if response format is unexpected
            setState(() {
              _reviewStats[snackId] = ReviewStatistic(reviewCount: 0, averageRating: 0.0);
            });
          }
        } catch (e) {
          print('Error fetching review stats for snack ${snackId}: $e');
          // Continue with other snacks even if one fails
        }
      }
    } catch (e) {
      print('Error in review statistics batch processing: $e');
    }
  }

  void _showToast(String message) {
    // Create a custom positioned toast near the + button
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100, // Position above the navbar
        right: 20,   // Position from right edge
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF70AE6E),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );

    // Show the toast and remove after 2 seconds
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  void _editReview(Review review, Snack snack) {
    // Create a TextEditingController with the current review text
    final reviewController = TextEditingController(text: review.content);
    double newRating = review.rating.toDouble();

    // Show edit review dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          'Edit Review for ${snack.name}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF70AE6E),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rating stars
            StatefulBuilder(
                builder: (context, setDialogState) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < newRating ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFFD700),
                        ),
                        onPressed: () {
                          setDialogState(() {
                            newRating = index + 1;
                          });
                        },
                      );
                    }),
                  );
                }
            ),
            const SizedBox(height: 15),
            // Review text field
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Your review...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF70AE6E)),
                ),
              ),
              controller: reviewController,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF70AE6E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              // Save updated review
              try {
                final updatedReview = Review(
                  id: review.id,
                  userId: review.userId,
                  snackId: review.snackId,
                  rating: newRating.toDouble(),
                  content: reviewController.text,
                );
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('jwt_token') ?? '';
                await _reviewService.updateReview(updatedReview, token);

                if (mounted) {
                  // Update local state
                  setState(() {
                    final index = _reviews.indexWhere((r) => r.id == review.id);
                    if (index != -1) {
                      _reviews[index] = updatedReview;
                    }
                  });

                  Navigator.pop(context);
                  _showToast('Review updated!');

                  // Refresh review statistics
                  _fetchReviewStatistics();
                }
              } catch (e) {
                Navigator.pop(context);
                _showToast('Failed to update review: ${e.toString()}');
                print('Error updating review: $e');
              }
            },
            child: Text(
              'Simpan',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteReview(Review review, Snack snack) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Hapus Review?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF70AE6E),
            ),
          ),
          content: Text(
            'Apakah anda yakin ingin menghapus review untuk ${snack.name}?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF70AE6E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                try {
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('jwt_token') ?? '';
                  await _reviewService.deleteReview(review.id, token);

                  if (mounted) {
                    setState(() {
                      _reviews.removeWhere((r) => r.id == review.id);
                    });

                    Navigator.pop(context);
                    _showToast('Review berhasil dihapus');

                    // Refresh review statistics
                    _fetchReviewStatistics();
                  }
                } catch (e) {
                  Navigator.pop(context);
                  _showToast('Review berhasil dihapus');
                  // Refresh review page
                  _fetchUserReviews();
                  // Refresh review statistics
                  _fetchReviewStatistics();
                }
              },
              child: Text(
                'Ya, Hapus!',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E9),
              Colors.white,
            ],
            stops: [0.0, 0.3],
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title with animation
                    Row(
                      children: [
                        Image.asset(
                          'images/logo.png',
                          height: 32,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.fastfood_rounded,
                              size: 32,
                              color: Colors.green.shade700,
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'My Review',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF70AE6E),
                          ),
                        ).animate().fadeIn(duration: 600.ms).slideX(
                          begin: -0.1,
                          end: 0,
                          curve: Curves.easeOutQuad,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Subtitle
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.05,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Kelola review yang telah Anda berikan',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

              const SizedBox(height: 16),

              // Review grid
              Expanded(
                child: _isLoading
                    ? _buildLoadingGrid(size)
                    : _hasError
                    ? _buildErrorState(size)
                    : _reviews.isEmpty
                    ? _buildEmptyState(size)
                    : RefreshIndicator(
                  color: const Color(0xFF70AE6E),
                  onRefresh: _fetchUserReviews,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                    child: MasonryGridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 15,
                      itemCount: _reviews.length,
                      itemBuilder: (context, index) {
                        final review = _reviews[index];
                        final snack = _snacks[review.snackId];
                        final stats = _reviewStats[review.snackId];

                        if (snack == null) {
                          // If snack details are not loaded yet, show a loading item
                          return _buildLoadingItem(size, index);
                        }

                        return _buildReviewItem(review, snack, stats, size, index)
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
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const NavBar(),
    );
  }

  Widget _buildErrorState(Size size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ).animate().scale(
            duration: 600.ms,
            curve: Curves.elasticOut,
          ),
          const SizedBox(height: 24),
          Text(
            'Oops! Something went wrong',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4A4A4A),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _fetchUserReviews,
            icon: const Icon(Icons.refresh),
            label: Text(
              'Try Again',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF70AE6E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: const Color(0xFF70AE6E).withOpacity(0.4),
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideY(
            begin: 0.2,
            end: 0,
            delay: 600.ms,
            curve: Curves.easeOutQuad,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Size size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF70AE6E).withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.rate_review,
              size: 64,
              color: Color(0xFF70AE6E),
            ),
          ).animate().scale(
            duration: 600.ms,
            curve: Curves.elasticOut,
          ),
          const SizedBox(height: 24),
          Text(
            'Belum Ada Review',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4A4A4A),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 12),
          // "Tambahkan Review" button has been removed as requested
        ],
      ),
    );
  }

  Widget _buildLoadingGrid(Size size) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        itemCount: 6,
        itemBuilder: (context, i) {
          return _buildShimmerItem(size, i);
        },
      ),
    );
  }

  Widget _buildLoadingItem(Size size, int i) {
    return _buildShimmerItem(size, i);
  }

  Widget _buildShimmerItem(Size size, int i) {
    // Vary the height for visual interest
    final heightFactor = 1.2 + (i % 3) * 0.1;

    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: size.width * 0.5 * heightFactor,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 16,
            width: size.width * 0.3,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 12,
            width: size.width * 0.2,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                height: 24,
                width: size.width * 0.15,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 24,
                width: size.width * 0.15,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Review review, Snack snack, ReviewStatistic? stats, Size size, int index) {
    // Vary the height for visual interest
    final heightFactor = 1.2 + (index % 3) * 0.1;
    final averageRating = stats?.averageRating ?? 0.0;
    final reviewCount = stats?.reviewCount ?? 0;

    return GestureDetector(
      onTap: () => _editReview(review, snack),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Hero(
                    tag: 'review-${snack.id}',
                    child: CachedNetworkImage(
                      imageUrl: snack.imageUrl.isNotEmpty
                          ? AppConfig.baseUrl + snack.imageUrl
                          : 'https://via.placeholder.com/400x300?text=No+Image',
                      placeholder: (context, url) => Container(
                        height: size.width * 0.5 * heightFactor,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF70AE6E)),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: size.width * 0.5 * heightFactor,
                        color: Colors.grey[200],
                        child: const Icon(Icons.error, color: Colors.red),
                      ),
                      fit: BoxFit.cover,
                      height: size.width * 0.5 * heightFactor,
                      width: double.infinity,
                    ),
                  ),
                ),
                // Rating badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF70AE6E),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          averageRating.toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    snack.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Review count
                  Text(
                    '$reviewCount reviews',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),

                  // Review text preview
                  if (review.content.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      review.content,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[800],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'Edit',
                          Icons.edit_outlined,
                          const Color(0xFF70AE6E),
                              () => _editReview(review, snack),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          'Hapus',
                          Icons.delete_outline,
                          Colors.red,
                              () => _deleteReview(review, snack),
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
  }

  Widget _buildActionButton(
      String label,
      IconData icon,
      Color color,
      VoidCallback onPressed,
      ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
