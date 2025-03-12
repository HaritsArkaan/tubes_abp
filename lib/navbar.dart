import 'package:flutter/material.dart';
import 'dart:math' as math;

class AdvancedNavBar extends StatefulWidget {
  const AdvancedNavBar({Key? key}) : super(key: key);

  @override
  _AdvancedNavBarState createState() => _AdvancedNavBarState();
}

class _AdvancedNavBarState extends State<AdvancedNavBar> with TickerProviderStateMixin {
  int _selectedIndex = 0;

  // Animation controllers
  late AnimationController _bounceController;
  late AnimationController _rotationController;

  // Animations
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: math.pi / 12).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _selectItem(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });

      _bounceController.reset();
      _bounceController.forward();

      if (index == 1) {
        _rotationController.reset();
        _rotationController.forward();
      }
    } else if (index == 1) {
      _rotationController.reset();
      _rotationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFD1E7D1),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Nav items row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.add_circle_outline, Icons.add_circle, 'Add new'),
              _buildNavItem(2, Icons.favorite_border_rounded, Icons.favorite_rounded, 'Favorite'),
              _buildNavItem(3, Icons.menu_rounded, Icons.menu_rounded, 'My Review'),
            ],
          ),

          // Add Button
          if (_selectedIndex == 1)
            Positioned(
              top: -22,
              child: AnimatedBuilder(
                animation: Listenable.merge([_bounceAnimation, _rotationAnimation]),
                builder: (context, child) {
                  final scale = 1.0 + (_bounceAnimation.value * 0.1);
                  return Transform.scale(
                    scale: scale,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: GestureDetector(
                        onTap: () {
                          _rotationController.reset();
                          _rotationController.forward();
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade600,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _selectItem(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
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
                child: Icon(
                  isSelected ? filledIcon : outlineIcon,
                  key: ValueKey<bool>(isSelected),
                  color: isSelected ? Colors.green.shade600 : Colors.grey.shade700,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.green.shade600 : Colors.grey.shade700,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

