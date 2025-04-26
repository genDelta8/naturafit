import 'dart:math';
import 'package:naturafit/services/unit_preferences.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/views/client_side/book_session_page.dart';
import 'package:naturafit/views/client_side/client_home_page.dart';
import 'package:naturafit/views/client_side/client_log_progress_page.dart';
import 'package:naturafit/views/client_side/client_meal/client_current_meal_plan.dart';
import 'package:naturafit/views/client_side/client_weekly_schedule_page.dart';
import 'package:naturafit/views/client_side/client_workout/client_current_workout_plan.dart';
import 'package:naturafit/views/client_side/client_workout/select_workout_to_start_page.dart';
import 'package:naturafit/views/trainer_side/resources_page.dart';
import 'package:naturafit/views/trainer_side/trainer_home_page.dart';
import 'package:naturafit/views/trainer_side/trainer_profile_page.dart';
import 'package:naturafit/views/trainer_side/trainer_settings_page.dart';
import 'package:naturafit/views/trainer_side/weekly_schedule_page.dart';
import 'package:naturafit/widgets/curved_triangle_painter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/views/trainer_side/add_client_page.dart';
import 'package:naturafit/views/trainer_side/schedule_session_page.dart';
import 'package:naturafit/views/trainer_side/create_workout_plan_page.dart';
import 'package:naturafit/views/shared_side/create_meal_plan_page.dart';
import 'package:naturafit/views/trainer_side/generate_invitation_link.dart';
import 'package:naturafit/views/trainer_side/revenue_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NavigationController extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
}

class ClientSide extends StatefulWidget {
  const ClientSide({super.key});

  @override
  State<ClientSide> createState() => _ClientSideState();
}

