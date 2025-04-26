
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/auth/bloc/data_fetch_service.dart';
import 'package:naturafit/services/auth/bloc/my_auth_bloc.dart';
import 'package:naturafit/services/invitation/connections_bloc.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/views/client_side/book_session_page.dart';
import 'package:naturafit/views/client_side/client_meal/client_meal_plans_page.dart';
import 'package:naturafit/views/client_side/client_notification_page.dart';
import 'package:naturafit/views/client_side/client_profile_page.dart';
import 'package:naturafit/views/client_side/client_progress_page.dart';
import 'package:naturafit/views/client_side/client_meal/client_current_meal_plan.dart';
import 'package:naturafit/views/client_side/client_session_details_page.dart';
import 'package:naturafit/views/client_side/client_weekly_schedule_page.dart';
import 'package:naturafit/views/client_side/client_workout/client_workout_plans_page.dart';
import 'package:naturafit/views/client_side/your_team_page.dart';
import 'package:naturafit/views/shared_side/messages_page.dart';
import 'package:naturafit/views/trainer_side/coach_side.dart';
import 'package:naturafit/views/trainer_side/session_details_page.dart';
import 'package:naturafit/views/trainer_side/trainer_profile_page.dart';
import 'package:naturafit/views/trainer_side/trainer_settings_page.dart';
import 'package:naturafit/views/web/web_client_side.dart';
import 'package:naturafit/views/web/web_coach_side.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:naturafit/widgets/custom_user_profile_image.dart';
import 'package:naturafit/widgets/web_stat_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/views/client_side/client_workout/select_workout_to_start_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:naturafit/services/notification_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WorkoutSession {
  final String type;
  final String dateTime;
  final String trainerName;
  final String status;

  WorkoutSession({
    required this.type,
    required this.dateTime,
    required this.trainerName,
    required this.status,
  });
}

