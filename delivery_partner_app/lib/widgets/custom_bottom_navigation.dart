// widgets/custom_bottom_navigation.dart - Enhanced Bottom Navigation Bar
import 'package:flutter/material.dart';
import '../models/delivery_partner_model.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/profile/profile_screen.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final DeliveryPartnerModel deliveryPartner;
  final Function(int)? onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.deliveryPartner,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                index: 0,
                isSelected: currentIndex == 0,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.assignment_rounded,
                label: 'Orders',
                index: 1,
                isSelected: currentIndex == 1,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.person_rounded,
                label: 'Profile',
                index: 2,
                isSelected: currentIndex == 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!(index);
        } else {
          _navigateToScreen(context, index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF00BFFF).withOpacity(0.1) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                icon,
                color: isSelected 
                    ? const Color(0xFF00BFFF) 
                    : const Color(0xFF9E9E9E),
                size: isSelected ? 28 : 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: isSelected 
                    ? const Color(0xFF00BFFF) 
                    : const Color(0xFF9E9E9E),
                fontSize: isSelected ? 13 : 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontFamily: 'SFProDisplay',
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, int index) {
    Widget targetScreen;
    
    switch (index) {
      case 0:
        targetScreen = DashboardScreen(deliveryPartner: deliveryPartner);
        break;
      case 1:
        targetScreen = OrdersScreen(deliveryPartner: deliveryPartner);
        break;
      case 2:
        targetScreen = ProfileScreen(deliveryPartner: deliveryPartner);
        break;
      default:
        return;
    }

    // Only navigate if not already on the current screen
    if (index != currentIndex) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }
}

// Enhanced Bottom Navigation with Floating Action Button style
class EnhancedBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final DeliveryPartnerModel deliveryPartner;
  final Function(int)? onTap;

  const EnhancedBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.deliveryPartner,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.8),
            Colors.white,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background blur effect
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
            ),
          ),
          
          // Navigation items
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildEnhancedNavItem(
                    context: context,
                    icon: Icons.dashboard_rounded,
                    activeIcon: Icons.dashboard,
                    label: 'Dashboard',
                    index: 0,
                    isSelected: currentIndex == 0,
                  ),
                  _buildEnhancedNavItem(
                    context: context,
                    icon: Icons.assignment_outlined,
                    activeIcon: Icons.assignment,
                    label: 'Orders',
                    index: 1,
                    isSelected: currentIndex == 1,
                  ),
                  _buildEnhancedNavItem(
                    context: context,
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    index: 2,
                    isSelected: currentIndex == 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!(index);
        } else {
          _navigateToScreen(context, index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF00BFFF) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF00BFFF).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected 
                    ? Colors.white 
                    : const Color(0xFF9E9E9E),
                size: isSelected ? 26 : 24,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SFProDisplay',
                ),
                child: Text(label),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, int index) {
    Widget targetScreen;
    
    switch (index) {
      case 0:
        targetScreen = DashboardScreen(deliveryPartner: deliveryPartner);
        break;
      case 1:
        targetScreen = OrdersScreen(deliveryPartner: deliveryPartner);
        break;
      case 2:
        targetScreen = ProfileScreen(deliveryPartner: deliveryPartner);
        break;
      default:
        return;
    }

    // Only navigate if not already on the current screen
    if (index != currentIndex) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
        ),
      );
    }
  }
}
