import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'navbar.dart';

class MyReviewPage extends StatefulWidget {
  const MyReviewPage({Key? key}) : super(key: key);

  @override
  State<MyReviewPage> createState() => _MyReviewPageState();
}

class _MyReviewPageState extends State<MyReviewPage> {
  bool _isLoading = true;
  final List<ReviewItem> _reviewItems = reviewItems;

  @override
  void initState() {
    super.initState();
    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
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

  void _editReview(ReviewItem item) {
    // Show edit review dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          'Edit Review for ${item.name}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF70AE6E),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rating stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < item.rating.floor() ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFD700),
                  ),
                  onPressed: () {
                    // Update rating logic would go here
                  },
                );
              }),
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
              controller: TextEditingController(text: item.reviewText),
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
            onPressed: () {
              // Save review logic would go here
              Navigator.pop(context);
              _showToast('Review updated!');
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

  void _deleteReview(ReviewItem item) {
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
            'Apakah anda yakin ingin menghapus review untuk ${item.name}?',
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
              onPressed: () {
                setState(() {
                  _reviewItems.remove(item);
                });
                Navigator.pop(context);
                _showToast('Review berhasil dihapus');
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

  void _addNewReview() {
    _showToast('Tambah Review Baru');
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
                    // Removed the Add button from here
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
                    : _reviewItems.isEmpty
                    ? _buildEmptyState(size)
                    : RefreshIndicator(
                  color: const Color(0xFF70AE6E),
                  onRefresh: () async {
                    setState(() {
                      _isLoading = true;
                    });
                    await Future.delayed(const Duration(seconds: 1));
                    setState(() {
                      _isLoading = false;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                    child: MasonryGridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 15,
                      itemCount: _reviewItems.length,
                      itemBuilder: (context, index) {
                        return _buildReviewItem(index, size)
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
      // Removed the floating action button from here
      bottomNavigationBar: const NavBar(),
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
          Text(
            'Anda belum memberikan review apapun.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _addNewReview,
            icon: const Icon(Icons.add),
            label: Text(
              'Tambah Review Sekarang',
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

  Widget _buildReviewItem(int index, Size size) {
    final item = _reviewItems[index];
    // Vary the height for visual interest
    final heightFactor = 1.2 + (index % 3) * 0.1;

    return GestureDetector(
      onTap: () => _editReview(item),
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
                    tag: 'review-${item.name}',
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl,
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
                          item.rating.toString(),
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
                    item.name,
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
                    '${item.reviewCount} reviews',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),

                  // Review text preview
                  if (item.reviewText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.reviewText,
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
                              () => _editReview(item),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          'Hapus',
                          Icons.delete_outline,
                          Colors.red,
                              () => _deleteReview(item),
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

// Model class for review items
class ReviewItem {
  final String name;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final String reviewText;

  ReviewItem({
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    this.reviewText = '',
  });
}

// Sample data with actual image URLs
final List<ReviewItem> reviewItems = [
  ReviewItem(
    name: 'Corn dog',
    imageUrl: 'https://images.unsplash.com/photo-1619881590738-a111d176d906?q=80&w=400',
    rating: 4.8,
    reviewCount: 30,
    reviewText: 'Crispy outside, juicy inside. Perfect snack!',
  ),
  ReviewItem(
    name: 'Mochi Daifuku',
    imageUrl: 'https://images.unsplash.com/photo-1631206753348-db44968fd440?q=80&w=400',
    rating: 4.9,
    reviewCount: 25,
    reviewText: 'Soft and chewy with delicious filling.',
  ),
  ReviewItem(
    name: 'Boba',
    imageUrl: 'https://images.unsplash.com/photo-1558857563-b371033873b8?q=80&w=400',
    rating: 4.6,
    reviewCount: 20,
    reviewText: 'Perfect sweetness and chewy pearls!',
  ),
  ReviewItem(
    name: 'Toppokki',
    imageUrl: 'https://images.unsplash.com/photo-1635363638580-c2809d049eee?q=80&w=400',
    rating: 4.7,
    reviewCount: 32,
    reviewText: 'Spicy and satisfying. Great sauce!',
  ),
  ReviewItem(
    name: 'Ice Jeruk',
    imageUrl: 'https://images.unsplash.com/photo-1560526860-1f0e56046c85?q=80&w=400',
    rating: 4.5,
    reviewCount: 18,
    reviewText: 'Refreshing citrus flavor, perfect for hot days.',
  ),
  ReviewItem(
    name: 'Mango Rice',
    imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=400',
    rating: 4.8,
    reviewCount: 25,
    reviewText: 'Sweet mango pairs perfectly with the rice.',
  ),
];
