import 'dart:math';
import 'package:naturafit/services/invitation/connections_bloc.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/views/all_shared_settings/help_center_page.dart';
import 'package:naturafit/views/client_side/book_session_page.dart';
import 'package:naturafit/views/client_side/client_home_page.dart';
import 'package:naturafit/views/client_side/client_log_progress_page.dart';
import 'package:naturafit/views/client_side/client_meal/client_current_meal_plan.dart';
import 'package:naturafit/views/client_side/client_profile_page.dart';
import 'package:naturafit/views/client_side/client_settings_page.dart';
import 'package:naturafit/views/client_side/client_weekly_schedule_page.dart';
import 'package:naturafit/views/client_side/client_workout/client_current_workout_plan.dart';
import 'package:naturafit/views/client_side/client_workout/select_workout_to_start_page.dart';
import 'package:naturafit/views/trainer_side/coach_side.dart';
import 'package:naturafit/views/trainer_side/trainer_home_page.dart';
import 'package:naturafit/views/trainer_side/trainer_settings_page.dart';
import 'package:naturafit/views/web/web_coach_side.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_measure_picker.dart';
import 'package:naturafit/widgets/custom_search_bar.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/auth/bloc/data_fetch_service.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/views/client_side/client_notification_page.dart';
import 'package:naturafit/views/shared_side/messages_page.dart';
import 'package:naturafit/widgets/custom_user_profile_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:speedometer_chart/speedometer_chart.dart';
import 'package:naturafit/widgets/custom_top_selector.dart';
import 'package:naturafit/services/unit_preferences.dart';
import 'package:naturafit/services/notification_service.dart';

class WebClientSide extends StatefulWidget {
  const WebClientSide({super.key});

  @override
  State<WebClientSide> createState() => WebClientSideState();
}

class WebClientSideState extends State<WebClientSide> {
  int _currentIndex = 0;
  bool _isLeftSidebarExpanded = false;
  Widget _currentPage = const ClientDashboard();

  final List<Widget> _pages = [
    const ClientDashboard(),
    const ClientWeeklySchedulePage(),
    const CurrentMealPlanPage(),
    const CurrentWorkoutPlanPage(),
    const ClientProfilePage(),
    const NotificationsPage(),
    const MessagesPage(),
    //const ClientProfilePage(),
  ];

  // Add this method to allow setting custom pages
  void setCurrentPage(Widget page, String pageName) {
    setState(() {
      _currentPage = page;
      if (pageName == 'MessagesPage') {
        _currentIndex = 6; // Use -1 to indicate custom page
      } else {
        _currentIndex = -1;
      }
    });
  }

  // Add this method to get the current page
  Widget get currentPage {
    if (_currentIndex >= 0) {
      return _pages[_currentIndex];
    }
    return _currentPage;
  }

  // Add this method after the currentPage getter
  void _handleNotificationClick() async {
    final userProvider = context.read<UserProvider>();
    final userData = userProvider.userData;

    if (userData != null) {
      setState(() {
        _currentIndex = 5; // Set notification page index
      });
      try {
        // Mark notifications as read
        await NotificationService()
            .markAllNotificationsAsRead(userData['userId']);

        // Update unread notifications in UserProvider
        if (mounted) {
          userProvider.setUnreadNotifications([]);
        }
      } catch (e) {
        debugPrint('Error handling notification click: $e');
      }
    }
  }

