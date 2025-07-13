import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/permissions_helper.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // WhatsApp-inspired colors
  static const Color _whatsappGreen = Color(0xFF25D366);
  static const Color _whatsappDark = Color(0xFF075E54);
  static const Color _whatsappLight = Color(0xFF128C7E);
  static const Color _whatsappTeal = Color(0xFF34B7F1);

  final List<OnboardingItem> _items = [
    OnboardingItem(
      icon: Icons.download_rounded,
      title: 'Save Status Updates',
      description: 'Download images and videos from WhatsApp status updates with a single tap',
      color: _whatsappGreen,
      gradient: [_whatsappGreen, _whatsappLight],
    ),
    OnboardingItem(
      icon: Icons.folder_special_rounded,
      title: 'Organized Gallery',
      description: 'All your saved statuses are neatly organized and easily accessible',
      color: _whatsappLight,
      gradient: [_whatsappLight, _whatsappTeal],
    ),
    OnboardingItem(
      icon: Icons.security_rounded,
      title: 'Secure & Private',
      description: 'Your data stays on your device. We need storage permission to save files securely',
      color: _whatsappDark,
      gradient: [_whatsappDark, _whatsappLight],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Check if this is the first time opening the app
  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('first_time') ?? true;
    
    if (!isFirstTime && mounted) {
      // Skip onboarding and go directly to home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);
    
    try {
      final granted = await PermissionsHelper.requestStoragePermission();
      
      if (granted) {
        await _completeOnboarding();
      } else {
        _showPermissionDialog();
      }
    } catch (e) {
      _showErrorDialog('Failed to request permissions: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time', false);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: child,
            );
          },
        ),
      );
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            const Text('Permission Required'),
          ],
        ),
        content: const Text(
          'Storage permission is required to save WhatsApp statuses. Please grant permission in settings to continue.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              PermissionsHelper.openAppSettings();
            },
            style: FilledButton.styleFrom(backgroundColor: _whatsappGreen),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            const Text('Error'),
          ],
        ),
        content: Text(message, style: const TextStyle(height: 1.4)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(backgroundColor: _whatsappGreen),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _whatsappGreen.withOpacity(0.1),
              Colors.white,
              _whatsappLight.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with skip button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // WhatsApp-style logo/title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _whatsappGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.share_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'DuoStatus Saver',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _whatsappDark,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: _whatsappGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // PageView with animations
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    _animationController.reset();
                    _animationController.forward();
                  },
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Animated icon with gradient background
                              Hero(
                                tag: 'onboarding_icon_$index',
                                child: Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [
                                        item.gradient[0].withOpacity(0.2),
                                        item.gradient[1].withOpacity(0.1),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: item.color.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: item.gradient,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      item.icon,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 48),
                              
                              // Title with WhatsApp-style typography
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _whatsappDark,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              
                              // Description with better spacing
                              Text(
                                item.description,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                  height: 1.6,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Enhanced page indicator and button
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    // WhatsApp-style page indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _items.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 32 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: _currentPage == index
                                ? LinearGradient(colors: [_whatsappGreen, _whatsappLight])
                                : null,
                            color: _currentPage == index 
                                ? null 
                                : _whatsappGreen.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // WhatsApp-style action button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _isLoading ? null : () {
                          if (_currentPage == _items.length - 1) {
                            _requestPermissions();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOutCubic,
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _whatsappGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _currentPage == _items.length - 1 
                                        ? 'Get Started' 
                                        : 'Continue',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _currentPage == _items.length - 1 
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: 20,
                                  ),
                                ],
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
  }
}

class OnboardingItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final List<Color> gradient;

  OnboardingItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.gradient,
  });
}

// Also update your permissions helper to fix the recursive call:
// In permissions_helper.dart, change line 86 from:
// static Future<void> openAppSettings() async {
//   await openAppSettings();
// }
// To:
// static Future<void> openAppSettings() async {
//   await openAppSettings();
// }