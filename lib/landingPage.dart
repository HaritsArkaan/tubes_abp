import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;

class LandingPage extends StatefulWidget {
  final VoidCallback? onComplete;

  const LandingPage({Key? key, this.onComplete}) : super(key: key);

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _mainController;
  late AnimationController _backgroundController;
  late AnimationController _foodItemsController;
  late AnimationController _secondPhaseController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _floatingIconsController;

  // Animations
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotateAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _secondPhaseOpacityAnimation;

  // Phase tracking
  bool _showSecondPhase = false;
  bool _showSkipButton = false;

  // Second phase animations
  bool _showTitle = false;
  bool _showDescription = false;
  bool _showLoginButton = false;
  bool _showSignUpButton = false;
  bool _showGuestButton = false;

  // Food items for floating animation
  final List<FoodItem> _foodItems = [];
  final int _foodItemCount = 60; // Significantly increased count
  final math.Random _random = math.Random();

  // Food particles for background
  final List<FoodParticle> _foodParticles = [];
  final int _particleCount = 50;

  // Floating food icons
  final List<FloatingFoodIcon> _floatingIcons = [];
  final int _floatingIconCount = 20; // Added more floating icons

  // Timer for auto-transition
  Timer? _transitionTimer;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 8000),
      vsync: this,
    );

    _foodItemsController = AnimationController(
      duration: const Duration(milliseconds: 15000),
      vsync: this,
    );

    _secondPhaseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 12000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _floatingIconsController = AnimationController(
      duration: const Duration(milliseconds: 20000),
      vsync: this,
    );

    // Setup animations
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _logoRotateAnimation = Tween<double>(
      begin: -0.2,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    ));

    _textSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
    ));

    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
    ));

    _secondPhaseOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_secondPhaseController);

    // Generate food items, particles, and floating icons
    _generateFoodItems();
    _generateFoodParticles();
    _generateFloatingIcons();

    // Start animations
    _mainController.forward();
    _backgroundController.repeat();
    _foodItemsController.repeat();
    _particleController.repeat();
    _pulseController.repeat(reverse: true);
    _floatingIconsController.repeat();

    // Show skip button after a short delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _showSkipButton = true;
        });
      }
    });

    // Set timer for auto-transition to second phase after 10 seconds
    _transitionTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        _transitionToSecondPhase();
      }
    });

    // Listen to second phase controller for staggered animations
    _secondPhaseController.addListener(() {
      if (_secondPhaseController.value > 0.3 && !_showTitle && mounted) {
        setState(() {
          _showTitle = true;
        });
      }
      if (_secondPhaseController.value > 0.5 && !_showDescription && mounted) {
        setState(() {
          _showDescription = true;
        });
      }
      if (_secondPhaseController.value > 0.7 && !_showLoginButton && mounted) {
        setState(() {
          _showLoginButton = true;
        });
      }
      if (_secondPhaseController.value > 0.8 && !_showSignUpButton && mounted) {
        setState(() {
          _showSignUpButton = true;
        });
      }
      if (_secondPhaseController.value > 0.9 && !_showGuestButton && mounted) {
        setState(() {
          _showGuestButton = true;
        });
      }
    });
  }

  void _generateFoodItems() {
    // More diverse food emojis including drinks, snacks, and desserts
    final foodEmojis = [
      '🍔', '🍕', '🌮', '🍦', '🍩', '🍪', '🍫', '🍰', '🧁', '🍭', '🍿',
      '🥨', '🥐', '🍙', '🍜', '🍣', '🍱', '🥗', '🍲', '🍛', '🍝', '🥪',
      '🧇', '🥞', '🍮', '🍧', '🍨', '☕', '🧃', '🥤', '🧋', '🍹', '🍸',
      '🍎', '🍓', '🍇', '🍉', '🍌', '🥑', '🥥', '🍒', '🍍', '🥭', '🍊'
    ];

    for (int i = 0; i < _foodItemCount; i++) {
      _foodItems.add(FoodItem(
        emoji: foodEmojis[_random.nextInt(foodEmojis.length)],
        position: Offset(
          _random.nextDouble() * 1.2 - 0.1, // -0.1 to 1.1 (wider than screen)
          _random.nextDouble() * 1.5 + 0.2, // 0.2 to 1.7 (taller than screen)
        ),
        size: _random.nextDouble() * 0.06 + 0.04, // 4-10% of screen width (increased size)
        speed: _random.nextDouble() * 0.2 + 0.1, // Speed factor
        delay: _random.nextDouble(),
        rotationSpeed: (_random.nextDouble() - 0.5) * 2, // -1 to 1
        wobbleFrequency: _random.nextDouble() * 3 + 1,
        wobbleAmplitude: _random.nextDouble() * 10 + 5,
      ));
    }
  }

  void _generateFoodParticles() {
    // Food-related icons for background particles
    final foodIcons = [
      Icons.restaurant, Icons.local_pizza, Icons.local_cafe,
      Icons.local_bar, Icons.cake, Icons.icecream, Icons.fastfood,
      Icons.coffee, Icons.emoji_food_beverage, Icons.lunch_dining,
      Icons.bakery_dining, Icons.ramen_dining, Icons.set_meal
    ];

    for (int i = 0; i < _particleCount; i++) {
      _foodParticles.add(FoodParticle(
        icon: foodIcons[_random.nextInt(foodIcons.length)],
        position: Offset(
          _random.nextDouble(),
          _random.nextDouble(),
        ),
        size: _random.nextDouble() * 0.03 + 0.01, // 1-4% of screen width
        opacity: _random.nextDouble() * 0.15 + 0.05, // 5-20% opacity
        speed: _random.nextDouble() * 0.0005 + 0.0002, // Movement speed
        angle: _random.nextDouble() * 2 * math.pi, // Random direction
      ));
    }
  }

  void _generateFloatingIcons() {
    // Food icons that float up from the bottom
    final foodIcons = [
      Icons.lunch_dining,
      Icons.local_pizza,
      Icons.icecream,
      Icons.coffee,
      Icons.cake,
      Icons.fastfood,
      Icons.local_cafe,
      Icons.ramen_dining,
      Icons.restaurant,
      Icons.set_meal,
      Icons.bakery_dining,
      Icons.emoji_food_beverage,
    ];

    for (int i = 0; i < _floatingIconCount; i++) {
      _floatingIcons.add(FloatingFoodIcon(
        icon: foodIcons[_random.nextInt(foodIcons.length)],
        startPosition: Offset(
          _random.nextDouble() * 0.8 + 0.1, // 0.1 to 0.9 (horizontal position)
          1.2 + _random.nextDouble() * 0.5, // 1.2 to 1.7 (below screen)
        ),
        size: _random.nextDouble() * 0.08 + 0.05, // 5-13% of screen width (large)
        speed: _random.nextDouble() * 0.4 + 0.2, // Vertical speed
        delay: _random.nextDouble(),
        rotationSpeed: (_random.nextDouble() - 0.5) * 4, // -2 to 2
        horizontalMovement: (_random.nextDouble() - 0.5) * 0.3, // -0.15 to 0.15
        color: [
          Colors.white,
          Colors.amber.shade200,
          Colors.lightGreen.shade200,
          Colors.orange.shade200,
          Colors.red.shade200,
        ][_random.nextInt(5)],
      ));
    }
  }

  void _transitionToSecondPhase() {
    setState(() {
      _showSecondPhase = true;
    });
    _secondPhaseController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _backgroundController.dispose();
    _foodItemsController.dispose();
    _secondPhaseController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _floatingIconsController.dispose();
    _transitionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            // Main content
            _showSecondPhase
                ? _buildSecondPhase()
                : _buildFirstPhase(),

            // Skip button - enhanced design
            if (_showSkipButton && !_showSecondPhase)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + 0.05 * _pulseController.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _transitionToSecondPhase,
                            borderRadius: BorderRadius.circular(24),
                            splashColor: Colors.white.withOpacity(0.3),
                            highlightColor: Colors.white.withOpacity(0.1),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Skip",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
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
      ),
    );
  }

  Widget _buildFirstPhase() {
    final size = MediaQuery.of(context).size;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Animated gradient background
        AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: const [
                    Color(0xFF8BC34A),
                    Color(0xFF689F38),
                    Color(0xFF558B2F),
                  ],
                  stops: [
                    0.0,
                    0.5 + 0.1 * math.sin(_backgroundController.value * 2 * math.pi),
                    1.0
                  ],
                ),
              ),
            );
          },
        ),

        // Animated background patterns
        AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return CustomPaint(
              painter: BackgroundPatternPainter(
                progress: _backgroundController.value,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Food icon particles in background
        AnimatedBuilder(
          animation: _particleController,
          builder: (context, child) {
            return CustomPaint(
              painter: FoodParticlePainter(
                particles: _foodParticles,
                progress: _particleController.value,
                screenSize: size,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Floating food items with wobble effect
        AnimatedBuilder(
          animation: _foodItemsController,
          builder: (context, child) {
            return CustomPaint(
              painter: FoodItemsPainter(
                foodItems: _foodItems,
                progress: _foodItemsController.value,
                screenSize: size,
                wobbleProgress: _backgroundController.value,
              ),
              size: Size.infinite,
            );
          },
        ),

        // New floating food icons from bottom
        AnimatedBuilder(
          animation: _floatingIconsController,
          builder: (context, child) {
            return CustomPaint(
              painter: FloatingIconsPainter(
                icons: _floatingIcons,
                progress: _floatingIconsController.value,
                screenSize: size,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Plate with food illustration
        Center(
          child: AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) {
              return Opacity(
                opacity: _logoOpacityAnimation.value,
                child: Transform.rotate(
                  angle: _logoRotateAnimation.value * math.pi,
                  child: Transform.scale(
                    scale: _logoScaleAnimation.value,
                    child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 220 + (5 * math.sin(_pulseController.value * math.pi)),
                            height: 220 + (5 * math.sin(_pulseController.value * math.pi)),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3 + 0.1 * math.sin(_pulseController.value * math.pi)),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(30),
                            child: Image.asset(
                              'images/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback if image is not found
                                return Icon(
                                  Icons.restaurant,
                                  size: 100,
                                  color: Colors.green.shade700,
                                );
                              },
                            ),
                          );
                        }
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Brand name with animation
        Positioned(
          bottom: 140,
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) {
              return Opacity(
                opacity: _textOpacityAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _textSlideAnimation.value),
                  child: ShimmerText(
                    text: 'SnackHunt',
                    baseColor: Colors.white,
                    highlightColor: Colors.white.withOpacity(0.7),
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: Color(0x88000000),
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Tagline with animation
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) {
              return Opacity(
                opacity: _textOpacityAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _textSlideAnimation.value * 1.2),
                  child: const Text(
                    'Discover • Crave • Enjoy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: Color(0x88000000),
                          blurRadius: 3,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Subtitle with animation
        Positioned(
          bottom: 40,
          left: 30,
          right: 30,
          child: AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) {
              return Opacity(
                opacity: _textOpacityAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _textSlideAnimation.value * 1.5),
                  child: const Text(
                    'Your ultimate guide to delicious snacks around Telkom University',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Progress indicator at bottom
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              width: 100,
              height: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _transitionTimer == null ? 1.0 :
                  (10000 - _transitionTimer!.tick * 1000) / 10000,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondPhase() {
    return AnimatedBuilder(
      animation: _secondPhaseController,
      builder: (context, child) {
        return Opacity(
          opacity: _secondPhaseOpacityAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFF5F5F5),
                  const Color(0xFFE8F5E9),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Salad image with animation
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.8, end: 1.0),
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  width: 240,
                                  height: 240,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFD7EAD9),
                                        const Color(0xFFC8E6C9),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.2),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'images/salad.png',
                                      width: 180,
                                      height: 180,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        // Fallback if image is not found
                                        return Icon(
                                          Icons.restaurant_menu,
                                          size: 100,
                                          color: Colors.green.shade700,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 40),

                          // Title with animation
                          AnimatedOpacity(
                            opacity: _showTitle ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            child: AnimatedSlide(
                              offset: _showTitle ? Offset.zero : const Offset(0, 0.2),
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOut,
                              child: ShimmerText(
                                text: "Discover,\nCrave, Enjoy!",
                                baseColor: Colors.black,
                                highlightColor: Colors.green.shade700,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Description with animation
                          AnimatedOpacity(
                            opacity: _showDescription ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            child: AnimatedSlide(
                              offset: _showDescription ? Offset.zero : const Offset(0, 0.2),
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOut,
                              child: const Text(
                                "Discover the best snacks around Telkom University, crave your favorites, and enjoy every bite with SnackHunt!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Buttons section with staggered animation
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Login/Sign In button
                        AnimatedOpacity(
                          opacity: _showLoginButton ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          child: AnimatedSlide(
                            offset: _showLoginButton ? Offset.zero : const Offset(0, 0.2),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacementNamed('/login');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8BC34A),
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  shadowColor: Colors.green.withOpacity(0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.login_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      "Login / Sign In",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Sign Up button
                        AnimatedOpacity(
                          opacity: _showSignUpButton ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          child: AnimatedSlide(
                            offset: _showSignUpButton ? Offset.zero : const Offset(0, 0.2),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacementNamed('/register');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF8BC34A),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                    side: const BorderSide(color: Color(0xFF8BC34A), width: 2),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_add_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      "Sign Up",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Continue as Guest button
                        AnimatedOpacity(
                          opacity: _showGuestButton ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          child: AnimatedSlide(
                            offset: _showGuestButton ? Offset.zero : const Offset(0, 0.2),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacementNamed('/dashboard');
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black54,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.explore_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    "Continue as Guest",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Food item data class with wobble effect parameters
class FoodItem {
  final String emoji;
  final Offset position;
  final double size;
  final double speed;
  final double delay;
  final double rotationSpeed;
  final double wobbleFrequency;
  final double wobbleAmplitude;

  FoodItem({
    required this.emoji,
    required this.position,
    required this.size,
    required this.speed,
    required this.delay,
    required this.rotationSpeed,
    required this.wobbleFrequency,
    required this.wobbleAmplitude,
  });
}

// Food particle data class for background
class FoodParticle {
  final IconData icon;
  final Offset position;
  final double size;
  final double opacity;
  final double speed;
  final double angle;

  FoodParticle({
    required this.icon,
    required this.position,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.angle,
  });
}

// Floating food icon data class - NEW
class FloatingFoodIcon {
  final IconData icon;
  final Offset startPosition;
  final double size;
  final double speed;
  final double delay;
  final double rotationSpeed;
  final double horizontalMovement;
  final Color color;

  FloatingFoodIcon({
    required this.icon,
    required this.startPosition,
    required this.size,
    required this.speed,
    required this.delay,
    required this.rotationSpeed,
    required this.horizontalMovement,
    required this.color,
  });
}

// Custom painter for food items with wobble effect
class FoodItemsPainter extends CustomPainter {
  final List<FoodItem> foodItems;
  final double progress;
  final Size screenSize;
  final double wobbleProgress;

  FoodItemsPainter({
    required this.foodItems,
    required this.progress,
    required this.screenSize,
    required this.wobbleProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (var item in foodItems) {
      // Calculate animation progress with delay
      final itemProgress = (progress + item.delay) % 1.0;

      // Calculate position with floating effect
      final baseX = screenSize.width * item.position.dx;

      // Add wobble effect to X position
      final wobbleX = item.wobbleAmplitude *
          math.sin(wobbleProgress * 2 * math.pi * item.wobbleFrequency + item.delay * 10);

      final x = baseX + wobbleX;

      // Y position moves from bottom to top with a wave pattern
      final y = screenSize.height * (1.0 + item.position.dy - itemProgress * (1.0 + item.speed));

      // Only draw if in view
      if (y > -50 && y < screenSize.height + 50) {
        // Calculate rotation with wobble
        final baseRotation = itemProgress * 2 * math.pi * item.rotationSpeed;
        final wobbleRotation = 0.1 * math.sin(wobbleProgress * 2 * math.pi * 2 + item.delay * 5);
        final rotation = baseRotation + wobbleRotation;

        // Calculate opacity (fade in/out at edges)
        double opacity = 1.0;
        if (y < 50) {
          opacity = y / 50;
        } else if (y > screenSize.height - 50) {
          opacity = (screenSize.height - y) / 50;
        }

        // Calculate scale with wobble
        final scale = 1.0 + 0.1 * math.sin(wobbleProgress * 2 * math.pi + item.delay * 15);

        // Save canvas state
        canvas.save();

        // Apply transformations
        canvas.translate(x, y);
        canvas.rotate(rotation);
        canvas.scale(scale, scale);

        // Draw emoji
        textPainter.text = TextSpan(
          text: item.emoji,
          style: TextStyle(
            fontSize: screenSize.width * item.size,
            color: Colors.white.withOpacity(opacity.clamp(0.0, 1.0)),
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );

        // Restore canvas state
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(FoodItemsPainter oldDelegate) => true;
}

// Custom painter for food particles in background
class FoodParticlePainter extends CustomPainter {
  final List<FoodParticle> particles;
  final double progress;
  final Size screenSize;

  FoodParticlePainter({
    required this.particles,
    required this.progress,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Calculate position with slow movement
      final dx = (progress * particle.speed * math.cos(particle.angle)) % 1.0;
      final dy = (progress * particle.speed * math.sin(particle.angle)) % 1.0;

      final x = screenSize.width * ((particle.position.dx + dx) % 1.0);
      final y = screenSize.height * ((particle.position.dy + dy) % 1.0);

      // Calculate pulse effect
      final pulse = 1.0 + 0.2 * math.sin(progress * 2 * math.pi + particle.position.dx * 10);

      // Draw icon
      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(particle.icon.codePoint),
          style: TextStyle(
            fontSize: screenSize.width * particle.size * pulse,
            fontFamily: particle.icon.fontFamily,
            package: particle.icon.fontPackage,
            color: Colors.white.withOpacity(particle.opacity * pulse),
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      iconPainter.layout();
      iconPainter.paint(
        canvas,
        Offset(x - iconPainter.width / 2, y - iconPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(FoodParticlePainter oldDelegate) => true;
}

// NEW: Custom painter for floating food icons
class FloatingIconsPainter extends CustomPainter {
  final List<FloatingFoodIcon> icons;
  final double progress;
  final Size screenSize;

  FloatingIconsPainter({
    required this.icons,
    required this.progress,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var icon in icons) {
      // Calculate animation progress with delay
      final iconProgress = (progress + icon.delay) % 1.0;

      // Calculate vertical position (moving up)
      final y = screenSize.height * (icon.startPosition.dy - iconProgress * icon.speed);

      // Calculate horizontal position with sine wave movement
      final baseX = screenSize.width * icon.startPosition.dx;
      final waveX = screenSize.width * icon.horizontalMovement *
          math.sin(iconProgress * 6 * math.pi);
      final x = baseX + waveX;

      // Only draw if in view
      if (y > -50 && y < screenSize.height + 50) {
        // Calculate rotation
        final rotation = iconProgress * 2 * math.pi * icon.rotationSpeed;

        // Calculate opacity (fade in/out at edges)
        double opacity = 1.0;
        if (y < 50) {
          opacity = y / 50;
        } else if (y > screenSize.height - 50) {
          opacity = (screenSize.height - y) / 50;
        }

        // Calculate scale with pulse effect
        final scale = 1.0 + 0.2 * math.sin(iconProgress * 4 * math.pi);

        // Save canvas state
        canvas.save();

        // Apply transformations
        canvas.translate(x, y);
        canvas.rotate(rotation);
        canvas.scale(scale, scale);

        // Draw icon with glow effect
        final shadowPaint = Paint()
          ..color = icon.color.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

        canvas.drawCircle(Offset.zero, screenSize.width * icon.size * 0.6, shadowPaint);

        // Draw icon
        final iconPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.icon.codePoint),
            style: TextStyle(
              fontSize: screenSize.width * icon.size,
              fontFamily: icon.icon.fontFamily,
              package: icon.icon.fontPackage,
              color: icon.color.withOpacity(opacity.clamp(0.0, 1.0)),
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        iconPainter.layout();
        iconPainter.paint(
          canvas,
          Offset(-iconPainter.width / 2, -iconPainter.height / 2),
        );

        // Restore canvas state
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(FloatingIconsPainter oldDelegate) => true;
}

// Background pattern painter
class BackgroundPatternPainter extends CustomPainter {
  final double progress;

  BackgroundPatternPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Draw light beams
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi + progress * math.pi;
      final length = width * 0.8;
      final startX = width / 2;
      final startY = height / 2;
      final endX = startX + math.cos(angle) * length;
      final endY = startY + math.sin(angle) * length;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(
          center: Offset(startX, startY),
          radius: length,
        ))
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(startX, startY)
        ..lineTo(
          startX + math.cos(angle - 0.1) * length,
          startY + math.sin(angle - 0.1) * length,
        )
        ..lineTo(
          startX + math.cos(angle + 0.1) * length,
          startY + math.sin(angle + 0.1) * length,
        )
        ..close();

      canvas.drawPath(path, paint);
    }

    // Draw circles
    for (int i = 0; i < 15; i++) {
      final radius = width * (0.05 + (i % 3) * 0.03);
      final x = width * (0.2 + 0.6 * math.cos(progress * 2 * math.pi + i * 0.3));
      final y = height * (0.2 + 0.6 * math.sin(progress * 2 * math.pi + i * 0.3));

      final paint = Paint()
        ..color = Colors.white.withOpacity(0.1 + (i % 3) * 0.03)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw waves at bottom
    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final amplitude = 20.0 - (i * 5.0);
      final wavePhase = progress * 2 * math.pi + (i * math.pi / 3);

      path.moveTo(0, height * 0.85 + amplitude * math.sin(wavePhase));

      for (double x = 0; x <= width; x += 10) {
        final y = height * 0.85 + amplitude * math.sin(wavePhase + (x / width) * 4 * math.pi);
        path.lineTo(x, y);
      }

      path.lineTo(width, height);
      path.lineTo(0, height);
      path.close();

      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(BackgroundPatternPainter oldDelegate) => true;
}

// Shimmer text effect widget
class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerText({
    Key? key,
    required this.text,
    required this.style,
    required this.baseColor,
    required this.highlightColor,
  }) : super(key: key);

  @override
  _ShimmerTextState createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: _SlidingGradientTransform(
                slidePercent: _shimmerController.value,
              ),
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: widget.style,
          ),
        );
      },
    );
  }
}

// Helper class for shimmer effect
class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({
    required this.slidePercent,
  });

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

// Main function to run the app
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnackHunt',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Poppins',
      ),
      home: const LandingPage(),
      routes: {
        '/login': (context) => const Placeholder(), // Replace with actual login page
        '/register': (context) => const Placeholder(), // Replace with actual register page
        '/dashboard': (context) => const Placeholder(), // Replace with actual dashboard page
      },
    );
  }
}