  // Add this method near the top of the class, with other methods
  void _showSetWeightGoalDialog() {
    final userProvider = context.read<UserProvider>();
    final unitPrefs = context.read<UnitPreferences>();
    final userData = userProvider.userData;
    final weightUnit = userData?['weightUnit'] ?? 'kg';
    final isMetric = weightUnit == 'kg';

    // Current weight is stored in kg, convert if needed
    final currentWeightKg =
        userProvider.userData?['weight']?.toDouble() ?? 70.0;
    final currentWeightDisplay =
        isMetric ? currentWeightKg : unitPrefs.kgToLbs(currentWeightKg);

    final l10n = AppLocalizations.of(context)!;

    String selectedGoalType = 'loss';
    final weightController = TextEditingController();
    bool isValidInput = false;
    double? targetWeight;

    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void calculateTargetWeight() {
              if (weightController.text.isEmpty) {
                isValidInput = false;
                setState(() {});
                return;
              }

              try {
                // Convert input to kg if needed
                double goalWeightInput = double.parse(weightController.text);
                double goalWeightKg = isMetric
                    ? goalWeightInput
                    : unitPrefs.lbsToKg(goalWeightInput);

                if (goalWeightKg <= 0) {
                  isValidInput = false;
                  setState(() {});
                  return;
                }

                if (selectedGoalType == 'loss' &&
                    goalWeightKg >= currentWeightKg) {
                  isValidInput = false;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar.show(
                        title: l10n.weight_goal,
                        message: l10n.weight_loss_validation_error,
                        type: SnackBarType.error,
                      ),
                    );
                  }
                  setState(() {});
                  return;
                }

                targetWeight = selectedGoalType == 'loss'
                    ? currentWeightKg - goalWeightKg
                    : currentWeightKg + goalWeightKg;
                isValidInput = true;
              } catch (e) {
                isValidInput = false;
              }
              setState(() {});
            }

            return Dialog(
              backgroundColor: theme.brightness == Brightness.light
                  ? Colors.white
                  : myGrey80,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.set_weight_goal,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.brightness == Brightness.light
                            ? myGrey90
                            : myGrey10,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.light
                            ? myGrey10
                            : myGrey80,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: myGrey20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: myBlue60.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.monitor_weight_outlined,
                              color: myBlue60,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.current_weight,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: theme.brightness == Brightness.light
                                      ? myGrey60
                                      : myGrey10,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${currentWeightDisplay.toStringAsFixed(1)} ${weightUnit}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.brightness == Brightness.light
                                      ? myGrey90
                                      : myGrey10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomTopSelector(
                      options: [
                        TopSelectorOption(title: l10n.loss),
                        TopSelectorOption(title: l10n.gain),
                      ],
                      selectedIndex: selectedGoalType == 'loss' ? 0 : 1,
                      onOptionSelected: (index) {
                        setState(() {
                          selectedGoalType = index == 0 ? 'loss' : 'gain';
                          calculateTargetWeight();
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    CustomFocusTextField(
                      label:
                          '${l10n.weight_to} ${selectedGoalType == 'loss' ? l10n.loss.toLowerCase() : l10n.gain.toLowerCase()}',
                      hintText: weightUnit, // Show kg or lbs
                      controller: weightController,
                      prefixIcon: Icons.monitor_weight_outlined,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) => calculateTargetWeight(),
                      shouldShowBorder: true,
                    ),
                    if (isValidInput && targetWeight != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: selectedGoalType == 'loss'
                              ? myRed50.withOpacity(0.1)
                              : myGreen50.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedGoalType == 'loss'
                                ? myRed50
                                : myGreen50,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (selectedGoalType == 'loss'
                                        ? myRed50
                                        : myGreen50)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                selectedGoalType == 'loss'
                                    ? Icons.trending_down
                                    : Icons.trending_up,
                                color: selectedGoalType == 'loss'
                                    ? myRed50
                                    : myGreen50,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.target_weight,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: selectedGoalType == 'loss'
                                        ? myRed50
                                        : myGreen50,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${(isMetric ? targetWeight! : unitPrefs.kgToLbs(targetWeight!)).toStringAsFixed(1)} ${weightUnit}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: selectedGoalType == 'loss'
                                        ? myRed50
                                        : myGreen50,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            l10n.cancel,
                            style: GoogleFonts.plusJakartaSans(
                              color: theme.brightness == Brightness.light
                                  ? myGrey60
                                  : myGrey10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: isValidInput
                              ? () async {
                                  final userId =
                                      userProvider.userData?['userId'];
                                  if (userId != null && targetWeight != null) {
                                    try {
                                      final weightGoalId = FirebaseFirestore
                                          .instance
                                          .collection('weight_goals')
                                          .doc(userId)
                                          .collection('all_weight_goals')
                                          .doc()
                                          .id;

                                      // Convert goal amount to kg if in lbs
                                      final goalAmountKg = isMetric
                                          ? double.parse(weightController.text)
                                          : unitPrefs.lbsToKg(double.parse(
                                              weightController.text));

                                      final weightGoalData = {
                                        'weightGoalId': weightGoalId,
                                        'startWeight':
                                            currentWeightKg, // Always store in kg
                                        'targetWeight':
                                            targetWeight, // Already in kg
                                        'goalType': selectedGoalType,
                                        'goalAmount':
                                            goalAmountKg, // Store in kg
                                        'createdAt':
                                            FieldValue.serverTimestamp(),
                                        'isCompleted': false,
                                      };

                                      await FirebaseFirestore.instance
                                          .collection('weight_goals')
                                          .doc(userId)
                                          .collection('all_weight_goals')
                                          .doc(weightGoalId)
                                          .set(weightGoalData);

                                      // Update the currentWeightGoal in UserProvider
                                      userProvider
                                          .setCurrentWeightGoal(weightGoalData);

                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          CustomSnackBar.show(
                                            title: l10n.weight_goal,
                                            message:
                                                l10n.weight_goal_set_success,
                                            type: SnackBarType.success,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          CustomSnackBar.show(
                                            title: l10n.weight_goal,
                                            message: l10n.weight_goal_set_error,
                                            type: SnackBarType.error,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: myBlue60,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            l10n.submit,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showWeightActionDialog() {
    final userProvider = context.read<UserProvider>();
    final currentWeightGoal = userProvider.currentWeightGoal;
    final l10n = AppLocalizations.of(context)!;
    if (currentWeightGoal == null) {
      // If no weight goal exists, show the set goal dialog directly
      _showSetWeightGoalDialog();
    } else {
      // If a weight goal exists, show the action selector dialog
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTopSelector(
                    options: [
                      TopSelectorOption(title: l10n.new_goal),
                      TopSelectorOption(title: l10n.log_weight),
                    ],
                    selectedIndex: 0,
                    onOptionSelected: (index) {
                      Navigator.pop(context);
                      if (index == 0) {
                        _showSetWeightGoalDialog();
                      } else {
                        _showLogWeightDialog();
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  void _showLogWeightDialog() {
    final userProvider = context.read<UserProvider>();
    final userData = userProvider.userData;
    final weightUnit = userData?['weightUnit'] ?? 'kg';
    final currentWeight = weightUnit == 'kg'
        ? (userData?['weight'] ?? 70.0).toDouble()
        : (userData?['weight'] ?? 70.0).toDouble() * 2.20462;
    bool hasChanges = false;
    double newWeight = currentWeight;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // Get weight goal data
    final currentWeightGoal = userProvider.currentWeightGoal;
    final startWeight = currentWeightGoal?['startWeight']?.toDouble();
    final targetWeight = currentWeightGoal?['targetWeight']?.toDouble();
    final goalType = currentWeightGoal?['goalType'];

    // Convert weights to display unit if needed
    final unitPrefs = context.read<UnitPreferences>();
    final isMetric = weightUnit == 'kg';
    final displayStartWeight = startWeight != null
        ? (isMetric ? startWeight : unitPrefs.kgToLbs(startWeight))
        : null;
    final displayTargetWeight = targetWeight != null
        ? (isMetric ? targetWeight : unitPrefs.kgToLbs(targetWeight))
        : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: theme.brightness == Brightness.light
                  ? Colors.white
                  : myGrey80,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.log_weight,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.brightness == Brightness.light
                            ? myGrey90
                            : myGrey10,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Show start and target weights if they exist
                    if (currentWeightGoal != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.light
                              ? myGrey10
                              : myGrey80,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: myGrey20),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.start_weight,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          theme.brightness == Brightness.light
                                              ? myGrey60
                                              : myGrey10,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${displayStartWeight?.toStringAsFixed(1)} $weightUnit',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          theme.brightness == Brightness.light
                                              ? myGrey90
                                              : myGrey10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: myGrey20,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.target_weight,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            theme.brightness == Brightness.light
                                                ? myGrey60
                                                : myGrey10,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${displayTargetWeight?.toStringAsFixed(1)} $weightUnit',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: goalType == 'loss'
                                            ? myRed50
                                            : myGreen50,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    CustomMeasurePicker(
                      title: l10n.weight,
                      initialValue: currentWeight,
                      initialUnit: weightUnit,
                      units: const ['kg', 'lbs'],
                      onChanged: (value, unit) {
                        // Convert to kg if needed
                        if (unit == 'lbs') {
                          value = value / 2.20462;
                        }
                        setState(() {
                          hasChanges = value != currentWeight;
                          newWeight = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            l10n.cancel,
                            style: GoogleFonts.plusJakartaSans(
                              color: theme.brightness == Brightness.light
                                  ? myGrey60
                                  : myGrey10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: hasChanges
                              ? () async {
                                  final userId =
                                      userProvider.userData?['userId'];
                                  if (userId != null) {
                                    try {
                                      // Update weight in Firestore
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(userId)
                                          .update({'weight': newWeight});

                                      // Update UserProvider
                                      userProvider.setUserData({
                                        ...userProvider.userData!,
                                        'weight': newWeight,
                                      });

                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          CustomSnackBar.show(
                                            title: l10n.weight,
                                            message: l10n
                                                .weight_updated_successfully,
                                            type: SnackBarType.success,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          CustomSnackBar.show(
                                            title: l10n.weight,
                                            message: l10n.weight_update_failed,
                                            type: SnackBarType.error,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: myBlue60,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            l10n.submit,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEnterInvitationCodeDialog() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final codeController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                  color: theme.brightness == Brightness.dark
                      ? myGrey60
                      : myGrey30),
            ),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.enter_invitation_code,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : myGrey80,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white70
                              : myGrey60,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    l10n.enter_invitation_code_shared_by_your_trainer,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white70
                          : myGrey60,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Code Input
                  CustomFocusTextField(
                    label: l10n.invitation_code,
                    hintText: l10n.enter_invitation_code,
                    controller: codeController,
                    isRequired: true,
                    prefixIcon: Icons.key_rounded,
                    onChanged: (value) {
                      setState(() {}); // Rebuild to update submit button state
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: codeController.text.isEmpty || isLoading
                          ? null
                          : () async {
                              setState(() {
                                isLoading = true;
                              });

                              try {
                                final userProvider =
                                    context.read<UserProvider>();
                                final userRole = userProvider.userData?['role'];
                                final userId = userProvider.userData?['userId'];
                                final code = codeController.text.trim();

                                // Check if invitation exists
                                final inviteDoc = await FirebaseFirestore
                                    .instance
                                    .collection('invites')
                                    .doc(code)
                                    .get();

                                if (!inviteDoc.exists) {
                                  throw l10n.invalid_invitation_code;
                                }

                                final inviteData = inviteDoc.data()!;

                                if (inviteData['used'] == true) {
                                  throw l10n.invitation_code_already_used;
                                }

                                if (inviteData['trainerClientId'] == userId) {
                                  throw l10n.cannot_connect_to_yourself;
                                }

                                if (userRole == 'trainer') {
                                  throw l10n.trainers_cannot_connect_to_other_trainers;
                                }

                                // Check for existing connection
                                final existingConnection =
                                    await FirebaseFirestore.instance
                                        .collection('connections')
                                        .doc('client')
                                        .collection(userId)
                                        .doc(inviteData['professionalId'])
                                        .get();

                                if (existingConnection.exists) {
                                  throw l10n.already_have_connection_with_professional;
                                }

                                // Create connection using ConnectionsBloc
                                context.read<ConnectionsBloc>().add(
                                      AcceptInvitation(
                                        clientId: userId,
                                        clientName: userProvider
                                                .userData?[fbRandomName] ??
                                            '',
                                        professionalId:
                                            inviteData['professionalId'],
                                        professionalRole: inviteData['role'],
                                        professionalUsername:
                                            inviteData['professionalUsername'],
                                        professionalFullName:
                                            inviteData['professionalFullName'],
                                        professionalProfileImageUrl:
                                            inviteData[fbProfileImageURL],
                                      ),
                                    );

                                // Add the new professional to UserProvider
                                final newProfessional = {
                                  'professionalId': inviteData['professionalId'],
                                  'professionalUsername': inviteData['professionalUsername'],
                                  'professionalFullName': inviteData['professionalFullName'],
                                  'professionalProfileImageUrl': inviteData[fbProfileImageURL],
                                  'role': inviteData['role'],
                                  'status': fbClientConfirmedStatus,
                                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                                };

                                final currentProfessionals = List<Map<String, dynamic>>.from(
                                  userProvider.partiallyTotalProfessionals ?? []
                                );
                                currentProfessionals.add(newProfessional);
                                userProvider.setPartiallyTotalProfessionals(currentProfessionals);

                                // Mark invitation as used
                                await FirebaseFirestore.instance
                                    .collection('invites')
                                    .doc(code)
                                    .update({
                                  'used': true,
                                  'acceptedAt': FieldValue.serverTimestamp(),
                                  'status': fbClientConfirmedStatus
                                });

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    CustomSnackBar.show(
                                      title: l10n.connection_created,
                                      message:
                                          l10n.successfully_connected_with_trainer,
                                      type: SnackBarType.success,
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  CustomSnackBar.show(
                                    title: l10n.error,
                                    message: e.toString(),
                                    type: SnackBarType.error,
                                  ),
                                );
                              } finally {
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: myBlue60,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              l10n.submit,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final userProvider = context.watch<UserProvider>();
    final userData = userProvider.userData;
    final unreadNotifications = userProvider.unreadNotifications?.length ?? 0;
    final width = MediaQuery.of(context).size.width;
    final canExpandLeftBar =
        width > 700; // Only allow expansion if width > 700px

    final heightUnitToPass = userData?['heightUnit'] ?? 'cm';
    final weightUnitToPass = userData?['weightUnit'] ?? 'kg';
    var heightToPass = (heightUnitToPass == 'cm')
        ? (userData?['height'] ?? 170.0).toDouble()
        : (userData?['height'] ?? 170.0).toDouble() / 30.48;
    var weightToPass = (weightUnitToPass == 'kg')
        ? (userData?['weight'] ?? 70.0).toDouble()
        : (userData?['weight'] ?? 70.0).toDouble() * 2.20462;

    final currentWeightGoal = userProvider.currentWeightGoal;
    final targetWeight = currentWeightGoal?['targetWeight']?.toDouble();
    final goalType = currentWeightGoal?['goalType'];
    final goalAmount = currentWeightGoal?['goalAmount']?.toDouble();
    final startWeight = currentWeightGoal?['startWeight']?.toDouble();
    final currentWeight = userData?['weight']?.toDouble() ?? 70.0;

    // Calculate progress and display values
    double progressValue = 0.0;
    String progressText =
        '0/0${weightUnitToPass}'; // Default value when no goal exists

    final unitPrefs = context.watch<UnitPreferences>();
    final weightUnit = userData?['weightUnit'] ?? 'kg';
    final isMetric = weightUnit == 'kg';

    if (currentWeightGoal != null &&
        goalAmount != null &&
        startWeight != null) {
      if (goalType == 'loss') {
        final weightChange = startWeight - currentWeight;
        final progressRatio = weightChange / goalAmount;

        progressValue = progressRatio.clamp(0.0, 1.0) * goalAmount;

        // Convert values to display unit if needed
        final displayWeightChange =
            isMetric ? weightChange : unitPrefs.kgToLbs(weightChange);
        final displayGoalAmount =
            isMetric ? goalAmount : unitPrefs.kgToLbs(goalAmount);

        // Add unit to the progress text
        progressText =
            '${displayWeightChange.toStringAsFixed(1)}/${displayGoalAmount.toStringAsFixed(1)}${weightUnit}';

        if (weightChange < 0) {
          progressText =
              '${displayWeightChange.toStringAsFixed(1)}/${displayGoalAmount.toStringAsFixed(1)}${weightUnit}';
        } else if (weightChange > goalAmount) {
          progressText =
              '+${displayWeightChange.toStringAsFixed(1)}/${displayGoalAmount.toStringAsFixed(1)}${weightUnit}';
        }
      } else {
        final weightChange = currentWeight - startWeight;
        final progressRatio = weightChange / goalAmount;

        progressValue = progressRatio.clamp(0.0, 1.0) * goalAmount;

        // Convert values to display unit if needed
        final displayWeightChange =
            isMetric ? weightChange : unitPrefs.kgToLbs(weightChange);
        final displayGoalAmount =
            isMetric ? goalAmount : unitPrefs.kgToLbs(goalAmount);

        // Add unit to the progress text
        progressText =
            '${displayWeightChange.toStringAsFixed(1)}/${displayGoalAmount.toStringAsFixed(1)}${weightUnit}';

        if (weightChange < 0) {
          progressText =
              '${displayWeightChange.toStringAsFixed(1)}/${displayGoalAmount.toStringAsFixed(1)}${weightUnit}';
        } else if (weightChange > goalAmount) {
          progressText =
              '+${displayWeightChange.toStringAsFixed(1)}/${displayGoalAmount.toStringAsFixed(1)}${weightUnit}';
        }
      }
    } else {
      // Update default text to include unit
      progressText = '0/0${weightUnit}';
    }

    // Responsive breakpoints
    final isVerySmall = width < 600;
    final isSmall = width < 800;
    final isMedium = width < 1200;
    final showSideBars = width > 1000;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Navigation Bar
          if (!isVerySmall)
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 72,
                maxWidth: 210,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: MouseRegion(
                  onEnter: (_) =>
                      setState(() => _isLeftSidebarExpanded = canExpandLeftBar),
                  onExit: (_) => setState(() => _isLeftSidebarExpanded = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: _isLeftSidebarExpanded ? 210 : 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          myBlue60,
                          myBlue50,
                        ],
                        stops: [0.0, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: SingleChildScrollView(
                      // Add SingleChildScrollView
                      child: ConstrainedBox(
                        // Add ConstrainedBox for minimum height
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height -
                              48, // 48 for padding
                        ),
                        child: IntrinsicHeight(
                          // Wrap with IntrinsicHeight
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 32, horizontal: 0),
                            child: Column(
                              children: [
                                // Top Actions
                                Column(
                                  children: [
                                    _buildLeftNavItem(
                                      icon: Icons.notifications,
                                      label: l10n.notifications,
                                      count: unreadNotifications,
                                      isSelected: _currentIndex == 5,
                                      onTap: _handleNotificationClick,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildLeftNavItem(
                                      icon: Icons.message_rounded,
                                      label: l10n.messages,
                                      count: userProvider.unreadMessageCount,
                                      isSelected: _currentIndex == 6,
                                      onTap: () =>
                                          setState(() => _currentIndex = 6),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Divider(
                                    color: Colors.white70,
                                    height: 1,
                                  ),
                                ),

                                const SizedBox(height: 24),
                                // Main Navigation
                                Expanded(
                                  child: Column(
                                    children: [
                                      _buildLeftNavItem(
                                        icon: Icons.home_outlined,
                                        label: l10n.home,
                                        isSelected: _currentIndex == 0,
                                        onTap: () =>
                                            setState(() => _currentIndex = 0),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildLeftNavItem(
                                        icon: Icons.calendar_month_outlined,
                                        label: l10n.schedule,
                                        isSelected: _currentIndex == 1,
                                        onTap: () =>
                                            setState(() => _currentIndex = 1),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildLeftNavItem(
                                        icon: Icons.restaurant_menu_outlined,
                                        label: l10n.meal,
                                        isSelected: _currentIndex == 2,
                                        onTap: () =>
                                            setState(() => _currentIndex = 2),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildLeftNavItem(
                                        icon: Icons.fitness_center_outlined,
                                        label: l10n.workout,
                                        isSelected: _currentIndex == 3,
                                        onTap: () =>
                                            setState(() => _currentIndex = 3),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildLeftNavItem(
                                        icon: Icons.person_outline,
                                        label: l10n.profile,
                                        isSelected: _currentIndex == 4,
                                        onTap: () =>
                                            setState(() => _currentIndex = 4),
                                      ),
                                    ],
                                  ),
                                ),
                                // Bottom buttons
                                _buildLeftNavItem(
                                  icon: Icons.settings_outlined,
                                  label: l10n.settings,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ClientSettingsPage(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildLeftNavItem(
                                  icon: Icons.help_outline,
                                  label: l10n.help,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const HelpCenterPage(),
                                      ),
                                    );
                                  }, // Will implement FAQ navigation later
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Main Content Area
          Expanded(
            flex: 3,
            child: Column(
              // Wrap in Column
              children: [
                _buildCustomAppBarForWeb(context), // Add app bar at top
                Expanded(
                  // Wrap content in Expanded
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child:
                        currentPage, // Use currentPage instead of _pages[_currentIndex]
                  ),
                ),
              ],
            ),
          ),

          // Right Sidebar
          if (showSideBars)
            Container(
              width: 300,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(-5, 0),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top section
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                          size: 16,
                                          color: theme.brightness ==
                                                  Brightness.dark
                                              ? myGrey10
                                              : myGrey60),
                                      const SizedBox(width: 8),
                                      Text(
                                        _getLocalizedDate(
                                            context, DateTime.now()),
                                        style: GoogleFonts.plusJakartaSans(
                                          color: theme.brightness ==
                                                  Brightness.dark
                                              ? myGrey10
                                              : myGrey60,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // User Profile Section
                                  Row(
                                    children: [
                                      // User Image
                                      Container(
                                        decoration: BoxDecoration(
                                          color: theme.brightness ==
                                                  Brightness.light
                                              ? Colors.white
                                              : myGrey80,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Container(
                                          margin: const EdgeInsets.all(1.5),
                                          width: 56,
                                          height: 56,
                                          child: CustomUserProfileImage(
                                            imageUrl:
                                                userData?['profileImageUrl'],
                                            name: userData?[fbFullName] ??
                                                userData?[fbRandomName] ??
                                                'User',
                                            size: 64,
                                            borderRadius: 12,
                                            backgroundColor: theme.brightness ==
                                                    Brightness.dark
                                                ? myGrey70
                                                : myGrey30,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Name and Switch Button Column
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  '${l10n.hi},',
                                                  style: theme
                                                      .textTheme.titleMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Text(
                                                  '💪',
                                                  style:
                                                      TextStyle(fontSize: 16),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              (userData?[fbFullName] ??
                                                      userData?[
                                                          fbRandomName]) ??
                                                  'User',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            //_buildSwitchToClientButton(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Switch to Client button
                                  if (userData?['isTrainerClientProfile'] ==
                                      true)
                                    _buildSwitchToTrainerButton(),
                                ],
                              ),

                              const Expanded(child: SizedBox()),

                              // Bottom Actions
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildActionButton(
                                    icon: Icons.add_outlined,
                                    label: l10n.book_session_web_button,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const BookSessionPage(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildActionButton(
                                    icon: Icons.edit_outlined,
                                    label: l10n.log_progress_web_button,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LogProgressPage(
                                          initialHeight: heightToPass,
                                          initialWeight: weightToPass,
                                          initialHeightUnit: heightUnitToPass,
                                          initialWeightUnit: weightUnitToPass,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Add the new invitation code card here
                                  InkWell(
                                    onTap: _showEnterInvitationCodeDialog,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color:
                                            theme.brightness == Brightness.dark
                                                ? myGrey70
                                                : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: theme.brightness ==
                                                  Brightness.dark
                                              ? myGrey60
                                              : myGrey30,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: myBlue60.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.key_rounded,
                                              color: myBlue60,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              l10n.enter_invitation_code,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                color: theme.brightness ==
                                                        Brightness.dark
                                                    ? myGrey10
                                                    : Colors.black87,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // Weight Goal Indicator
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        currentWeightGoal != null
                                            ? (goalType == 'loss'
                                                ? l10n.weight_loss_goal
                                                : l10n.weight_gain_goal)
                                            : l10n.no_weight_goal_set,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        progressText, // This will now show "0/0" when no goal exists
                                        style: GoogleFonts.plusJakartaSans(
                                          color: progressText.startsWith('-')
                                              ? myRed50
                                              : progressText.startsWith('+')
                                                  ? myGreen50
                                                  : theme.brightness ==
                                                          Brightness.dark
                                                      ? myGrey10
                                                      : myGrey90,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          SpeedometerChart(
                                            dimension: 200,
                                            minValue: 0,
                                            maxValue: goalAmount ?? 10,
                                            value: progressValue,
                                            graphColor: const [
                                              myBlue30,
                                              myBlue60
                                            ],
                                            pointerColor: theme.brightness ==
                                                    Brightness.dark
                                                ? myGrey10
                                                : myGrey90,
                                            hasIconPointer: false,
                                            animationDuration: 1000,
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () =>
                                                    _showWeightActionDialog(),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: myBlue30,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: myBlue60
                                                            .withOpacity(0.3),
                                                        blurRadius: 8,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Container(
                                                    margin:
                                                        const EdgeInsets.all(3),
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: myBlue60,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.add,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 0),
                                ],
                              ),
                            ],
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

  String _getLocalizedDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;

    // Get localized day name
    String dayName = '';
    switch (date.weekday) {
      case DateTime.monday:
        dayName = l10n.monday_date;
        break;
      case DateTime.tuesday:
        dayName = l10n.tuesday_date;
        break;
      case DateTime.wednesday:
        dayName = l10n.wednesday_date;
        break;
      case DateTime.thursday:
        dayName = l10n.thursday_date;
        break;
      case DateTime.friday:
        dayName = l10n.friday_date;
        break;
      case DateTime.saturday:
        dayName = l10n.saturday_date;
        break;
      case DateTime.sunday:
        dayName = l10n.sunday_date;
        break;
    }

    // Get localized month name
    String monthName = '';
    switch (date.month) {
      case 1:
        monthName = l10n.january_date;
        break;
      case 2:
        monthName = l10n.february_date;
        break;
      case 3:
        monthName = l10n.march_date;
        break;
      case 4:
        monthName = l10n.april_date;
        break;
      case 5:
        monthName = l10n.may_date;
        break;
      case 6:
        monthName = l10n.june_date;
        break;
      case 7:
        monthName = l10n.july_date;
        break;
      case 8:
        monthName = l10n.august_date;
        break;
      case 9:
        monthName = l10n.september_date;
        break;
      case 10:
        monthName = l10n.october_date;
        break;
      case 11:
        monthName = l10n.november_date;
        break;
      case 12:
        monthName = l10n.december_date;
        break;
    }

    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  PreferredSize _buildCustomAppBarForWeb(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.of(context).size.width;
    final showButtonText = width > 900;
    final showSearchBar = width > 500;

    final searchController = TextEditingController();

    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Bar - Only show if width > 500
            if (showSearchBar) ...[
              Expanded(
                child: CustomSearchBar(
                  controller: searchController,
                  onChanged: (value) {
                    // Implement search functionality
                    debugPrint('Searching: $value');
                  },
                  hintText: l10n.search_activities_messages,
                ),
              ),
              const SizedBox(width: 16),
            ],
            // Schedule Session Button
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SelectWorkoutToStartPage(),
                  ),
                );
              },
              child: Container(
                height: 48,
                //width: showButtonText ? null : 48,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: myBlue60,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: myBlue60.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.start_workout,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildLeftNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int count = 0,
    bool isSelected = false,
  }) {
    final isActionIcon =
        icon == Icons.notifications || icon == Icons.message_rounded;

    return InkWell(
      onTap: () {
        onTap();
        // Reset custom page when clicking nav items
        setState(() {
          _currentPage = const ClientDashboard();
        });
      },
      child: Container(
        width: double.infinity,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Stack(
          children: [
            if (isSelected)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Center(
                        child: Container(
                          width: isActionIcon ? 24 : null,
                          height: isActionIcon ? 24 : null,
                          padding: EdgeInsets.zero,
                          alignment: Alignment.center,
                          decoration: isActionIcon
                              ? BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white70,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                )
                              : null,
                          child: Icon(
                            icon,
                            color: isSelected ? Colors.white : Colors.white70,
                            size: isActionIcon ? 14 : 24,
                          ),
                        ),
                      ),
                      if (count > 0)
                        Positioned(
                          right: isActionIcon ? 0 : -4,
                          top: isActionIcon ? 0 : -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: myRed50,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              count.toString(),
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_isLeftSidebarExpanded)
                    Flexible(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        opacity: _isLeftSidebarExpanded ? 1.0 : 0.0,
                        child: Container(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            label,
                            style: GoogleFonts.plusJakartaSans(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildSwitchToTrainerButton() {
    final l10n = AppLocalizations.of(context)!;
    final myIsWebOrDektop = isWebOrDesktopCached;

    return GestureDetector(
      onTap: () async {
        debugPrint('Switching to trainer profile');
        final userProvider = context.read<UserProvider>();
        final linkedTrainerId = userProvider.userData?['linkedTrainerId'];

        if (linkedTrainerId != null) {
          try {
            // Show loading screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FullScreenLoading(),
              ),
            );

            // Get client data from Firestore
            final clientDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(linkedTrainerId)
                .get();

            if (clientDoc.exists) {
              final clientData = clientDoc.data()!;

              // Clear existing trainer data
              userProvider.clearAllData();

              // Set new client data
              userProvider.setUserData({
                ...clientData,
                'userId': linkedTrainerId,
                'role': 'trainer',
              });

              // Fetch client-specific data
              await DataFetchService().fetchUserData(
                linkedTrainerId,
                'trainer',
                context,
              );

              // Navigate to client home page
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => myIsWebOrDektop
                        ? const WebCoachSide()
                        : const CoachSide(),
                  ),
                  (route) => false,
                );
              }
            } else {
              Navigator.pop(context); // Remove loading screen
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  CustomSnackBar.show(
                    title: 'Trainer Profile',
                    message: l10n.trainer_profile_not_found,
                    type: SnackBarType.error,
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('Error switching to trainer profile: $e');
            Navigator.pop(context); // Remove loading screen
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                CustomSnackBar.show(
                  title: 'Trainer Profile',
                  message: l10n.failed_switch_profile,
                  type: SnackBarType.error,
                ),
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            CustomSnackBar.show(
              title: 'Trainer Profile',
              message: l10n.no_trainer_profile,
              type: SnackBarType.error,
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              myBlue50,
              myBlue40,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: myBlue50.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.switch_account,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.switch_to_trainer,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 16,
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
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          //color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Icon with colored background
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: getIconColor(icon).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: getIconColor(icon),
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            // Label
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: theme.brightness == Brightness.dark
                      ? myGrey10
                      : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Chevron
            Card(
              margin: const EdgeInsets.only(left: 8),
              color:
                  theme.brightness == Brightness.dark ? myGrey70 : Colors.white,
              elevation: 2,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Icon(
                  Icons.chevron_right,
                  color:
                      theme.brightness == Brightness.dark ? myGrey10 : myGrey60,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get icon colors
  Color getIconColor(IconData icon) {
    if (icon == Icons.add_outlined) {
      return myPurple60; // Coral color for add client
    } else if (icon == Icons.edit_outlined) {
      return myYellow50; // Purple for workout plan
    }
    return myBlue60; // Default color
  }
}

class FullScreenLoading extends StatelessWidget {
  const FullScreenLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor:
          theme.brightness == Brightness.light ? Colors.white : myGrey80,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: myBlue60),
            const SizedBox(height: 16),
            Text(
              l10n.switching_to_trainer,
              style: GoogleFonts.plusJakartaSans(
                color:
                    theme.brightness == Brightness.light ? myGrey60 : myGrey10,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
