import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'navbar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ScrollController _scrollController;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _isScrolled = _scrollController.offset > 20;
        });
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSearchBar(context),
                          _buildHighlightMenu(context),
                          _buildCategories(context),
                          _buildPopularPicks(context),
                          const SizedBox(height: 100), // Space for bottom nav
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

  Widget _buildHeader(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
                      // Profile image with animated border
                      Container(
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
                          borderRadius: BorderRadius.circular(size.width * 0.05),
                          child: Image.asset(
                            'images/profile.jpg',
                            fit: BoxFit.cover,
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
                            const Text(
                              'Hello, Emily!',
                              style: TextStyle(
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

                      // Notification button with ripple effect
                      GestureDetector(
                        onTap: () {
                          // Add notification functionality
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              const Icon(
                                Icons.notifications_none_rounded,
                                color: Color(0xFF2E3E5C),
                                size: 20,
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.02,
      ),
      child: Row(
        children: [
          // Search field with animation
          Expanded(
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
                        decoration: InputDecoration(
                          hintText: "What's your taste craving today?",
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: size.width * 0.03),

          // Filter button with animation
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  (1 - _animationController.value) * 30,
                  0,
                ),
                child: Opacity(
                  opacity: _animationController.value,
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              onTap: () {
                // Add filter functionality
              },
              child: Container(
                height: size.height * 0.055,
                width: size.height * 0.055,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightMenu(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
        width: size.width,
        height: size.width * 0.5,
        margin: EdgeInsets.symmetric(
          horizontal: size.width * 0.04,
          vertical: size.height * 0.01,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Image with parallax effect
              Positioned.fill(
                child: Hero(
                  tag: 'risoles_hero',
                  child: Image.asset(
                    'images/risoles.jpg',
                    fit: BoxFit.cover,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Risoles Mozzarella',
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
                      children: [
                        Text(
                          'Risoles',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: size.width * 0.04,
                          ),
                        ),
                        SizedBox(width: size.width * 0.02),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
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
                                '4.8',
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

  Widget _buildCategoryItem(BuildContext context, String title, Color color) {
    final size = MediaQuery.of(context).size;
    final itemSize = size.width * 0.15;

    return GestureDetector(
      onTap: () {
        // Navigate to category
      },
      child: Column(
        children: [
          Container(
            width: itemSize,
            height: itemSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'images/${title.toLowerCase()}.png',
                width: itemSize * 0.6,
                height: itemSize * 0.6,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: size.height * 0.01),
          Text(
            title,
            style: TextStyle(
              fontSize: size.width * 0.035,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2E3E5C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularPicks(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
                  'Popular picks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E3E5C),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // View all popular picks
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
          SizedBox(
            height: size.width * 0.55,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
              children: [
                _buildPopularItem(
                  context,
                  'Corn dog',
                  '4.5',
                  '\$5.00',
                  'images/corndog.jpg',
                ),
                SizedBox(width: size.width * 0.04),
                _buildPopularItem(
                  context,
                  'Mochi Daifuku',
                  '4.8',
                  '\$6.50',
                  'images/mochi.jpg',
                ),
                SizedBox(width: size.width * 0.04),
                _buildPopularItem(
                  context,
                  'Boba',
                  '4.7',
                  '\$4.00',
                  'images/boba.jpg',
                ),
                SizedBox(width: size.width * 0.04),
                _buildPopularItem(
                  context,
                  'Takoyaki',
                  '4.6',
                  '\$7.50',
                  'images/corndog.jpg', // Replace with takoyaki image
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularItem(BuildContext context, String name, String rating, String price, String image) {
    final size = MediaQuery.of(context).size;
    final itemWidth = size.width * 0.4;

    return GestureDetector(
      onTap: () {
        // Navigate to food detail
      },
      child: Container(
        width: itemWidth,
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
            Stack(
              children: [
                // Food image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.asset(
                    image,
                    height: itemWidth * 0.75,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                // Favorite button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      // Toggle favorite
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

                // Discount tag
                if (name == 'Corn dog')
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '15% OFF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E3E5C),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E3E5C),
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
}