class _ClientSideState extends State<ClientSide>
    with SingleTickerProviderStateMixin {
  final NavigationController _controller = NavigationController();
  late final AnimationController _animationController;
  bool _isMenuOpen = false;

  // Add these late final animations
  late final Animation<double> _rotationAnimation;
  late final List<Animation<double>> _positionAnimations;
  late final Animation<double> _formationRotationAnimation;

  // Add these animations
  late final List<Animation<double>> _scaleAnimations;
  late final List<Animation<double>> _slideAnimations;

  final List<Widget> _pages = [
    const ClientDashboard(),
    const ClientWeeklySchedulePage(),
    const CurrentMealPlanPage(),
    const CurrentWorkoutPlanPage(),
    //const ClientProfilePage(),
  ];

  

  // Helper function to map ranges
  double map(int x, int inMin, int inMax, double outMin, double outMax) {
    return (x - inMin) * (outMax - outMin) / (inMax - inMin) + outMin;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Initialize animations for each button
    _scaleAnimations = List.generate(
      4,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.2, // Stagger the animations
            0.6 + index * 0.1,
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    _slideAnimations = List.generate(
      4,
      (index) => Tween<double>(
        begin: 100.0,
        end: 0.0,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.2,
            0.6 + index * 0.1,
            curve: Curves.easeOut,
          ),
        ),
      ),
    );
  }

  // Add this method to handle menu toggle
  void _toggleMenu() {
    if (!_isMenuOpen) {
      setState(() {
        _isMenuOpen = true;
      });
      _animationController.forward();
    } else {
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isMenuOpen = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final userData = context.watch<UserProvider>().userData;
    final unitPreferences = context.watch<UnitPreferences>();

    
    final heightUnitToPass = userData?['heightUnit'] ?? 'cm';
    final weightUnitToPass = userData?['weightUnit'] ?? 'kg';
    var heightToPass = (heightUnitToPass == 'cm') ? (userData?['height'] ?? 170.0).toDouble() : (userData?['height'] ?? 170.0).toDouble() / 30.48;
    var weightToPass = (weightUnitToPass == 'kg') ? (userData?['weight'] ?? 70.0).toDouble() : (userData?['weight'] ?? 70.0).toDouble() * 2.20462;

    if (heightUnitToPass == 'ft') {
      heightToPass = unitPreferences.cmToft(heightToPass);
    }

    if (weightUnitToPass == 'lbs') {
      weightToPass = unitPreferences.kgToLbs(weightToPass);
    }
    
    
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Stack(
            clipBehavior: Clip.none,
            children: [
              _pages[_controller.currentIndex],

              // Navigation Bar - Move to bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Navigation Bar Container
                    Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(35),
                          topRight: Radius.circular(35),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                              // Left side buttons
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildNavButton(
                                        0, Icons.home_outlined, l10n.home),
                                    _buildNavButton(
                                        1, Icons.calendar_month_outlined, l10n.schedule),
                                  ],
                                ),
                              ),
                              // Center space for plus button
                              const SizedBox(width: 60),
                              // Right side buttons
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildNavButton(
                                        2, Icons.restaurant_menu_outlined, l10n.meal),
                                    _buildNavButton(
                                        3,
                                        Icons.fitness_center_outlined,
                                        l10n.workout),
                                    
                                  ],
                                ),
                              ),
                            ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Center Plus Button Background
              Positioned(
                left: 0,
                right: 0,
                bottom: 40,
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 15,
                                    decoration: BoxDecoration(
                                      color: theme.scaffoldBackgroundColor,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 60,
                                height: 15,
                                decoration: BoxDecoration(
                                  color: theme.scaffoldBackgroundColor,
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(30),
                                    bottomRight: Radius.circular(30),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Floating Button - Move to bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 40, // Position it above the nav bar
                child: Center(
                  child: // Center Plus Button
                      Column(
                    children: [
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Visibility(
                            visible: _isMenuOpen,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                /*
                                _buildAnimatedActionButton(
                                  icon: Icons.person_add_outlined,
                                  label: 'Add\nClient',
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const GenerateInviteLinkPage()),
                                  ),
                                  scaleAnimation: _scaleAnimations[0],
                                  slideAnimation: _slideAnimations[0],
                                  margin: 30,
                                ),
                                */
                                //const SizedBox(width: 10),
                                _buildAnimatedActionButton(
                                  icon: Icons.add_outlined,
                                  label: l10n.book_session,
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const BookSessionPage()),
                                  ),
                                  scaleAnimation: _scaleAnimations[1],
                                  slideAnimation: _slideAnimations[1],
                                  margin: 30,
                                ),
                                const SizedBox(width: 10),
                                
                                _buildAnimatedActionButton(
                                  icon: Icons.play_arrow,
                                  label: 'Start\nWorkout',
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SelectWorkoutToStartPage()),
                                  ),
                                  scaleAnimation: _scaleAnimations[0],
                                  slideAnimation: _slideAnimations[0],
                                  margin: 0,
                                ),
                                const SizedBox(width: 10),
                                _buildAnimatedActionButton(
                                  icon: Icons.edit_outlined,
                                  label: l10n.log_progress,
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => LogProgressPage(
                                      initialHeight: heightToPass,
                                      initialWeight: weightToPass,
                                      initialHeightUnit: heightUnitToPass,
                                      initialWeightUnit: weightUnitToPass,
                                    )),
                                  ),
                                  scaleAnimation: _scaleAnimations[1],
                                  slideAnimation: _slideAnimations[1],
                                  margin: 30,
                                ),
                                
                              ],
                            ),
                          );
                        },
                      ),

                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: myBlue60.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTap: _toggleMenu,
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: myBlue30,
                              borderRadius: BorderRadius.all(Radius.circular(16)),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: myBlue60,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                              ),
                              child: Center(
                                child: AnimatedIcon(
                                  icon: AnimatedIcons.menu_close,
                                  progress: _animationController,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavButton(int index, IconData icon, String label) {
    final theme = Theme.of(context);
    bool isSelected = _controller.currentIndex == index;

    return GestureDetector(
      onTap: () {
        _controller.setIndex(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 35,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? myBlue20 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? myBlue60 : theme.brightness == Brightness.light ? myGrey40 : myGrey60,
              size: 20,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: SizedBox(
                width: isSelected ? 6 : 0,
              ),
            ),
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  width: isSelected ? null : 0,
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      color: myBlue60,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: myBlue30,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(0),
        width: 75,
        height: 90,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: myBlue60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add this new method for animated buttons
  Widget _buildAnimatedActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Animation<double> scaleAnimation,
    required Animation<double> slideAnimation,
    required double margin,
  }) {
    return Transform.translate(
      offset: Offset(0, slideAnimation.value),
      child: Transform.scale(
        scale: scaleAnimation.value,
        child: Container(
          margin: EdgeInsets.only(top: margin),
          child: _buildActionButton(
            icon: icon,
            label: label,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
