import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'navbar.dart'; // Import your navbar

// Model class for snack items
class SnackItem {
  final String id;
  final String name;
  final String imageUrl;
  final String price;
  final String type;
  final String location;
  final double rating;
  final int reviewCount;

  SnackItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.type,
    required this.location,
    required this.rating,
    required this.reviewCount,
  });
}

// Sample data with actual image URLs
final List<SnackItem> snackItems = [
  SnackItem(
    id: '1',
    name: 'Risoles Mayo',
    imageUrl: 'https://images.unsplash.com/photo-1558745010-d2a3c21762ab?q=80&w=400',
    price: '5.000',
    type: 'Snack',
    location: 'Jl. Kebon Jeruk No. 10',
    rating: 4.5,
    reviewCount: 24,
  ),
  SnackItem(
    id: '2',
    name: 'Boba Milk Tea',
    imageUrl: 'https://images.unsplash.com/photo-1558857563-b371033873b8?q=80&w=400',
    price: '15.000',
    type: 'Drink',
    location: 'Jl. Sudirman No. 45',
    rating: 4.8,
    reviewCount: 36,
  ),
  SnackItem(
    id: '3',
    name: 'Mochi Ice Cream',
    imageUrl: 'https://images.unsplash.com/photo-1631206753348-db44968fd440?q=80&w=400',
    price: '10.000',
    type: 'Dessert',
    location: 'Jl. Gatot Subroto No. 22',
    rating: 4.2,
    reviewCount: 18,
  ),
  SnackItem(
    id: '4',
    name: 'Corn Dog',
    imageUrl: 'https://images.unsplash.com/photo-1619881590738-a111d176d906?q=80&w=400',
    price: '12.000',
    type: 'Food',
    location: 'Jl. Thamrin No. 33',
    rating: 4.6,
    reviewCount: 42,
  ),
  SnackItem(
    id: '5',
    name: 'Toppokki',
    imageUrl: 'https://images.unsplash.com/photo-1635363638580-c2809d049eee?q=80&w=400',
    price: '18.000',
    type: 'Food',
    location: 'Jl. Asia Afrika No. 15',
    rating: 4.7,
    reviewCount: 32,
  ),
  SnackItem(
    id: '6',
    name: 'Ice Jeruk',
    imageUrl: 'https://images.unsplash.com/photo-1560526860-1f0e56046c85?q=80&w=400',
    price: '8.000',
    type: 'Drink',
    location: 'Jl. Cihampelas No. 50',
    rating: 4.5,
    reviewCount: 18,
  ),
];

class JajananKu extends StatefulWidget {
  const JajananKu({Key? key}) : super(key: key);

  @override
  State<JajananKu> createState() => _JajananKuState();
}

class _JajananKuState extends State<JajananKu> {
  bool _isLoading = true;
  final List<SnackItem> _snackItems = snackItems;
  OverlayEntry? _overlayEntry;

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

  @override
  void dispose() {
    // Make sure to remove any active overlay when disposing
    _removeOverlay();
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

  void _editSnack(SnackItem item) {
    // Mock navigation
    _showToast('Edit: ${item.name}');
  }

  void _deleteSnack(SnackItem item) {
    showDialog(
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
            'Apakah anda yakin ingin menghapus ${item.name}?',
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
                  _snackItems.remove(item);
                });
                Navigator.pop(context);
                _showToast('${item.name} berhasil dihapus');
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

  void _viewSnackDetail(SnackItem item) {
    // Mock navigation
    _showToast('Detail: ${item.name}');
  }

  void _addNewSnack() {
    // Mock navigation
    _showToast('Tambah Jajanan Baru');
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
                    // Add button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                          Icons.add_circle_outline,
                          color: Color(0xFF70AE6E),
                          size: 24,
                        ),
                        onPressed: _addNewSnack,
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideX(
                      begin: 0.1,
                      end: 0,
                      curve: Curves.easeOutQuad,
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
                    'Kelola jajanan yang telah Anda tambahkan',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

              const SizedBox(height: 16),

              // Snack grid
              Expanded(
                child: _isLoading
                    ? _buildLoadingGrid(size)
                    : _snackItems.isEmpty
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
                      itemCount: _snackItems.length,
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
      floatingActionButton: _isLoading || _snackItems.isEmpty
          ? null
          : FloatingActionButton(
        onPressed: _addNewSnack,
        backgroundColor: const Color(0xFF70AE6E),
        child: const Icon(Icons.add),
      ).animate().scale(
        delay: 500.ms,
        duration: 400.ms,
        curve: Curves.elasticOut,
      ),
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
            'Anda belum menambahkan jajanan apapun.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _addNewSnack,
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
    final item = _snackItems[index];
    // Vary the height for visual interest
    final heightFactor = 1.2 + (index % 3) * 0.1;

    return GestureDetector(
      onTap: () => _viewSnackDetail(item),
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
                    tag: 'snack-${item.id}',
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
                      'Rp ${item.price}',
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
                      color: _getTypeColor(item.type),
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
                      item.type,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
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
                    item.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
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
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.rating} (${item.reviewCount})',
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
                          item.location,
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
                              () => _editSnack(item),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          'Hapus',
                          Icons.delete_outline,
                          Colors.red,
                              () => _deleteSnack(item),
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