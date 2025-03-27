import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:like_button/like_button.dart';
import 'navbar.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({Key? key}) : super(key: key);

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  bool _isLoading = true;
  final List<FoodItem> _foodItems = foodItems;

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

  void _toggleFavorite(int index) {
    setState(() {
      _foodItems[index] = _foodItems[index].copyWith(
        isFavorite: !_foodItems[index].isFavorite,
      );
    });
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

              // Food grid
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
                      itemCount: _foodItems.length,
                      itemBuilder: (context, index) {
                        return _buildFoodItem(index, size)
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
      // Fix: Check what parameters your NavBar accepts and use those instead
      bottomNavigationBar: const NavBar(), // Changed from currentIndex to selectedIndex
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
        itemBuilder: (context, i) { // Changed from index to i to avoid conflict
          return _buildShimmerItem(size, i); // Pass i to the method
        },
      ),
    );
  }

  Widget _buildShimmerItem(Size size, int i) { // Added parameter i
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: size.width * (0.25 + (i % 3) * 0.05), // Use i instead of index
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

  Widget _buildFoodItem(int index, Size size) {
    final item = _foodItems[index];
    // Vary the height slightly for visual interest
    final heightFactor = 0.25 + (index % 3) * 0.05;

    return GestureDetector(
      onTap: () {
        // Navigate to detail page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} details'),
            duration: const Duration(seconds: 1),
            backgroundColor: const Color(0xFF4CAF50),
          ),
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
                tag: 'food_${item.name}',
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
                  isLiked: item.isFavorite,
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
                    _toggleFavorite(index);
                    return !isLiked;
                  },
                ),
              ),
            ],
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
      ),
    );
  }
}

// Enhanced model class for food items
class FoodItem {
  final String name;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final bool isFavorite;

  FoodItem({
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    this.isFavorite = true,
  });

  FoodItem copyWith({
    String? name,
    String? imageUrl,
    double? rating,
    int? reviewCount,
    bool? isFavorite,
  }) {
    return FoodItem(
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

// Sample data with actual image URLs
final List<FoodItem> foodItems = [
  FoodItem(
    name: 'Corn dog',
    imageUrl: 'https://images.unsplash.com/photo-1619881590738-a111d176d906?q=80&w=400',
    rating: 4.8,
    reviewCount: 30,
  ),
  FoodItem(
    name: 'Mochi Daifuku',
    imageUrl: 'https://images.unsplash.com/photo-1631206753348-db44968fd440?q=80&w=400',
    rating: 4.9,
    reviewCount: 25,
  ),
  FoodItem(
    name: 'Boba',
    imageUrl: 'https://images.unsplash.com/photo-1558857563-b371033873b8?q=80&w=400',
    rating: 4.6,
    reviewCount: 20,
  ),
  FoodItem(
    name: 'Wonton',
    imageUrl: 'https://images.unsplash.com/photo-1625398407796-82650a8c9dd4?q=80&w=400',
    rating: 4.5,
    reviewCount: 30,
  ),
  FoodItem(
    name: 'Ice Strawberry',
    imageUrl: 'https://images.unsplash.com/photo-1501443762994-82bd5dace89a?q=80&w=400',
    rating: 4.9,
    reviewCount: 25,
  ),
  FoodItem(
    name: 'Curry Katsu',
    imageUrl: 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?q=80&w=400',
    rating: 4.8,
    reviewCount: 25,
  ),
  FoodItem(
    name: 'Nasi Goreng',
    imageUrl: 'https://images.unsplash.com/photo-1632778149955-e80f8ceca2e8?q=80&w=400',
    rating: 4.7,
    reviewCount: 35,
  ),
  FoodItem(
    name: 'Cappuccino',
    imageUrl: 'https://images.unsplash.com/photo-1534778101976-62847782c213?q=80&w=400',
    rating: 4.8,
    reviewCount: 40,
  ),
  FoodItem(
    name: 'Gyoza',
    imageUrl: 'https://images.unsplash.com/photo-1625938145744-e380515399b7?q=80&w=400',
    rating: 4.7,
    reviewCount: 25,
  ),
];