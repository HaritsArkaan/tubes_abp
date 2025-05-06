import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navbar.dart';
import 'editJajanan.dart';
import 'models/snack.dart';
import 'models/reviewStatistic.dart';
import 'services/api_snack.dart';
import 'services/api_review.dart';
import 'config.dart';

class JajananKu extends StatefulWidget {
  const JajananKu({Key? key}) : super(key: key);

  @override
  State<JajananKu> createState() => _JajananKuState();
}

class _JajananKuState extends State<JajananKu> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  List<Snack> _snacks = [];
  Map<int, ReviewStatistic> _reviewStats = {};
  OverlayEntry? _overlayEntry;
  late AnimationController _buttonAnimationController;
  bool _isButtonHovered = false;

  // API services
  final ApiService _apiService = ApiService();
  final ApiReview _apiReview = ApiReview();

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for the add button
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Load data from API
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = '';
    });

    try {
      // Get token and user ID from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final token = await prefs.getString('jwt_token');
      final userId = await prefs.getInt('user_id');

      if (token == null || userId == null) {
        throw Exception('User not authenticated');
      }

      // Fetch snacks by user ID
      final snacks = await _apiService.getSnacksByUserId(userId, token);

      // Fetch review statistics for each snack
      final Map<int, ReviewStatistic> reviewStats = {};
      for (var snack in snacks) {
        try {
          final statsData = await _apiReview.getReviewStatistics(snack.id);
          if (statsData != null) {
            reviewStats[snack.id] = ReviewStatistic.fromJson(statsData);
          }
        } catch (e) {
          print('Error fetching review stats for snack ${snack.id}: $e');
          // Continue with next snack even if this one fails
        }
      }

      // Update state with fetched data
      if (mounted) {
        setState(() {
          _snacks = snacks;
          _reviewStats = reviewStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = 'Failed to load data: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    // Make sure to remove any active overlay when disposing
    _removeOverlay();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  // Remove any existing overlay
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // Show a custom toast message near the FAB
  void _showToast(String message) {
    // Remove any existing overlay first
    _removeOverlay();

    // Create a new overlay entry
    _overlayEntry = OverlayEntry(
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _removeOverlay,
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Insert the overlay
    Overlay.of(context).insert(_overlayEntry!);

    // Auto-remove after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (_overlayEntry != null) {
        _removeOverlay();
      }
    });
  }

  Future<void> _editSnack(Snack snack) async {
    final result = await showDialog<Snack>(
      context: context,
      builder: (BuildContext context) {
        return EditSnackDialog(
          snack: snack,
          onSave: (updatedSnack) async {
            try {
              // Get token from shared preferences
              final prefs = await SharedPreferences.getInstance();
              final token = await prefs.getString('token');

              if (token == null) {
                throw Exception('User not authenticated');
              }

              // Update snack via API
              final updatedSnackFromApi = await _apiService.updateSnack(updatedSnack, token);
              return updatedSnackFromApi;
            } catch (e) {
              _showToast('Failed to update: ${e.toString()}');
              return null;
            }
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        // Find the index of the item to update
        final index = _snacks.indexWhere((s) => s.id == result.id);
        if (index != -1) {
          // Replace the old item with the updated one
          _snacks[index] = result;
        }
      });
      _showToast('${result.name} berhasil diperbarui');

      // Refresh review statistics for this snack
      try {
        final statsData = await _apiReview.getReviewStatistics(result.id);
        if (statsData != null && mounted) {
          setState(() {
            _reviewStats[result.id] = ReviewStatistic.fromJson(statsData);
          });
        }
      } catch (e) {
        print('Error refreshing review stats: $e');
      }
    }
  }

  Future<void> _deleteSnack(Snack snack) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Hapus Jajanan?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF70AE6E),
            ),
          ),
          content: Text(
            'Apakah anda yakin ingin menghapus ${snack.name}?',
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF70AE6E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Ya, Hapus!',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // Get token from shared preferences
        final prefs = await SharedPreferences.getInstance();
        final token = await prefs.getString('jwt_token');

        if (token == null) {
          throw Exception('User not authenticated');
        }

        // Delete snack via API
        await _apiService.deleteSnack(snack.id, token);

        // Update state
        setState(() {
          _snacks.remove(snack);
          _reviewStats.remove(snack.id);
        });

        _showToast('${snack.name} berhasil dihapus');
      } catch (e) {
        _showToast('Failed to delete: ${e.toString()}');
      }
    }
  }

  void _viewSnackDetail(Snack snack) {
    // Navigate to detail page
    Navigator.of(context).pushNamed('/detailJajanan', arguments: snack);
  }

  void _addNewSnack() {
    // Navigate to the tambahJajanan route
    Navigator.of(context).pushNamed('/tambahJajanan');
  }

  void _navigateToLogin() {
    // Navigate to login page
    Navigator.of(context).pushReplacementNamed('/login');
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
                            // Fallback if image can't be loaded
                            return Container(
                              height: 32,
                              width: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF70AE6E).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.restaurant,
                                color: Color(0xFF70AE6E),
                                size: 20,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Jajananku',
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

              // Add Button - Redesigned with icon and text
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.05,
                  vertical: size.height * 0.01,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Subtitle text moved to be inline with button
                    Expanded(
                      child: Text(
                        'Kelola jajanan yang telah Anda tambahkan',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),

                    // New elegant compact button
                    MouseRegion(
                      onEnter: (_) => setState(() => _isButtonHovered = true),
                      onExit: (_) => setState(() => _isButtonHovered = false),
                      child: GestureDetector(
                        onTap: _addNewSnack,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isButtonHovered ? const Color(0xFF8BC34A) : const Color(0xFF70AE6E),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF70AE6E).withOpacity(_isButtonHovered ? 0.3 : 0.1),
                                blurRadius: _isButtonHovered ? 8 : 4,
                                spreadRadius: _isButtonHovered ? 1 : 0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 24,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 600.ms),

              const SizedBox(height: 16),

              // Snack grid
              Expanded(
                child: _isLoading
                    ? _buildLoadingGrid(size)
                    : _isError
                    ? _buildErrorState(size)
                    : _snacks.isEmpty
                    ? _buildEmptyState(size)
                    : RefreshIndicator(
                  color: const Color(0xFF70AE6E),
                  onRefresh: _loadData,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                    child: MasonryGridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 15,
                      itemCount: _snacks.length,
                      itemBuilder: (context, index) {
                        return _buildSnackItem(index, size)
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
      // No floating action button as requested
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
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red[400],
            ),
          ),
          const SizedBox(height: 8),
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
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: Text(
              'Try Again',
              style: GoogleFonts.poppins(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF70AE6E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_errorMessage.contains('User not authenticated'))
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton.icon(
                onPressed: _navigateToLogin,
                icon: const Icon(Icons.login),
                label: Text(
                  'Go to Login',
                  style: GoogleFonts.poppins(),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF70AE6E),
                ),
              ),
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
              Icons.restaurant,
              size: 64,
              color: Color(0xFF70AE6E),
            ),
          ).animate().scale(
            duration: 600.ms,
            curve: Curves.elasticOut,
          ),
          const SizedBox(height: 24),
          Text(
            'Belum Ada Jajanan',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4A4A4A),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 12),
          Text(
            'Anda belum menambahkan jajanan',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/tambahJajanan');
            },
            icon: const Icon(Icons.add),
            label: Text(
              'Tambah Jajanan Sekarang',
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

  Widget _buildSnackItem(int index, Size size) {
    final snack = _snacks[index];
    // Get review statistics for this snack, or use default values if not available
    final reviewStat = _reviewStats[snack.id] ??
        ReviewStatistic(reviewCount: 0, averageRating: 0.0);

    // Vary the height for visual interest
    final heightFactor = 1.2 + (index % 3) * 0.1;

    return GestureDetector(
      onTap: () => _viewSnackDetail(snack),
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
                    tag: 'snack-${snack.id}',
                    child: CachedNetworkImage(
                      imageUrl: '${AppConfig.baseUrl}${snack.imageUrl}',
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
                // Price tag
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      'Rp ${snack.price.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF70AE6E),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Type badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getTypeColor(snack.type),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      snack.type,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                // Seller badge
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      snack.seller,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
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

                  // Rating with review count from API
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFFD700),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${reviewStat.averageRating.toStringAsFixed(1)} (${reviewStat.reviewCount})',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          snack.location,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Contact
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          snack.contact,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'Edit',
                          Icons.edit_outlined,
                          const Color(0xFF70AE6E),
                              () => _editSnack(snack),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          'Hapus',
                          Icons.delete_outline,
                          Colors.red,
                              () => _deleteSnack(snack),
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

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Food':
        return const Color(0xFF5C6BC0); // Indigo
      case 'Drink':
        return const Color(0xFF26A69A); // Teal
      case 'Dessert':
        return const Color(0xFFEC407A); // Pink
      case 'Snack':
        return const Color(0xFFFF7043); // Deep Orange
      default:
        return const Color(0xFF70AE6E); // Default green
    }
  }
}
