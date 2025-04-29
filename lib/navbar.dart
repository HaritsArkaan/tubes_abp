import 'package:flutter/material.dart';
import 'dart:math' as math;

class NavBar extends StatefulWidget {
  const NavBar({
    Key? key,
  }) : super(key: key);

  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _bounceController;
  late AnimationController _rippleController;
  late AnimationController _rotationController;
  late AnimationController _slideController;

  late Animation<double> _bounceAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _slideAnimation;

  // For glow effect
  final List<Color> _glowColors = [
    const Color(0xFF8BC34A),
    const Color(0xFF9CCC65),
    const Color(0xFFAED581),
    const Color(0xFFC5E1A5),
    const Color(0xFFDCEDC8),
  ];

  // Define routes for each navigation item - removed the Add tab
  final List<String> _routes = [
    '/dashboard',
    '/jajananku',
    '/favorite',
    '/myReview',
  ];

  @override
  void initState() {
    super.initState();

    // Determine the current route and set the selected index accordingly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSelectedIndexBasedOnRoute();
    });

    // Bounce animation for icon
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.1), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));

    // Ripple animation for background effect
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _rippleAnimation = CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOutQuart,
    );

    // Rotation animation for special effects
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _rotationAnimation = CurvedAnimation(
      parent: _rotationController,
      curve: Curves.elasticOut,
    );

    // Slide animation for indicator
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    );

    _slideController.forward();
  }

  void _updateSelectedIndexBasedOnRoute() {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    // Check if we're on a specific page and update the selected index
    if (currentRoute.contains('jajananku')) {
      setState(() {
        _selectedIndex = 1; // Jajananku is now index 1 (after removing Add)
      });
    } else if (currentRoute.contains('favorite')) {
      setState(() {
        _selectedIndex = 2; // Favorite is now index 2
      });
    } else if (currentRoute.contains('myReview')) {
      setState(() {
        _selectedIndex = 3; // Review is now index 3
      });
    } else {
      // Default to home/dashboard
      setState(() {
        _selectedIndex = 0; // Home index
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update selected index when dependencies change (like route changes)
    _updateSelectedIndexBasedOnRoute();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _rippleController.dispose();
    _rotationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });

      // Reset and play animations
      _bounceController.reset();
      _bounceController.forward();

      _rippleController.reset();
      _rippleController.forward();

      _slideController.reset();
      _slideController.forward();

      if (index == 1) { // Jajananku index is now 1
        _rotationController.reset();
        _rotationController.forward();
      }

      // Navigate to the corresponding route
      _navigateToRoute(index);
    } else if (index == 1) { // Jajananku index is now 1
      _rotationController.reset();
      _rotationController.forward();

      _bounceController.reset();
      _bounceController.forward();
    }
  }

  // Navigate to the route corresponding to the selected index
  void _navigateToRoute(int index) {
    // Get the current context
    final BuildContext ctx = context;

    // Navigate to the route using pushReplacementNamed to replace the current route
    // This ensures we don't build up the navigation stack
    Navigator.of(ctx).pushReplacementNamed(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / 4; // 4 items now (removed Add)

    return Container(
      height: 70 + bottomPadding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF689F38),
            Color(0xFF8BC34A),
            Color(0xFF7CB342),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8BC34A).withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: bottomPadding),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Animated glow effect for selected item
            AnimatedBuilder(
              animation: _rippleAnimation,
              builder: (context, child) {
                return Positioned(
                  left: _selectedIndex * itemWidth + (itemWidth / 2 - 35),
                  top: 5,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: _glowColors.map((color) => color.withOpacity(
                            _rippleAnimation.value * (1 - _rippleAnimation.value) * 4
                        )).toList(),
                        stops: const [0.2, 0.4, 0.6, 0.8, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Animated indicator line
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              top: 0,
              left: _selectedIndex * itemWidth + (itemWidth / 2 - 25),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 50,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),

            // Nav items - removed the Add item
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                _buildJajananItem(1, Icons.restaurant_menu_outlined, Icons.restaurant_menu, 'Jajananku'),
                _buildNavItem(2, Icons.favorite_border_rounded, Icons.favorite, 'Favorite'),
                _buildNavItem(3, Icons.photo_library_outlined, Icons.photo_library, 'Review'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 4, // 4 items now
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey<bool>(isSelected),
                color: Colors.white,
                size: isSelected ? 26 : 22,
              ),
            ),
            const SizedBox(height: 5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                letterSpacing: isSelected ? 0.5 : 0,
                shadows: isSelected ? [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ] : [],
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            if (isSelected)
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.6),
                          blurRadius: 4,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              const SizedBox(height: 11), // Maintain consistent height
          ],
        ),
      ),
    );
  }

  Widget _buildJajananItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 4, // 4 items now
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: isSelected ? _bounceAnimation.value : 1.0,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isSelected)
                          ...List.generate(4, (i) {
                            return AnimatedBuilder(
                              animation: _rippleAnimation,
                              builder: (context, child) {
                                final double rotation = (i * math.pi / 2) + (_rippleAnimation.value * math.pi);
                                final double distance = 12 * _rippleAnimation.value * (1 - _rippleAnimation.value) * 4;

                                return Transform.translate(
                                  offset: Offset(
                                    math.cos(rotation) * distance,
                                    math.sin(rotation) * distance,
                                  ),
                                  child: Opacity(
                                    opacity: (1 - _rippleAnimation.value) * 0.5,
                                    child: Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        Icon(
                          isSelected ? activeIcon : icon,
                          key: ValueKey<bool>(isSelected),
                          color: Colors.white,
                          size: isSelected ? 26 : 22,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                letterSpacing: isSelected ? 0.5 : 0,
                shadows: isSelected ? [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ] : [],
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            if (isSelected)
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.6),
                          blurRadius: 4,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              const SizedBox(height: 11), // Maintain consistent height
          ],
        ),
      ),
    );
  }
}
