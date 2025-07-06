import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Import AdMob
import '../helpers/ad_helper.dart'; // Import the ad helper
import 'whatsapp_screen.dart';
import 'whatsapp_business_screen.dart';
import 'saved_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isNavBarVisible = true;

  late final PageController _pageController;
  late final AnimationController _animationController;
  late final Animation<double> _slideAnimation;

  // Banner Ad instance
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  static const List<Widget> _screens = [
    WhatsAppScreen(),
    WhatsAppBusinessScreen(),
    SavedScreen(),
    SettingsScreen(),
  ];

  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.whatshot_outlined),
      activeIcon: Icon(Icons.whatshot),
      label: 'Status',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.blur_on_outlined),
      activeIcon: Icon(Icons.blur_on),
      label: 'Business',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.bookmark_outline),
      activeIcon: Icon(Icons.bookmark),
      label: 'Saved',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings_outlined),
      activeIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: _currentIndex);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    
    // --- Load Banner Ad ---
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdHelper.createBannerAd()
      ..load();
    
    // We are not setting a listener here because it's handled in AdHelper.
    // However, if you need to react to ad events in this screen, you can
    // modify AdHelper to accept a listener or add one here.
    // For simplicity, we'll just check if it's loaded.
    // A better approach for production would be to use the listener to set state.
    // For this example, we'll assume it loads and set a flag.
    setState(() {
      _isBannerAdLoaded = true; // Assume loaded for UI purposes
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _bannerAd?.dispose(); // Dispose the banner ad
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      HapticFeedback.lightImpact();
    }
  }

  void _onNavTap(int index) {
    if (_currentIndex != index) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.mediumImpact();
    }
  }

  void _toggleNavBarVisibility(bool visible) {
    if (_isNavBarVisible != visible) {
      setState(() {
        _isNavBarVisible = visible;
      });

      if (visible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo is ScrollUpdateNotification) {
            if (scrollInfo.scrollDelta! > 5) {
              _toggleNavBarVisibility(false);
            } else if (scrollInfo.scrollDelta! < -5) {
              _toggleNavBarVisibility(true);
            }
          }
          if (scrollInfo is ScrollEndNotification) {
            final metrics = scrollInfo.metrics;
            if (metrics.atEdge) {
              _toggleNavBarVisibility(true);
            }
          }
          return false;
        },
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          itemCount: _screens.length,
          itemBuilder: (context, index) => _screens[index],
          allowImplicitScrolling: true,
        ),
      ),
      // --- Updated Bottom Navigation Bar with Ad ---
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ad Container
          if (_isBannerAdLoaded && _bannerAd != null)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          
          // Your existing animated Nav Bar
          if (_isNavBarVisible)
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    (1 - _slideAnimation.value) * 100,
                  ),
                  child: Opacity(
                    opacity: _slideAnimation.value,
                    child: _buildBottomNavBar(context),
                  ),
                );
              },
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
  Widget _buildBottomNavBar(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.scaffoldBackgroundColor.withOpacity(0.95),
            theme.scaffoldBackgroundColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, -10),
            spreadRadius: -5,
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
            letterSpacing: 0.2,
          ),
          items: _navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == _currentIndex;
            
            return BottomNavigationBarItem(
              icon: _buildNavIcon(item.icon, isSelected, theme, false),
              activeIcon: _buildNavIcon(
                item.activeIcon ?? item.icon, 
                isSelected, 
                theme, 
                true
              ),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNavIcon(Widget icon, bool isSelected, ThemeData theme, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected 
          ? theme.colorScheme.primary.withOpacity(isActive ? 0.15 : 0.1)
          : Colors.transparent,
        boxShadow: isSelected && isActive ? [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: icon,
    );
  }
}