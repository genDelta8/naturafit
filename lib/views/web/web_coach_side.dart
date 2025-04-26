import 'dart:math';
import 'package:naturafit/services/invitation/invitation_bloc.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/views/all_shared_settings/help_center_page.dart';
import 'package:naturafit/views/shared_side/create_meal_plan_page.dart';
import 'package:naturafit/views/trainer_side/add_client_page.dart';
import 'package:naturafit/views/trainer_side/create_workout_plan_page.dart';
import 'package:naturafit/views/trainer_side/resources_page.dart';
import 'package:naturafit/views/trainer_side/schedule_session_page.dart';
import 'package:naturafit/views/trainer_side/trainer_home_page.dart';
import 'package:naturafit/views/trainer_side/trainer_profile_page.dart';
import 'package:naturafit/views/trainer_side/trainer_settings_page.dart';
import 'package:naturafit/views/trainer_side/weekly_schedule_page.dart';
import 'package:naturafit/views/web/web_client_side.dart';
import 'package:naturafit/widgets/custom_search_bar.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/auth/bloc/data_fetch_service.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/views/client_side/client_notification_page.dart';
import 'package:naturafit/views/client_side/client_side.dart';
import 'package:naturafit/views/shared_side/messages_page.dart';
import 'package:naturafit/views/trainer_side/generate_invitation_link.dart';
import 'package:naturafit/widgets/custom_user_profile_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:naturafit/services/notification_service.dart';

class WebCoachSide extends StatefulWidget {
  const WebCoachSide({super.key});

  @override
  State<WebCoachSide> createState() => WebCoachSideState();
}

class WebCoachSideState extends State<WebCoachSide> {
  int _currentIndex = 0;
  bool _isLeftSidebarExpanded = false;
  
  // Add this variable to hold custom pages
  Widget _currentPage = const TrainerDashboard();

  final List<Widget> _pages = [
    const TrainerDashboard(),
    const WeeklySchedulePage(),
    const ResourcesPage(),
    const TrainerProfilePage(),
    const NotificationsPage(),
    const MessagesPage(),
  ];

