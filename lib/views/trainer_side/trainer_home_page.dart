import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/auth/bloc/data_fetch_service.dart';
import 'package:naturafit/services/auth/bloc/my_auth_bloc.dart';
import 'package:naturafit/services/notification_service.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/views/client_side/client_notification_page.dart';
import 'package:naturafit/views/client_side/client_side.dart';
import 'package:naturafit/views/shared_side/messages_page.dart';
import 'package:naturafit/views/trainer_side/active_clients_page.dart';
import 'package:naturafit/views/trainer_side/active_meal_plans_page.dart';
import 'package:naturafit/views/trainer_side/active_plans_page.dart';
import 'package:naturafit/views/trainer_side/add_client_page.dart';
import 'package:naturafit/views/trainer_side/available_slots_page.dart';
import 'package:naturafit/views/shared_side/create_meal_plan_page.dart';
import 'package:naturafit/views/trainer_side/create_workout_plan_page.dart';
import 'package:naturafit/views/trainer_side/generate_invitation_link.dart';
import 'package:naturafit/views/trainer_side/schedule_session_page.dart';
import 'package:naturafit/views/trainer_side/session_details_page.dart';
import 'package:naturafit/views/trainer_side/sessions_calendar_view.dart';
import 'package:naturafit/views/trainer_side/todays_sessions.dart';
import 'package:naturafit/views/trainer_side/trainer_invitation_page.dart';
import 'package:naturafit/views/trainer_side/trainer_profile_page.dart';
import 'package:naturafit/views/trainer_side/trainer_settings_page.dart';
import 'package:naturafit/views/web/web_client_side.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:naturafit/widgets/custom_user_profile_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/services/firebase_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:naturafit/views/web/web_coach_side.dart';
import 'package:naturafit/widgets/web_stat_card.dart';
import 'package:naturafit/widgets/web_upcoming_sessions_card.dart';

class ClientSession {
  final String name;
  final String nextSession;
  final String status;

  ClientSession({
    required this.name,
    required this.nextSession,
    required this.status,
  });
}