class FullScreenLoading extends StatelessWidget {
  const FullScreenLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: theme.brightness == Brightness.light ? myBlue60 : myBlue40,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.loading_trainer_profile,
              style: GoogleFonts.plusJakartaSans(
                color:
                    theme.brightness == Brightness.light ? myGrey60 : myGrey30,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _blinkAnimation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(_blinkController);

    _blinkController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  String formatTimeUntilSession(DateTime sessionTime) {
    final now = DateTime.now();
    final difference = sessionTime.difference(now);
    final l10n = AppLocalizations.of(context)!;

    if (difference.inDays == 0) return l10n.today;
    if (difference.inDays == 1) return l10n.tomorrow;
    return l10n.in_days(difference.inDays);
  }

  PreferredSize _buildCustomAppBar(
      BuildContext context,
      Map<String, dynamic> userData,
      int unreadNotifications,
      UserProvider userProvider) {
    final myIsWebOrDektop = isWebOrDesktopCached;
    final l10n = AppLocalizations.of(context)!;
    return PreferredSize(
      preferredSize: const Size.fromHeight(170),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: myBlue60, //const Color(0xFF1E293B),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: myBlue10),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('E, dd MMM yyyy').format(DateTime.now()),
                        style: GoogleFonts.plusJakartaSans(
                          color: myBlue10,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MessagesPage(),
                        ),
                      );
                    },
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        //vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: myBlue50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (userProvider.unreadMessageCount > 0) ...[
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 255, 87, 87),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                userProvider.unreadMessageCount.toString(),
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          const Icon(
                            Icons.message_rounded,
                            color: myBlue10,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final userProvider = context.read<UserProvider>();
                      final userData = userProvider.userData;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsPage(),
                        ),
                      );

                      if (userData != null) {
                        try {
                          // Mark notifications as read
                          await NotificationService()
                              .markAllNotificationsAsRead(userData['userId']);

                          // Update unread notifications in UserProvider
                          if (context.mounted) {
                            userProvider.setUnreadNotifications([]);
                          }
                        } catch (e) {
                          debugPrint('Error handling notification click: $e');
                        }
                      }
                    },
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        //vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: myBlue50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (unreadNotifications > 0) ...[
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: myRed50,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unreadNotifications.toString(),
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      width: 56,
                      height: 56,
                      child: CustomUserProfileImage(
                        imageUrl: userData['profileImageUrl'],
                        name: userData[fbFullName] ??
                            userData[fbRandomName] ??
                            'User',
                        size: 56,
                        borderRadius: 12,
                        backgroundColor: myBlue40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 230,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                l10n.hi_user(userData['fullName'] ??
                                    userData[fbRandomName] ??
                                    'User'),
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '💪',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(children: [
                        if (userData['isTrainerClientProfile'] == true) ...[
                          GestureDetector(
                            onTap: () async {
                              debugPrint('Switching to client profile');
                              final userProvider = context.read<UserProvider>();
                              final linkedTrainerId =
                                  userProvider.userData?['linkedTrainerId'];

                              if (linkedTrainerId != null) {
                                try {
                                  // Show loading screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const FullScreenLoading(),
                                    ),
                                  );

                                  // Get client data from Firestore
                                  final clientDoc = await FirebaseFirestore
                                      .instance
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
                                    Navigator.pop(
                                        context); // Remove loading screen
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        CustomSnackBar.show(
                                          title: l10n.error,
                                          message:
                                              l10n.trainer_profile_not_found,
                                          type: SnackBarType.error,
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  debugPrint(
                                      'Error switching to trainer profile: $e');
                                  Navigator.pop(
                                      context); // Remove loading screen
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      CustomSnackBar.show(
                                        title: l10n.error,
                                        message: l10n.failed_switch_profile,
                                        type: SnackBarType.error,
                                      ),
                                    );
                                  }
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  CustomSnackBar.show(
                                    title: l10n.error,
                                    message: l10n.no_trainer_profile,
                                    type: SnackBarType.error,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: myBlue50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.switch_account,
                                      size: 18, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.switch_to_trainer,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        /*
                      else ...[
                        Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 0,
                        ),
                        decoration: BoxDecoration(
                          //color: myGreen50, //const Color.fromARGB(255, 89, 200, 61),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flash_on,
                                size: 16, color: myYellow30),
                            const SizedBox(width: 0),
                            Text(
                              l10n.active_member,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ]
                      */

                        GestureDetector(
                          onTap: () async {
                            _showEnterInvitationCodeDialog();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: myBlue50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.key_rounded,
                                    size: 18, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  userData['isTrainerClientProfile'] == true
                                      ? l10n.code
                                      : l10n.invitation_code,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ClientProfilePage(),
                        ),
                      );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: myBlue50,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.person_outline,
                          size: 18, color: myBlue10),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.userData == null) {
          // Check auth state when data is null
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AuthBloc>().add(CheckAuthStatus(context));
          });

          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: myBlue60),
            ),
          );
        }

        final userData = userProvider.userData!;
        final activeProfessionals = userProvider.partiallyTotalProfessionals
                ?.where((professional) =>
                    professional['status'] == fbClientConfirmedStatus)
                .length ??
            0;
        final notificationsCount =
            userProvider.unreadNotifications?.length ?? 0;

        final theme = Theme.of(context);

        final myIsWebOrDektop = isWebOrDesktopCached;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: myIsWebOrDektop
              ? null
              : _buildCustomAppBar(
                  context,
                  userData,
                  notificationsCount,
                  userProvider,
                ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (myIsWebOrDektop) ...[
                      // Web layout
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Row(
                          children: [
                            Expanded(
                              child: WebStatCard(
                                context: context,
                                icon: Icons.group_rounded,
                                title: l10n.my_team,
                                value: activeProfessionals.toString(),
                                color: myBlue60,
                                description:
                                    l10n.trainers_currently_training_with_you,
                                onTap: () {
                                  final webClientState =
                                      context.findAncestorStateOfType<
                                          WebClientSideState>();
                                  if (webClientState != null) {
                                    webClientState.setState(() {
                                      webClientState.setCurrentPage(
                                          const YourTeamPage(), 'YourTeamPage');
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: WebStatCard(
                                context: context,
                                icon: Icons.insert_chart,
                                title: l10n.progress,
                                value: 'Soon',
                                color: myTeal30,
                                description: l10n
                                    .track_your_fitness_journey_and_achievements,
                                onTap: () {
                                  final webClientState =
                                      context.findAncestorStateOfType<
                                          WebClientSideState>();
                                  if (webClientState != null) {
                                    webClientState.setState(() {
                                      webClientState.setCurrentPage(
                                          const ProgressPage(), 'ProgressPage');
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: WebStatCard(
                                context: context,
                                icon: Icons.restaurant_menu,
                                title: l10n.meal_plans,
                                value: (context
                                            .watch<UserProvider>()
                                            .mealPlans
                                            ?.where((plan) =>
                                                plan['status'] == 'active' ||
                                                plan['status'] == 'current' ||
                                                plan['status'] == 'confirmed')
                                            .length ??
                                        0)
                                    .toString(),
                                color: myGreen50,
                                description: l10n
                                    .personalized_nutrition_plans_in_progress,
                                onTap: () {
                                  final webClientState =
                                      context.findAncestorStateOfType<
                                          WebClientSideState>();
                                  if (webClientState != null) {
                                    webClientState.setState(() {
                                      webClientState.setCurrentPage(
                                          const ClientMealPlansPage(),
                                          'ClientMealPlansPage');
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: WebStatCard(
                                context: context,
                                icon: Icons.fitness_center,
                                title: l10n.workout_plans,
                                value: (context
                                            .watch<UserProvider>()
                                            .workoutPlans
                                            ?.where((plan) =>
                                                plan['status'] == 'active' ||
                                                plan['status'] == 'current' ||
                                                plan['status'] == 'confirmed')
                                            .length ??
                                        0)
                                    .toString(),
                                color: myRed50,
                                description: l10n
                                    .personalized_nutrition_plans_in_progress,
                                onTap: () {
                                  final webClientState =
                                      context.findAncestorStateOfType<
                                          WebClientSideState>();
                                  if (webClientState != null) {
                                    webClientState.setState(() {
                                      webClientState.setCurrentPage(
                                          const ClientWorkoutPlansPage(),
                                          'ClientWorkoutPlansPage');
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          _buildStatCard(
                            context: context,
                            icon: Icons.group_rounded,
                            title: l10n.my_team,
                            value: activeProfessionals.toString(),
                            color: myBlue60,
                          ),
                          _buildStatCard(
                            context: context,
                            icon: Icons.insert_chart,
                            title: l10n.progress,
                            value: 'Soon',
                            color: myTeal30,
                          ),
                          _buildStatCard(
                            context: context,
                            icon: Icons.restaurant_menu,
                            title: l10n.meal_plans,
                            value: (context
                                        .watch<UserProvider>()
                                        .mealPlans
                                        ?.where((plan) =>
                                            plan['status'] == 'active' ||
                                            plan['status'] == 'current' ||
                                            plan['status'] == 'confirmed')
                                        .length ??
                                    0)
                                .toString(),
                            color: myGreen50,
                          ),
                          _buildStatCard(
                            context: context,
                            icon: Icons.fitness_center,
                            title: l10n.workout_plans,
                            value: (context
                                        .watch<UserProvider>()
                                        .workoutPlans
                                        ?.where((plan) =>
                                            plan['status'] == 'active' ||
                                            plan['status'] == 'current' ||
                                            plan['status'] == 'confirmed')
                                        .length ??
                                    0)
                                .toString(),
                            color: myRed50,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (myIsWebOrDektop)
                      _buildUpcomingSessionsCardForWeb(context)
                    else
                      _buildUpcomingSessionsCard(context),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: title == l10n.workout_plans
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => title == l10n.workout_plans
                      ? const ClientWorkoutPlansPage()
                      : const CurrentMealPlanPage(),
                ),
              )
          : title == l10n.my_team
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const YourTeamPage()),
                  )
              : title == l10n.meal_plans
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ClientMealPlansPage(),
                        ),
                      )
                  : title == l10n.progress
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ProgressPage()),
                          )
                      : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.light ? Colors.white : myGrey90,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: theme.brightness == Brightness.light
                    ? Colors.grey[600]
                    : Colors.grey[300],
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardForWeb({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required String description,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        final webClientState =
            context.findAncestorStateOfType<WebClientSideState>();
        final l10n = AppLocalizations.of(context)!;
        if (title == l10n.my_team) {
          if (webClientState != null) {
            webClientState.setState(() {
              webClientState.setCurrentPage(
                  const YourTeamPage(), 'YourTeamPage');
            });
          }
        } else if (title == l10n.workout_plans_web) {
          if (webClientState != null) {
            webClientState.setState(() {
              webClientState.setCurrentPage(
                  const ClientWorkoutPlansPage(), 'ClientWorkoutPlansPage');
            });
          }
        } else if (title == l10n.meal_plans_web) {
          if (webClientState != null) {
            webClientState.setState(() {
              webClientState.setCurrentPage(
                  const ClientMealPlansPage(), 'ClientMealPlansPage');
            });
          }
        } else if (title == l10n.progress) {
          if (webClientState != null) {
            webClientState.setState(() {
              webClientState.setCurrentPage(
                  const ProgressPage(), 'ProgressPage');
            });
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40, // Fixed height for description area
              child: Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: myGrey60,
                  fontSize: 14,
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
    final l10n = AppLocalizations.of(context)!;
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 0, 102, 255),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSessionsCard(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final upcomingSessions =
        context.watch<UserProvider>().threeUpcomingSessions ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light ? Colors.white : myGrey90,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.upcoming_sessions,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (upcomingSessions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 48,
                    color: theme.brightness == Brightness.light
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.no_upcoming_sessions_message,
                    style: GoogleFonts.plusJakartaSans(
                      color: theme.brightness == Brightness.light
                          ? Colors.grey[600]
                          : Colors.grey[300],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ...upcomingSessions.map((session) =>
                _buildSessionCard(context, session, upcomingSessions)),
        ],
      ),
    );
  }

  TimeOfDay _parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeByPreference(String time24h, String timeFormat) {
    final timeOfDay = _parseTimeString(time24h);
    if (timeFormat == '24-hour') {
      return time24h; // Already in 24h format
    } else {
      // Convert to 12h format with AM/PM
      final hour = timeOfDay.hourOfPeriod;
      final minute = timeOfDay.minute.toString().padLeft(2, '0');
      final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
      return '${hour == 0 ? 12 : hour}:$minute $period';
    }
  }

  Widget _buildUpcomingSessionsCardForWeb(BuildContext context) {
    final upcomingSessions =
        context.watch<UserProvider>().threeUpcomingSessions ?? [];
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: myYellow50.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: myYellow50,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.upcoming_sessions_title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      fontSize: 24,
                    ),
                  ),
                  /*
                  const SizedBox(height: 4),
                  Text(
                    'Next 3 training sessions',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: myGrey60,
                      fontSize: 14,
                    ),
                  ),
                  */
                ],
              ),
            ],
          ),
          const SizedBox(height: 48),
          if (upcomingSessions.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: theme.disabledColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.no_upcoming_sessions_empty,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.disabledColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  /*
                  Text(
                    'Schedule your first session to get started',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: myGrey60,
                    ),
                  ),
                  */
                ],
              ),
            )
          else
            ...upcomingSessions.map((session) =>
                _buildSessionCardForWeb(context, session, upcomingSessions)),
        ],
      ),
    );
  }

  String getLocalizedDayName(BuildContext context, String dayName) {
    final l10n = AppLocalizations.of(context)!;
    switch (dayName) {
      case 'Monday':
        return l10n.monday;
      case 'Tuesday':
        return l10n.tuesday;
      case 'Wednesday':
        return l10n.wednesday;
      case 'Thursday':
        return l10n.thursday;
      case 'Friday':
        return l10n.friday;
      case 'Saturday':
        return l10n.saturday;
      case 'Sunday':
        return l10n.sunday;
      default:
        return dayName;
    }
  }

  String getLocalizedMonthName(BuildContext context, String monthName) {
    final l10n = AppLocalizations.of(context)!;
    switch (monthName) {
      case 'Jan':
        return l10n.january_date;
      case 'Feb':
        return l10n.february_date;
      case 'Mar':
        return l10n.march_date;
      case 'Apr':
        return l10n.april_date;
      case 'May':
        return l10n.may_date;
      case 'Jun':
        return l10n.june_date;
      case 'Jul':
        return l10n.july_date;
      case 'Aug':
        return l10n.august_date;
      case 'Sep':
        return l10n.september_date;
      case 'Oct':
        return l10n.october_date;
      case 'Nov':
        return l10n.november_date;
      case 'Dec':
        return l10n.december_date;
      default:
        return monthName;
    }
  }

  Widget _buildSessionCardForWeb(
      BuildContext context,
      Map<String, dynamic> session,
      List<Map<String, dynamic>> upcomingSessions) {
    final theme = Theme.of(context);
    final userData = context.read<UserProvider>().userData;
    final l10n = AppLocalizations.of(context)!;
    if (userData == null) return const SizedBox.shrink();

    final isGroup = session['isGroupSession'] ?? false;
    final isAvailable = session['status'] == fbCreatedStatusForAvailableSlot;
    final isRequested = session['status'] == 'requested';
    final sessionDate = (session['sessionDate'] as Timestamp).toDate();
    final formattedDay = DateFormat('dd').format(sessionDate);
    final formattedMonth = DateFormat('MMM').format(sessionDate);
    final formattedDayName = DateFormat('EEEE').format(sessionDate);
    //final formattedTime = session['time'];

    // Get trainer info with proper field names matching the database
    final String trainerName =
        session['professionalFullname']?.toString().isNotEmpty == true
            ? session['professionalFullname']
            : session['professionalUsername'] ?? 'Coach';
    final String? trainerProfileImageUrl =
        session['professionalProfileImageUrl'];

    // Get initial for avatar - safely handle empty strings
    final String trainerInitial =
        trainerName.isNotEmpty ? trainerName[0].toUpperCase() : 'C';

    // For group sessions
    final List<dynamic> groupClients = session['clients'] ?? [];
    final int groupSize = groupClients.length;

    final is24Hour = userData['timeFormat'] == '24-hour';

    // Format time based on preference
    final timeFormatToPass = is24Hour ? 'HH:mm' : 'h:mm a';
    final formattedTime = DateFormat(timeFormatToPass).format(sessionDate);

    final width = MediaQuery.of(context).size.width;
    // Responsive breakpoints
    final isSmall = width < 800;
    final isMedium = width < 1200;

    // Before the Row's children list, add these declarations
    final statusWidget = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: getStatusColor(isGroup, session['status'])['backgroundColor'],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isGroup && session['status'] != 'cancelled'
            ? l10n.group
            : getLocalizedStatus(context, session['status']).toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: isSmall ? 10 : 12,
          color: getStatusColor(isGroup, session['status'])['textColor'],
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    final statusBadge = isRequested
        ? FadeTransition(
            opacity: _blinkAnimation,
            child: statusWidget,
          )
        : statusWidget;

    return Column(
      children: [
        InkWell(
          onTap: () {
            debugPrint('MY Session ID: ${session['sessionId']}');
            debugPrint('MY Trainer ID: ${session['professionalId']}');
            debugPrint('MY Group Session: $isGroup');
            debugPrint('MY Client ID: ${userData['userId']}');

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClientSessionDetailsPage(
                  clientId: userData['userId'],
                  sessionId: session[
                      'sessionId'], // Use the professional's ID for client view
                  isGroupSession: isGroup,
                  passedTrainerId: session['professionalId'],
                  isProfessionalAvailableSlot: isGroup ? true : false,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Date and Time Row
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Date
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            formattedDay,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.brightness == Brightness.light
                                  ? myGrey90
                                  : Colors.white,
                            ),
                          ),
                          Text(
                            getLocalizedMonthName(context, formattedMonth)
                                .toUpperCase(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.brightness == Brightness.light
                                  ? myGrey90
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Time
                      if (!isMedium)
                        Column(
                          children: [
                            Text(
                              getLocalizedDayName(context, formattedDayName),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.brightness == Brightness.light
                                    ? myGrey90
                                    : Colors.white,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                //color: myGrey90,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: theme.brightness == Brightness.light
                                        ? myGrey90
                                        : Colors.white,
                                    width: 1),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: theme.brightness == Brightness.light
                                        ? myGrey90
                                        : Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    formattedTime,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          theme.brightness == Brightness.light
                                              ? myGrey90
                                              : Colors.white,
                                      fontSize: 16,
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
                const SizedBox(width: 20),

                // Keep existing avatar code
                if (!isMedium) ...[
                  if (isGroup)
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.light
                            ? myGrey30
                            : myGrey80,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.groups,
                        color: Colors.white,
                      ),
                    )
                  else if (isAvailable || isRequested)
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.light
                            ? myGrey30
                            : myGrey80,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                    )
                  else if (trainerProfileImageUrl != null &&
                      trainerProfileImageUrl != 'null' &&
                      trainerProfileImageUrl != '')
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: trainerProfileImageUrl
                                .toString()
                                .startsWith('assets/')
                            ? myAvatarBackground
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: trainerProfileImageUrl
                                .toString()
                                .startsWith('assets/')
                            ? Image.asset(
                                trainerProfileImageUrl,
                                fit: BoxFit.cover,
                              )
                            : CachedNetworkImage(
                                imageUrl: trainerProfileImageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: myGrey20,
                                  child: const Center(
                                    child: CircularProgressIndicator(color: myGrey30),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: myGrey20,
                                  child: const Icon(
                                    Icons.person_outline,
                                    color: myGrey60,
                                  ),
                                ),
                              ),
                            
                      ),
                    )
                  else
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.light
                            ? myGrey30
                            : myGrey80,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          trainerInitial,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 20),
                ],

                // Client Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGroup
                            ? l10n.group_session_count(groupSize)
                            : isAvailable
                                ? l10n.available_slot
                                : isRequested
                                    ? l10n.available_slot
                                    : trainerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session['sessionCategory'] ?? l10n.training_session,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: myGrey60,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                statusBadge,
              ],
            ),
          ),
        ),
        if (upcomingSessions.last != session)
          Divider(
            color: theme.dividerColor,
            height: 1,
          ),
      ],
    );
  }

  String getLocalizedStatus(BuildContext context, String? status) {
    final l10n = AppLocalizations.of(context)!;

    switch (status?.toLowerCase()) {
      case fbClientConfirmedStatus:
      case fbCreatedStatusForNotAppUser:
        return l10n.status_confirmed;
      case fbCreatedStatusForAvailableSlot:
        return l10n.status_available;
      case fbCreatedStatusForAppUser:
        return l10n.status_pending;
      case fbCancelledStatus:
        return l10n.status_cancelled;
      case 'requested':
        return l10n.status_requested;
      case 'withdrawn':
        return l10n.status_withdrawn;
      case 'rejected':
        return l10n.status_rejected;
      default:
        return l10n.status_pending;
    }
  }

  Widget _buildSessionCard(BuildContext context, Map<String, dynamic> session,
      List<Map<String, dynamic>> upcomingSessions) {
    final isGroup = session['isGroupSession'] ?? false;
    final sessionDate = (session['sessionDate'] as Timestamp).toDate();
    final formattedDate = DateFormat('E, MMM d').format(sessionDate);
    final userData = context.read<UserProvider>().userData;
    final displayTime = _formatTimeByPreference(
        session['time'], userData?['timeFormat'] ?? '12-hour');
    final status = session['status']?.toLowerCase();
    final isRequested = status == fbRequestedStatus;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Get trainer info with proper field names matching the database
    final String trainerName =
        session['professionalFullname']?.toString().isNotEmpty == true
            ? session['professionalFullname']
            : session['professionalUsername'] ?? 'Coach';
    final String? trainerProfileImageUrl =
        session['professionalProfileImageUrl'];

    // Get initial for avatar - safely handle empty strings
    final String trainerInitial =
        trainerName.isNotEmpty ? trainerName[0].toUpperCase() : 'C';

    return Column(
      children: [
        InkWell(
          onTap: () {
            final userData = context.read<UserProvider>().userData;
            if (userData == null) return;
            debugPrint('MY Session ID: ${session['sessionId']}');
            debugPrint('MY Trainer ID: ${session['professionalId']}');
            debugPrint('MY Group Session: $isGroup');
            debugPrint('MY Client ID: ${userData['userId']}');

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClientSessionDetailsPage(
                  clientId: userData['userId'],
                  sessionId: session[
                      'sessionId'], // Use the professional's ID for client view
                  isGroupSession: isGroup,
                  passedTrainerId: session['professionalId'],
                  isProfessionalAvailableSlot: isGroup ? true : false,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                if (isGroup)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: myGrey30,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.groups,
                      color: Colors.white,
                    ),
                  )
                else if (trainerProfileImageUrl != null &&
                    trainerProfileImageUrl != 'null' &&
                    trainerProfileImageUrl != '')
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: trainerProfileImageUrl
                              .toString()
                              .startsWith('assets/')
                          ? myAvatarBackground
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: trainerProfileImageUrl
                              .toString()
                              .startsWith('assets/')
                          ? Image.asset(
                              trainerProfileImageUrl,
                              fit: BoxFit.cover,
                            )
                          : CachedNetworkImage(
                                imageUrl: trainerProfileImageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: myGrey20,
                                  child: const Center(
                                    child: CircularProgressIndicator(color: myGrey30),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: myGrey20,
                                  child: const Icon(
                                    Icons.person_outline,
                                    color: myGrey60,
                                  ),
                                ),
                              ), 
                          
                    ),
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: myGrey30,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        trainerInitial,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGroup ? 'Group Session' : trainerName,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$formattedDate at $displayTime',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session['sessionCategory'] ?? 'Training Session',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isRequested)
                  FadeTransition(
                    opacity: _blinkAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: getStatusColor(
                            isGroup, session['status'])['backgroundColor'],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isGroup
                            ? l10n.group
                            : session['status'] == 'withdrawn'
                                ? l10n.withdrawn
                                : session['status'] == 'rejected'
                                    ? l10n.declined
                                    : (session['status'] ?? 'PENDING')
                                        .toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: getStatusColor(
                              isGroup, session['status'])['textColor'],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: getStatusColor(
                          isGroup, session['status'])['backgroundColor'],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isGroup
                          ? l10n.group
                          : session['status'] == 'withdrawn'
                              ? l10n.withdrawn
                              : session['status'] == 'rejected'
                                  ? l10n.declined
                                  : (session['status'] ?? 'PENDING')
                                      .toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: getStatusColor(
                            isGroup, session['status'])['textColor'],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (upcomingSessions.last != session)
          Divider(
            color: theme.brightness == Brightness.light
                ? Colors.grey[200]
                : Colors.grey[800],
            height: 1,
          ),
      ],
    );
  }

  Map<String, Color> getStatusColor(bool isGroup, String? status) {
    if (isGroup) {
      return {
        'backgroundColor': myPurple60,
        'textColor': Colors.white,
      };
    }

    switch (status?.toLowerCase()) {
      case 'group':
        return {
          'backgroundColor': myPurple60,
          'textColor': Colors.white,
        };
      case fbClientConfirmedStatus:
      case fbCreatedStatusForNotAppUser:
      case 'booked':
        return {
          'backgroundColor': myBlue50,
          'textColor': Colors.white,
        };
      case fbCreatedStatusForAppUser:
        return {
          'backgroundColor': myYellow50,
          'textColor': Colors.white,
        };
      case fbCancelledStatus:
      case 'withdrawn':
      case 'rejected':
        return {
          'backgroundColor': myRed50,
          'textColor': Colors.white,
        };
      case fbRequestedStatus:
        return {
          'backgroundColor': myRed40,
          'textColor': Colors.white,
        };
      default:
        return {
          'backgroundColor': myYellow50,
          'textColor': Colors.white,
        };
    }
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
                      setState(() {});
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
                                final userId = userProvider.userData?['userId'];
                                final userRole = userProvider.userData?['role'];
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

                                // Validate that trainer is not trying to connect with themselves
                                if (inviteData['trainerClientId'] == userId) {
                                  throw l10n.cannot_connect_with_yourself;
                                }

                                if (inviteData['used'] == true) {
                                  throw l10n.invitation_code_already_used;
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
                                  'professionalId':
                                      inviteData['professionalId'],
                                  'professionalUsername':
                                      inviteData['professionalUsername'],
                                  'professionalFullName':
                                      inviteData['professionalFullName'],
                                  'professionalProfileImageUrl':
                                      inviteData[fbProfileImageURL],
                                  'role': inviteData['role'],
                                  'status': fbClientConfirmedStatus,
                                  'timestamp':
                                      DateTime.now().millisecondsSinceEpoch,
                                };

                                final currentProfessionals =
                                    List<Map<String, dynamic>>.from(userProvider
                                            .partiallyTotalProfessionals ??
                                        []);
                                currentProfessionals.add(newProfessional);
                                userProvider.setPartiallyTotalProfessionals(
                                    currentProfessionals);

                                // Mark invitation as used
                                await FirebaseFirestore.instance
                                    .collection('invites')
                                    .doc(code)
                                    .update({'used': true});

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
}
