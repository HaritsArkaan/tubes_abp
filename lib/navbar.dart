import 'package:flutter/material.dart';
import 'dart:math' as math;

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
    final double navbarHeight = math.max(65.0, 65.0 + (bottomPadding > 0 ? bottomPadding - 10.0 : 0.0));

    return Container(
      height: navbarHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        // Lighter green color
        color: const Color(0xFF8BC34A),
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
                size: Size(screenWidth.toDouble(), navbarHeight.toDouble()),
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
                      fontSize: isSelected ? (fontSize + 1.0) : fontSize.toDouble(),
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