class FullScreenLoading extends StatelessWidget {
  const FullScreenLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: myBlue60),
            const SizedBox(height: 16),
            Text(
              l10n.switching_to_client,
              style: GoogleFonts.plusJakartaSans(
                color: myGrey60,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrainerDashboard extends StatefulWidget {
  const TrainerDashboard({super.key});

  @override
  State<TrainerDashboard> createState() => _TrainerDashboardState();
}

class _TrainerDashboardState extends State<TrainerDashboard>
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

  final List<ClientSession> clients = [
    ClientSession(
      name: "Sarah Johnson",
      nextSession: "Today, 2:00 PM",
      status: "Confirmed",
    ),
    ClientSession(
      name: "Mike Peters",
      nextSession: "Tomorrow, 10:00 AM",
      status: "Pending",
    ),
    ClientSession(
      name: "Emma Wilson",
      nextSession: "Today, 4:30 PM",
      status: "Confirmed",
    ),
  ];

  String _getCurrentDate() {
    return DateFormat('E, dd MMM yyyy').format(DateTime.now());
  }

  PreferredSize _buildCustomAppBar(
    BuildContext context,
    Map<String, dynamic> userData,
    int unreadNotifications,
    UserProvider userProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final myIsWebOrDektop = isWebOrDesktopCached;
    return PreferredSize(
      preferredSize: const Size.fromHeight(170),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: myBlue60,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: myBlue60.withOpacity(0.1),
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
                //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('E, dd MMM yyyy').format(DateTime.now()),
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
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
                                color: myRed50,
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
                            color: Colors.white,
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
                          await NotificationService().markAllNotificationsAsRead(userData['userId']);
                          
                          
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
                      margin: const EdgeInsets.all(1.5),
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
                        width: 190,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                '${l10n.hi}, ${(userData[fbFullName] ?? userData[fbRandomName]) ?? 'User'}!',
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
                              '👋',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 0),
                      GestureDetector(
                        onTap: () async {
                          debugPrint('Switching to client profile');
                          final userProvider = context.read<UserProvider>();
                          final trainerClientId =
                              userProvider.userData?['trainerClientId'];

                          if (trainerClientId != null) {
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
                              final clientDoc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(trainerClientId)
                                  .get();

                              if (clientDoc.exists) {
                                final clientData = clientDoc.data()!;

                                // Clear existing trainer data
                                userProvider.clearAllData();

                                // Set new client data
                                userProvider.setUserData({
                                  ...clientData,
                                  'userId': trainerClientId,
                                  'role': 'client',
                                });

                                // Fetch client-specific data
                                await DataFetchService().fetchUserData(
                                  trainerClientId,
                                  'client',
                                  context,
                                );

                                // Navigate to client home page
                                if (context.mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => myIsWebOrDektop
                                          ? const WebClientSide()
                                          : const ClientSide(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              } else {
                                Navigator.pop(context); // Remove loading screen
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    CustomSnackBar.show(
                                      title: l10n.client,
                                      message: l10n.client_profile_not_found,
                                      type: SnackBarType.error,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              debugPrint(
                                  'Error switching to client profile: $e');
                              Navigator.pop(context); // Remove loading screen
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  CustomSnackBar.show(
                                    title: l10n.client,
                                    message:
                                        l10n.failed_to_switch_to_client_profile,
                                    type: SnackBarType.error,
                                  ),
                                );
                              }
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              CustomSnackBar.show(
                                title: l10n.client,
                                message: l10n
                                    .no_client_profile_associated_with_this_account,
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
                                l10n.switch_to_client,
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
                      /*
                      Container(
                        padding: const EdgeInsets.symmetric(
                          //horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          //color: myYellow40,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 20, color: myYellow30),
                            const SizedBox(width: 4),
                            Text(
                              'Pro Member',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      */
                    ],
                  ),
                  const Spacer(),

/*
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TrainerProfilePage(),
                        ),
                      );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: myBlue50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_outline, size: 18, color: Colors.white),
                    ),
                  )
                  */

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GenerateInviteLinkPage(),
                        ),
                      );
                    },
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: myBlue50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            l10n.add_new_client_button,
                            style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.person_add,
                              size: 18, color: Colors.white),
                        ],
                      ),
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

  Map<String, Color> getStatusColor(bool isGroup, String? status) {
    if (isGroup && status != 'cancelled') {
      return {
        'backgroundColor': myPurple60,
        'textColor': Colors.white,
      };
    }

    switch (status?.toLowerCase()) {
      case fbClientConfirmedStatus:
      case fbCreatedStatusForNotAppUser:
        return {
          'backgroundColor': myBlue50,
          'textColor': Colors.white,
        };
      case fbCreatedStatusForAvailableSlot:
        return {
          'backgroundColor': myGreen50,
          'textColor': Colors.white,
        };
      case fbCreatedStatusForAppUser:
        return {
          'backgroundColor': myYellow50,
          'textColor': Colors.white,
        };
      case fbCancelledStatus:
        return {
          'backgroundColor': myRed50,
          'textColor': Colors.white,
        };
      case 'requested':
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

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.userData == null) {
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
        final l10n = AppLocalizations.of(context)!;
        final activeClientsLength = userProvider.partiallyTotalClients
                ?.where((client) => (client['status'] == 'active' ||
                    client['status'] == 'confirmed'))
                .length ??
            0;
        final availableSlots = userProvider.availableFutureSlots?.length ?? 0;
        final activeWorkoutsLength = userProvider.workoutPlans
                ?.where((workout) => (workout['status'] == 'active' ||
                    workout['status'] == 'confirmed' ||
                    workout['status'] == 'current'))
                .length ??
            0;
        final activeMealsLength = userProvider.mealPlans
                ?.where((meal) => (meal['status'] == 'active' ||
                    meal['status'] == 'confirmed' ||
                    meal['status'] == 'current'))
                .length ??
            0;

        final notificationsCount =
            userProvider.unreadNotifications?.length ?? 0;

        debugPrint('Dont remove this line');

        final theme = Theme.of(context);

        final myIsWebOrDektop = isWebOrDesktopCached;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: myIsWebOrDektop
              ? null
              : _buildCustomAppBar(
                  context, userData, notificationsCount, userProvider),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //const SizedBox(height: 12),
                    if (myIsWebOrDektop) ...[
                      // Web layout
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Row(
                          children: [
                            Expanded(
                              child: WebStatCard(
                                context: context,
                                icon: Icons.groups,
                                title: l10n.active_clients_web,
                                value: activeClientsLength.toString(),
                                color: myBlue60,
                                description:
                                    l10n.clients_currently_training_with_you,
                                onTap: () {
                                  final webCoachState =
                                      context.findAncestorStateOfType<
                                          WebCoachSideState>();
                                  if (webCoachState != null) {
                                    webCoachState.setState(() {
                                      webCoachState.setCurrentPage(
                                          const ActiveClientsPage(),
                                          'ActiveClientsPage');
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: WebStatCard(
                                context: context,
                                icon: Icons.event_available,
                                title: l10n.available_slots_web,
                                value: availableSlots.toString(),
                                color: myTeal30,
                                description: l10n.slots_available_for_booking,
                                onTap: () {
                                  final webCoachState =
                                      context.findAncestorStateOfType<
                                          WebCoachSideState>();
                                  if (webCoachState != null) {
                                    webCoachState.setState(() {
                                      webCoachState.setCurrentPage(
                                          const AvailableSlotsPage(),
                                          'AvailableSlotsPage');
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
                                title: l10n.meal_plans_web,
                                value: activeMealsLength.toString(),
                                color: myGreen50,
                                description: l10n
                                    .personalized_nutrition_plans_in_progress,
                                onTap: () {
                                  final webCoachState =
                                      context.findAncestorStateOfType<
                                          WebCoachSideState>();
                                  if (webCoachState != null) {
                                    webCoachState.setState(() {
                                      webCoachState.setCurrentPage(
                                          const ActiveMealPlansPage(),
                                          'ActiveMealPlansPage');
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
                                title: l10n.workout_plans_web,
                                value: activeWorkoutsLength.toString(),
                                color: myRed50,
                                description:
                                    l10n.training_programs_being_followed,
                                onTap: () {
                                  final webCoachState =
                                      context.findAncestorStateOfType<
                                          WebCoachSideState>();
                                  if (webCoachState != null) {
                                    webCoachState.setState(() {
                                      webCoachState.setCurrentPage(
                                          const ActiveWorkoutPlansPage(),
                                          'ActiveWorkoutPlansPage');
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Existing mobile GridView
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
                            icon: Icons.groups,
                            title: l10n.active_clients_mobile,
                            value: activeClientsLength.toString(),
                            color: myBlue60,
                          ),
                          /*
                          _buildStatCard(
                            context: context,
                            icon: Icons.calendar_today,
                            title: "Today's Sessions",
                            value: todaySlots.toString(),
                            color: myTeal30,
                          ),
                          */
                          _buildStatCard(
                            context: context,
                            icon: Icons.event_available,
                            title: l10n.available_slots_mobile,
                            value: availableSlots.toString(),
                            color: myTeal30,
                          ),
                          _buildStatCard(
                            context: context,
                            icon: Icons.restaurant_menu,
                            title: l10n.meal_plans_mobile,
                            value: activeMealsLength.toString(),
                            color: myGreen50, // Green color for nutrition
                          ),
                          _buildStatCard(
                            context: context,
                            icon: Icons.fitness_center,
                            title: l10n.workout_plans_mobile,
                            value: activeWorkoutsLength.toString(),
                            color: myRed50,
                          ),

                          /*
                          _buildStatCard(
                            context: context,
                            icon: Icons.fitness_center,
                            title: 'TEST123',
                            value: activeWorkoutsLength.toString(),
                            color: myRed50,
                          ),
                          */
                          /*
                          _buildStatCard(
                            context: context,
                            icon: Icons.attach_money,
                            title: 'Monthly Revenue',
                            value: '\$3.2K',
                            color: myRed50, // Green color for money
                          ),
                          */
                        ],
                      ),
                    ],

                    /*
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.person_add,
                            label: 'Add\nNew Client',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const AddClientPage()), //GenerateInviteLinkPage()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.calendar_month,
                            label: 'Schedule\nSession',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ScheduleSessionPage() // Will use default 'existing_client'
                                    ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.fitness_center,
                            label: 'Create\nWorkout Plan',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const CreateWorkoutPlanPage()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.food_bank,
                            label: 'Create\nMeal Plan',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const CreateMealPlanPage()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    */

                    const SizedBox(height: 24),
                    if (myIsWebOrDektop)
                      _buildUpcomingSessionsCardForWeb(context, userData)
                    else
                      _buildUpcomingSessionsCard(context),
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
    return InkWell(
      onTap: () {
        final l10n = AppLocalizations.of(context)!;
        if (title == l10n.active_clients_mobile) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ActiveClientsPage()),
          );
        } else if (title == l10n.available_slots_mobile) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AvailableSlotsPage()),
          );
        } else if (title == l10n.workout_plans_mobile) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ActiveWorkoutPlansPage()),
          );
        } else if (title == l10n.meal_plans_mobile) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ActiveMealPlansPage()),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    //color: theme.brightness == Brightness.dark ? myGrey10 : theme.textTheme.headlineSmall?.color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.2,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingSessionsCard(BuildContext context) {
    final upcomingSessions =
        context.watch<UserProvider>().threeUpcomingSessions ?? [];
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.upcoming_sessions_title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  color: theme.textTheme.titleLarge?.color,
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
                    color: theme.disabledColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.no_upcoming_sessions_empty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.disabledColor,
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

  Widget _buildUpcomingSessionsCardForWeb(BuildContext context, userData) {
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
                //_buildSessionCardForWeb(context, session, upcomingSessions)),
                WebUpcomingSessionsCard(
                  session: session,
                  upcomingSessions: upcomingSessions,
                  userData: userData,
                )),
        ],
      ),
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
      default:
        return l10n.status_pending;
    }
  }

  Widget _buildSessionCard(BuildContext context, Map<String, dynamic> session,
      List<Map<String, dynamic>> upcomingSessions) {
    final theme = Theme.of(context);
    final userData = context.read<UserProvider>().userData;
    final l10n = AppLocalizations.of(context)!;
    if (userData == null) return const SizedBox.shrink();

    final isGroup = session['isGroupSession'] ?? false;
    final isAvailable = session['status'] == fbCreatedStatusForAvailableSlot;
    final isRequested = session['status'] == 'requested';
    final sessionDate = (session['sessionDate'] as Timestamp).toDate();
    final formattedDate = DateFormat('E, MMM d').format(sessionDate);

    // Get client info with proper field names
    final String clientName =
        session['clientFullname']?.toString().isNotEmpty == true
            ? session['clientFullname']
            : session['clientUsername'] ?? 'Client';
    final String? profileImageUrl = session['clientProfileImageUrl'];

    // Get initial for avatar - safely handle empty strings
    final String clientInitial =
        clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C';

    // For group sessions
    final List<dynamic> groupClients = session['clients'] ?? [];
    final int groupSize = groupClients.length;

    return Column(
      children: [
        InkWell(
          onTap: () async {
            debugPrint('=== MOBILE SESSION CARD TAP ===');
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SessionDetailsPage(
                  sessionId: session['sessionId'],
                  trainerId: userData['userId'],
                ),
              ),
            );
            debugPrint('Mobile session card result: $result');
            
            if (result != null &&
                result is Map<String, dynamic> &&
                (result['deleted'] == true ||
                    result['cancelled'] == true ||
                    result['edited'] == true)) {
              if (context.mounted) {
                debugPrint('Refreshing professional slots in mobile view');
                await DataFetchService().fetchProfessionalSlots(
                    userData['userId'],
                    'trainer',
                    context.read<UserProvider>());
              }
            }
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
                else if (isAvailable || isRequested)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: myGrey30,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  )
                else if (profileImageUrl != null &&
                    profileImageUrl != 'null' &&
                    profileImageUrl != '')
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: profileImageUrl.toString().startsWith('assets/')
                          ? myAvatarBackground
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: profileImageUrl.toString().startsWith('assets/')
                          ? Image.asset(
                              profileImageUrl,
                              fit: BoxFit.cover,
                            )
                          : CachedNetworkImage(
                              imageUrl: profileImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: myGrey20,
                                child: const Center(
                                  child: CircularProgressIndicator(color: myGrey30),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: myGrey20,
                                child: const Icon(Icons.person_outline, color: myGrey60),
                              ),
                            ),
                          
                    ),
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light
                          ? myGrey30
                          : myGrey80,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        clientInitial,
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
                        isGroup
                            ? l10n.group_session_count(groupSize)
                            : isAvailable
                                ? l10n.available_slot
                                : isRequested
                                    ? l10n.available_slot
                                    : clientName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$formattedDate at ${session['time']}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session['sessionCategory'] ?? l10n.training_session,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (session['status']?.toLowerCase() == 'requested')
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
                        isGroup && session['status'] != 'cancelled'
                            ? l10n.group
                            : getLocalizedStatus(context, session['status'])
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
                      isGroup && session['status'] != 'cancelled'
                          ? l10n.group
                          : getLocalizedStatus(context, session['status'])
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
            color: theme.dividerColor,
            height: 1,
          ),
      ],
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
    final formattedDate = DateFormat('E, MMM d').format(sessionDate);
    final formattedDay = DateFormat('dd').format(sessionDate);
    final formattedMonth = DateFormat('MMM').format(sessionDate);
    final formattedDayName = DateFormat('EEEE').format(sessionDate);

    final width = MediaQuery.of(context).size.width;
    // Responsive breakpoints
    final isVerySmall = width < 600;
    final isSmall = width < 800;
    final isMedium = width < 1200;
    final showSideBars = width > 1000;
    final canExpandLeftBar = width > 700;

    // Get user's time format preference
    final is24Hour = userData['timeFormat'] == '24-hour';

    // Format time based on preference
    final timeFormat = is24Hour ? 'HH:mm' : 'h:mm a';
    final formattedTime = DateFormat(timeFormat).format(sessionDate);

    // Get client info with proper field names
    final String clientName =
        session['clientFullname']?.toString().isNotEmpty == true
            ? session['clientFullname']
            : session['clientUsername'] ?? 'Client';
    final String? profileImageUrl = session['clientProfileImageUrl'];

    // Get initial for avatar - safely handle empty strings
    final String clientInitial =
        clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C';

    // For group sessions
    final List<dynamic> groupClients = session['clients'] ?? [];
    final int groupSize = groupClients.length;

    return Column(
      children: [
        InkWell(
          onTap: () async {
            debugPrint('=== WEB SESSION CARD TAP ===');
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SessionDetailsPage(
                  sessionId: session['sessionId'],
                  trainerId: userData['userId'],
                ),
              ),
            );
            debugPrint('Web session card result: $result');
            
            if (result != null &&
                result is Map<String, dynamic> &&
                (result['deleted'] == true ||
                    result['cancelled'] == true ||
                    result['edited'] == true)) {
              if (context.mounted) {
                debugPrint('Refreshing professional slots in web view');
                await DataFetchService().fetchProfessionalSlots(
                    userData['userId'],
                    'trainer',
                    context.read<UserProvider>());
              }
            }
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
                  else if (profileImageUrl != null &&
                      profileImageUrl != 'null' &&
                      profileImageUrl != '')
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: profileImageUrl.toString().startsWith('assets/')
                            ? myAvatarBackground
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: profileImageUrl.toString().startsWith('assets/')
                            ? Image.asset(
                                profileImageUrl,
                                fit: BoxFit.cover,
                              )
                            : CachedNetworkImage(
                                imageUrl: profileImageUrl,
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
                          clientInitial,
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
                                    : clientName,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(
                        isGroup, session['status'])['backgroundColor'],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isGroup && session['status'] != 'cancelled'
                        ? l10n.group
                        : getLocalizedStatus(context, session['status'])
                            .toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isSmall ? 10 : 12,
                      color: getStatusColor(
                          isGroup, session['status'])['textColor'],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
}
