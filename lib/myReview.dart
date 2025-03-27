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

  void _editReview(ReviewItem item) {
    // Show edit review dialog or navigate to edit review page
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
            color: const Color(0xFF4CAF50),
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
                  borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                ),
              ),
              controller: TextEditingController(text: 'Great food! Would recommend.'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              // Save review logic would go here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Review updated!'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
            child: Text(
              'Save',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
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
                      'My Review',
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

              // Review grid
              Expanded(
                child: _isLoading
                    ? _buildLoadingGrid(size)
                    : RefreshIndicator(
                  color: const Color(0xFF4CAF50),
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
                      crossAxisCount: 3,
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 12,
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
      bottomNavigationBar: const NavBar(), // Assuming 3 is for My Review
    );
  }

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

  Widget _buildReviewItem(int index, Size size) {
    final item = _reviewItems[index];
    // Vary the height slightly for visual interest
    final heightFactor = 0.25 + (index % 3) * 0.05;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Food image with edit review button
        GestureDetector(
          onTap: () => _editReview(item),
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
              child: Stack(
                children: [
                  // Image
                  CachedNetworkImage(
                    imageUrl: item.imageUrl,
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
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  // Edit Review Button
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Edit Review',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Food name
        Text(
          item.name,
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
              '${item.rating} (${item.reviewCount})',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
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

  ReviewItem copyWith({
    String? name,
    String? imageUrl,
    double? rating,
    int? reviewCount,
    String? reviewText,
  }) {
    return ReviewItem(
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      reviewText: reviewText ?? this.reviewText,
    );
  }
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
  ReviewItem(
    name: 'Siomay',
    imageUrl: 'https://images.unsplash.com/photo-1496116218417-1a781b1c416c?q=80&w=400',
    rating: 4.6,
    reviewCount: 40,
    reviewText: 'Delicious dumplings with perfect dipping sauce.',
  ),
  ReviewItem(
    name: 'Ice Tea',
    imageUrl: 'https://images.unsplash.com/photo-1556679343-c1c1c9308e4e?q=80&w=400',
    rating: 4.5,
    reviewCount: 21,
    reviewText: 'Perfectly brewed and not too sweet.',
  ),
  ReviewItem(
    name: 'Matcha Strawberry',
    imageUrl: 'https://images.unsplash.com/photo-1558160074-4d7d8bdf4256?q=80&w=400',
    rating: 4.7,
    reviewCount: 19,
    reviewText: 'Unique flavor combination that works surprisingly well!',
  ),
];