  // Add this method to allow setting custom pages
  void setCurrentPage(Widget page, String pageName) {
    setState(() {
      _currentPage = page;
      if (pageName == 'MessagesPage') {
        _currentIndex = 5; // Use -1 to indicate custom page
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

  void _handleNotificationClick() async {
    final userProvider = context.read<UserProvider>();
    final userData = userProvider.userData;
    
    if (userData != null) {
      setState(() {
          _currentIndex = 4;
        });
      try {
        // Mark notifications as read
        await NotificationService().markAllNotificationsAsRead(userData['userId']);
        
        // Update state to show notifications page
        
        
        // Refresh unread notifications in UserProvider
        if (mounted) {
          userProvider.setUnreadNotifications([]);
        }
      } catch (e) {
        debugPrint('Error handling notification click: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final userProvider = context.watch<UserProvider>();
    final userData = userProvider.userData;
    final unreadNotifications = userProvider.unreadNotifications?.length ?? 0;
    final width = MediaQuery.of(context).size.width;
    
    // Responsive breakpoints
    final isVerySmall = width < 600;
    final isSmall = width < 800;
    final isMedium = width < 1200;
    final showSideBars = width > 1000;
    final canExpandLeftBar = width > 700;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocListener<InvitationBloc, InvitationState>(
        listener: (context, state) {
          if (state is InvitationGenerated) {
            _showInvitationDialog(context, state);
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Navigation Bar - only show if not very small
            if (!isVerySmall)
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 72,
                maxWidth: 210,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isLeftSidebarExpanded = canExpandLeftBar),
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
                    child: SingleChildScrollView( // Add SingleChildScrollView
                      child: ConstrainedBox( // Add ConstrainedBox for minimum height
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height - 48, // 48 for padding
                        ),
                        child: IntrinsicHeight( // Wrap with IntrinsicHeight
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 0),
                            child: Column(
                              children: [
                                // Top Actions
                                Column(
                                  children: [
                                    _buildLeftNavItem(
                                      icon: Icons.notifications,
                                      label: l10n.notifications,
                                      count: unreadNotifications,
                                      isSelected: _currentIndex == 4,
                                      onTap: _handleNotificationClick,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildLeftNavItem(
                                      icon: Icons.message_rounded,
                                      label: l10n.messages,
                                      count: userProvider.unreadMessageCount,
                                      isSelected: _currentIndex == 5,
                                      onTap: () => setState(() => _currentIndex = 5),
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
                                        onTap: () => setState(() => _currentIndex = 0),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildLeftNavItem(
                                        icon: Icons.event_available,
                                        label: l10n.slots,
                                        isSelected: _currentIndex == 1,
                                        onTap: () => setState(() => _currentIndex = 1),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildLeftNavItem(
                                        icon: Icons.library_books_outlined,
                                        label: l10n.library,
                                        isSelected: _currentIndex == 2,
                                        onTap: () => setState(() => _currentIndex = 2),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildLeftNavItem(
                                        icon: Icons.person_outline,
                                        label: l10n.profile,
                                        isSelected: _currentIndex == 3,
                                        onTap: () => setState(() => _currentIndex = 3),
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
                                      builder: (context) => const TrainerSettingsPage(),
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
                                        builder: (context) => const HelpCenterPage(),
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
                children: [
                  _buildCustomAppBarForWeb(context, isSmall),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(isSmall ? 12.0 : 24.0),
                      child: currentPage,
                    ),
                  ),
                ],
              ),
            ),
        
            // Right Sidebar - only show if enough space
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
                                          size: 16, color: theme.brightness == Brightness.dark ? myGrey10 : myGrey60),
                                      const SizedBox(width: 8),
                                      Text(
                                        _getLocalizedDate(context, DateTime.now()),
                                        style: GoogleFonts.plusJakartaSans(
                                          color: theme.brightness == Brightness.dark ? myGrey10 : myGrey60,
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
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Container(
                                          margin: const EdgeInsets.all(1.5),
                                          width: 56,
                                          height: 56,
                                          child: CustomUserProfileImage(
                                            imageUrl: userData?['profileImageUrl'],
                                            name: userData?[fbFullName] ??
                                                userData?[fbRandomName] ??
                                                'User',
                                            size: 64,
                                            borderRadius: 12,
                                            backgroundColor: theme.brightness == Brightness.dark ? myGrey70 : myGrey30,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Name and Switch Button Column
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  '${l10n.hi},',
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Text(
                                                  '👋',
                                                  style: TextStyle(fontSize: 16),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              (userData?[fbFullName] ??
                                                      userData?[fbRandomName]) ??
                                                  'User',
                                              style: theme.textTheme.titleMedium?.copyWith(
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
                                  _buildSwitchToClientButton(),
                                  const SizedBox(height: 64),
                                ],
                              ),
                              
                              const Expanded(child: SizedBox()),
                              
                              // Bottom Actions
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildActionButton(
                                    icon: Icons.person_add,
                                    label: l10n.add_new_client_manually_web_button,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AddClientPage(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildActionButton(
                                    icon: Icons.fitness_center,
                                    label: l10n.create_workout_plan_web_button,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const CreateWorkoutPlanPage(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildActionButton(
                                    icon: Icons.restaurant_menu,
                                    label: l10n.create_meal_plan,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const CreateMealPlanPage(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  _buildInvitationLinkButton(),
                                  const SizedBox(height: 24),
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
      ),
    );
  }

  void _showInvitationDialog(BuildContext context, InvitationGenerated state) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: theme.brightness == Brightness.dark ? myGrey60 : myGrey30),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            color: theme.cardColor,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: 400,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with close button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.share_invitation,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: theme.brightness == Brightness.dark ? Colors.white : myGrey80,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color: theme.brightness == Brightness.dark ? Colors.white70 : myGrey60,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Message
                      Text(
                        l10n.share_link_message,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          color: theme.brightness == Brightness.dark ? Colors.white70 : myGrey60,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Link Container
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark ? myGrey70 : myGrey10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.brightness == Brightness.dark ? myGrey60 : myGrey30,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                state.webLink,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: theme.brightness == Brightness.dark ? Colors.white : myGrey80,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                final message = '''${l10n.coachtrack_invitation}

${l10n.join_me_on_coachtrack}

${l10n.click_here_to_join}
${state.webLink}

${l10n.or_enter_this_invitation_code}
${state.inviteCode}

${l10n.dont_have_the_app_yet}
${l10n.android_store_link(state.androidStoreLink)}
${l10n.ios_store_link(state.iOSStoreLink)}''';

                        Clipboard.setData(ClipboardData(text: message));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  CustomSnackBar.show(
                                    title: l10n.invitation_link,
                                    message: l10n.copied_to_clipboard,
                                    type: SnackBarType.success,
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.copy,
                                size: 20,
                                color: theme.brightness == Brightness.dark ? Colors.white70 : myGrey60,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Share buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // WhatsApp button
                          OutlinedButton.icon(
                            onPressed: () => _shareLink(state, 'whatsapp', context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              side: const BorderSide(color: Colors.green),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.message, color: Colors.green, size: 20),
                            label: Text(
                              l10n.whatsapp,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Share button
                          ElevatedButton.icon(
                            onPressed: () => _shareLink(state, 'share', context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: myBlue60,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.share, color: Colors.white, size: 20),
                            label: Text(
                              l10n.share,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _shareLink(InvitationGenerated state, String method, BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final message = '''${l10n.coachtrack_invitation}

${l10n.join_me_on_coachtrack}

${l10n.click_here_to_join}
${state.webLink}

${l10n.or_enter_this_invitation_code}
${state.inviteCode}

${l10n.dont_have_the_app_yet}
${l10n.android_store_link(state.androidStoreLink)}
${l10n.ios_store_link(state.iOSStoreLink)}''';
    /*
    final message = l10n.join_message(
      state.webLink,
      state.androidStoreLink,
      state.iOSStoreLink,
    );
    */

    switch (method) {
      case 'whatsapp':
        if (kIsWeb) {
          // Use web.whatsapp.com URL for web platform
          final webWhatsappUrl = "https://web.whatsapp.com/send?text=${Uri.encodeComponent(message)}";
          await launchUrl(
            Uri.parse(webWhatsappUrl),
            mode: LaunchMode.platformDefault,
          );
        } else {
          // Use whatsapp:// scheme for mobile platforms
          final whatsappUrl = "whatsapp://send?text=${Uri.encodeComponent(message)}";
          if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
            await launchUrl(Uri.parse(whatsappUrl));
          }
        }
        break;
      case 'share':
        await Share.share(message);
        break;
    }
  }

  PreferredSize _buildCustomAppBarForWeb(BuildContext context, bool isSmall) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.of(context).size.width;

    // Responsive breakpoints
    final isVerySmall = width < 600;
    
    final searchController = TextEditingController();
    
    return PreferredSize(
      preferredSize: Size.fromHeight(isSmall ? 60 : 80),
      child: Container(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Bar - Only show if width > 500
            if (!isVerySmall) ...[
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
              SizedBox(width: isSmall ? 8 : 16),
            ],
            // Schedule Session Button
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScheduleSessionPage(initialSessionCategory: l10n.assessment),
                  ),
                );
              },
              child: Container(
                height: 48,
                //width: showButtonText ? null : (isSmall ? 40 : 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: myBlue60,
                  borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
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
                        Icons.calendar_month,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                        Text(
                          l10n.schedule_session_web,
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
          _currentPage = const TrainerDashboard();
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
                            maxLines: 1,
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

  Widget _buildSwitchToClientButton() {
    final l10n = AppLocalizations.of(context)!;
    final userProvider = context.read<UserProvider>();
    final myIsWebOrDektop = isWebOrDesktopCached;

    return GestureDetector(
      onTap: () async {
        debugPrint('Switching to client profile');
        final trainerClientId = userProvider.userData?['trainerClientId'];

        if (trainerClientId != null) {
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
                    builder: (context) => myIsWebOrDektop ? const WebClientSide() : const ClientSide(),
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
            debugPrint('Error switching to client profile: $e');
            Navigator.pop(context); // Remove loading screen
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                CustomSnackBar.show(
                  title: l10n.client,
                  message: l10n.failed_to_switch_to_client_profile,
                  type: SnackBarType.error,
                ),
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            CustomSnackBar.show(
              title: l10n.client,
              message: l10n.no_client_profile_associated_with_this_account,
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
                l10n.switch_to_client,
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

  Widget _buildInvitationLinkButton() {
    final l10n = AppLocalizations.of(context)!;
    final userProvider = context.read<UserProvider>();
    final userData = userProvider.userData;
    return GestureDetector(
      onTap: () {
        // Handle tap
                                      debugPrint('Generate Invitation Link');
                                      if (userData != null) {
                                        debugPrint(
                                            'userId: ${userData['userId']}');
                                        context.read<InvitationBloc>().add(
                                              GenerateInvitation(
                                                trainerClientId:
                                                    userData['trainerClientId'] ?? '',
                                                professionalId:
                                                    userData['userId'] ?? '',
                                                professionalUsername:
                                                    userData[fbRandomName] ??
                                                        'User',
                                                professionalFullName: userData[
                                                        fbFullName] ??
                                                    userData[fbRandomName] ??
                                                    'User',
                                                professionalProfileImageUrl:
                                                    userData[
                                                            fbProfileImageURL] ??
                                                        '',
                                                role: userData['role'] ?? '',
                                              ),
                                            );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          CustomSnackBar.show(
                                            title: l10n.generate_invitation_link,
                                            message: l10n.user_data_not_available,
                                            type: SnackBarType.error,
                                          ),
                                        );
                                      }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              myBlue60,
              myBlue50,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: myBlue60.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.link_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.generate,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.generate_invitation_link,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.generate_invitation_link_description,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
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
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 800;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: isSmall ? 12 : 16,
          horizontal: isSmall ? 8 : 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmall ? 6 : 8),
              decoration: BoxDecoration(
                color: getIconColor(icon).withOpacity(0.1),
                borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
              ),
              child: Icon(
                icon,
                color: getIconColor(icon),
                size: isSmall ? 20 : 24,
              ),
            ),
            if (!isSmall) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    color: theme.brightness == Brightness.dark 
                      ? myGrey10 
                      : Colors.black87,
                    fontSize: isSmall ? 14 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.only(left: 8),
                color: theme.brightness == Brightness.dark 
                  ? myGrey70 
                  : Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isSmall ? 2 : 4),
                  child: Icon(
                    Icons.chevron_right,
                    color: theme.brightness == Brightness.dark 
                      ? myGrey10 
                      : myGrey60,
                    size: isSmall ? 16 : 20,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method to get icon colors
  Color getIconColor(IconData icon) {
    if (icon == Icons.person_add) {
      return myBlue60; // Coral color for add client
    } else if (icon == Icons.fitness_center) {
      return myRed50; // Purple for workout plan
    } else if (icon == Icons.restaurant_menu) {
      return myGreen50; // Blue for meal plan
    }
    return myBlue60; // Default color
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
}

class FullScreenLoading extends StatelessWidget {
  const FullScreenLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light ? Colors.white : myGrey80,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: myBlue60),
            const SizedBox(height: 16),
            Text(
              l10n.switching_to_client,
              style: GoogleFonts.plusJakartaSans(
                color: theme.brightness == Brightness.light ? myGrey60 : myGrey10,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
