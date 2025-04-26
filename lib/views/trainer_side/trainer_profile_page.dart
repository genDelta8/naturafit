import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/unit_preferences.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/views/client_side/professional_slots_page.dart';
import 'package:naturafit/views/shared_side/direct_message_page.dart';
import 'package:naturafit/views/shared_side/messages_page.dart';
import 'package:naturafit/views/trainer_side/all_trainer_settings/trainer_account_settings_page.dart';
import 'package:naturafit/views/trainer_side/trainer_settings_page.dart';
import 'package:naturafit/views/web/web_coach_side.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:naturafit/widgets/custom_user_profile_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:naturafit/widgets/custom_loading_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TrainerProfilePage extends StatelessWidget {
  const TrainerProfilePage(
      {super.key,
      this.passedTrainer,
      this.isEnteredByClient = false,
      this.passedWidgetTrainer});

  final Map<String, dynamic>? passedTrainer;
  final bool isEnteredByClient;
  final Map<String, dynamic>? passedWidgetTrainer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double headerHeight = (screenWidth * (9 / 16));
    const double profileImageRadius = 60;

    final userData = isEnteredByClient
        ? passedTrainer
        : context.watch<UserProvider>().userData;
    //debugPrint('myuserData: $userData');

    if (userData == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: myBlue60),
        ),
      );
    }

    final myIsWebOrDektop = isWebOrDesktopCached;

    return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: !myIsWebOrDektop
            ? Stack(
                children: [
                  Column(
                    children: [
                      _buildHeader(context, headerHeight, profileImageRadius),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 80),
                              _buildNameAndBio(context, userData),
                              const SizedBox(height: 16),
                              _buildStatsSection(context),
                              const SizedBox(height: 16),
                              _buildSocialMediaSection(context, userData),
                              const SizedBox(height: 16),
                              _buildAvailableHoursSection(context, userData),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildProfileImage(
                      context, userData, headerHeight, profileImageRadius),
                ],
              )
            : SingleChildScrollView(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _buildHeader(context, headerHeight, profileImageRadius),
                        Column(
                          children: [
                            const SizedBox(height: 80),
                            _buildNameAndBio(context, userData),
                            const SizedBox(height: 16),
                            _buildStatsSection(context),
                            const SizedBox(height: 16),
                            _buildSocialMediaSection(context, userData),
                            const SizedBox(height: 16),
                            _buildAvailableHoursSection(context, userData),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ],
                    ),
                    _buildProfileImage(
                        context, userData, headerHeight, profileImageRadius),
                  ],
                ),
              ));
  }

  Widget _buildHeader(
      BuildContext context, double headerHeight, double profileImageRadius) {
    final theme = Theme.of(context);
    final userData = context.watch<UserProvider>().userData;
    final hasBackgroundImage = userData?['backgroundImageURL'] != null;
    final hasTempImage = userData?['tempBackgroundImagePath'] != null;
    final userProvider = context.read<UserProvider>();
    final l10n = AppLocalizations.of(context)!;

    const emptyWidth = 210 + 300 + 100;
    final screenWidth = MediaQuery.of(context).size.width;
    final webScreenWidth = screenWidth - emptyWidth;

    final isSmall = webScreenWidth * 0.8 < 400;

    final myHeaderWidth = isSmall ? 400.0 : webScreenWidth * 0.8;
    final myHeaderHeight = myHeaderWidth * (9 / 16);

    final myIsWebOrDektop = isWebOrDesktopCached;

    return Container(
      width: myIsWebOrDektop ? myHeaderWidth : double.infinity,
      height: myHeaderHeight,
      decoration: BoxDecoration(
        color: myGrey80,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        image: (hasTempImage || hasBackgroundImage)
            ? DecorationImage(
                image: hasTempImage
                    ? FileImage(File(userData!['tempBackgroundImagePath']!))
                    : NetworkImage(userData!['backgroundImageURL']!)
                        as ImageProvider,
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        children: [
          // Empty state UI (only show when no image)
          if (!hasBackgroundImage && !hasTempImage)
            Container(
              decoration: BoxDecoration(
                color:
                    theme.brightness == Brightness.light ? myGrey40 : myGrey80,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 40,
                      color: myGrey70,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.profile_background_photo,
                      style: GoogleFonts.plusJakartaSans(
                        color: myGrey70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.0),
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),

          // Header content
          Padding(
            padding: const EdgeInsets.only(top: 60, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: isEnteredByClient
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end,
              children: [
                if (isEnteredByClient)
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        icon: Icon(Icons.chevron_left,
                            color: Colors.white, size: 24),
                        onPressed: null,
                      ),
                    ),
                  ),
                if (!isEnteredByClient)
                  Row(
                    children: [
                      if (hasTempImage) ...[
                        // Save button for temp image
                        GestureDetector(
                          onTap: () =>
                              _saveBackgroundImage(context, userProvider),
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: myBlue60,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.save_button,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Remove temp image button
                        GestureDetector(
                          onTap: () => _removeBackgroundImage(
                              context, userProvider,
                              isTemp: true),
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: myRed50,
                              size: 20,
                            ),
                          ),
                        ),
                      ] else ...[
                        GestureDetector(
                          onTap: hasBackgroundImage
                              ? () => _showBackgroundImageOptions(
                                  context, userProvider)
                              : () =>
                                  _handleBackgroundImage(context, userProvider),
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.light
                                  ? myGrey70
                                  : Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              hasBackgroundImage
                                  ? Icons.edit
                                  : Icons.add_photo_alternate_outlined,
                              color: theme.brightness == Brightness.light
                                  ? myGrey40
                                  : Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(BuildContext context, Map<String, dynamic> userData,
      double headerHeight, double profileImageRadius) {
    final l10n = AppLocalizations.of(context)!;
    final String displayName =
        userData[fbFullName] ?? userData[fbRandomName] ?? 'T';
    final String initials =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T';

    const emptyWidth = 210 + 300 + 100;
    final screenWidth = MediaQuery.of(context).size.width;
    final webScreenWidth = screenWidth - emptyWidth;

    final isSmall = webScreenWidth * 0.8 < 400;
    final isSmallForButtons = webScreenWidth * 0.8 < 200;

    final spaceBetween = isSmallForButtons ? 16.0 : webScreenWidth * 0.1;

    final myHeaderWidth = isSmall ? 400.0 : webScreenWidth * 0.8;
    final myHeaderHeight = myHeaderWidth * (9 / 16);

    final myIsWebOrDektop = isWebOrDesktopCached;

    return Positioned(
      top: myHeaderHeight - profileImageRadius,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 45),
        child: Row(
          mainAxisAlignment: myIsWebOrDektop
              ? MainAxisAlignment.center
              : MainAxisAlignment.spaceBetween,
          children: [
            // Left button
            Container(
              width: profileImageRadius,
              height: profileImageRadius,
              decoration: BoxDecoration(
                color: myRed50,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.message_outlined, color: Colors.white),
                onPressed: () {
                  // Add your action here
                  final webCoachState =
                      context.findAncestorStateOfType<WebCoachSideState>();

                  if (isEnteredByClient) {
                    debugPrint('isEnteredByClient true');
                    final userProvider = context.read<UserProvider>();
                    final clientUserData = userProvider.userData;
                    final clientId = clientUserData?['userId'] ?? '';
                    final trainerClientId = userData['trainerClientId'];
                    final trainerId = userData['userId'];
                    if (trainerClientId == null) {
                      return;
                    }
                    if (trainerClientId == clientId) {
                      debugPrint('trainerClientId == clientId');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const MessagesPage(isVisitingProfile: true)),
                      );
                    } else {
                      debugPrint('trainerClientId != clientId');
                      final otherUserId = trainerId;
                      if (otherUserId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          CustomSnackBar.show(
                            title: l10n.direct_message,
                            message: l10n.invalid_chat_data,
                            type: SnackBarType.error,
                          ),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DirectMessagePage(
                            otherUserId: otherUserId,
                            otherUserName: userData[fbFullName] ?? 'Unknown',
                            chatType: 'client',
                            otherUserProfileImageUrl:
                                userData['profileImageUrl'] ?? '',
                          ),
                        ),
                      );
                    }
                  } else {
                    debugPrint('isEnteredByClient false');
                    if (webCoachState != null && myIsWebOrDektop) {
                      webCoachState.setState(() {
                        webCoachState.setCurrentPage(
                            const MessagesPage(), 'MessagesPage');
                      });
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MessagesPage()),
                      );
                    }
                  }

                },
              ),
            ),

            if (myIsWebOrDektop) SizedBox(width: spaceBetween),

            // Profile Image
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: profileImageRadius * 2,
                  height: profileImageRadius * 2,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CustomUserProfileImage(
                    imageUrl: userData['profileImageUrl'],
                    name: userData[fbFullName] ??
                        userData[fbRandomName] ??
                        'User',
                    size: profileImageRadius * 2,
                    borderRadius: 20,
                    backgroundColor: myGrey50,
                  ),
                ),
                if (!isEnteredByClient)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TrainerAccountSettingsPage(
                              initialFullName: userData[fbFullName] ?? '',
                              initialEmail: userData['email'] ?? '',
                              initialPhone: userData['phone'] ?? '',
                              initialLocation: userData['location'] ?? '',
                              initialProfileImageURL: userData['profileImageUrl'] ?? '',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: myGrey80,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            if (myIsWebOrDektop) SizedBox(width: spaceBetween),

            // Right button
            if (!isEnteredByClient)
              Container(
                width: profileImageRadius,
                height: profileImageRadius,
                decoration: BoxDecoration(
                  color: myBlue60,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TrainerSettingsPage()),
                    );
                  },
                ),
              ),
            if (isEnteredByClient)
              Container(
                width: profileImageRadius,
                height: profileImageRadius,
                decoration: BoxDecoration(
                  color: myBlue60,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.calendar_month_outlined,
                      color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfessionalSlotsPage(
                          professional: passedTrainer ?? {},
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

  Widget _buildNameAndBio(BuildContext context, Map<String, dynamic> userData) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final gender = userData['gender'];
    final localizedGender = gender == 'Male'
        ? l10n.male
        : gender == 'Other'
            ? l10n.other
            : l10n.female;

    int calculateAge(dynamic birthday) {
      //debugPrint('myBirthday: $birthday');
      if (birthday == null) return 0;

      try {
        DateTime birthDate;
        if (birthday is Timestamp) {
          // Handle Firebase Timestamp
          birthDate = birthday.toDate();
        } else if (birthday is Map<String, dynamic>) {
          // Handle Timestamp as map
          final seconds = birthday['_seconds'] as int;
          birthDate = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        } else {
          // Fallback to trying to parse as string if needed
          birthDate = DateTime.parse(birthday.toString());
        }

        final now = DateTime.now();
        int age = now.year - birthDate.year;

        // Adjust age if birthday hasn't occurred this year
        if (now.month < birthDate.month ||
            (now.month == birthDate.month && now.day < birthDate.day)) {
          age--;
        }

        //debugPrint('myAge: $age');
        return age;
      } catch (e) {
        debugPrint('Error calculating age: $e');
        return 0;
      }
    }

    // Get the calculated age
    final age = calculateAge(userData['birthday']);

    final myUserData = context.read<UserProvider>().userData;
    final unitPreferences = context.read<UnitPreferences>();
    final weightUnit = myUserData?['weightUnit'] ?? 'kg';
    final heightUnit = myUserData?['heightUnit'] ?? 'cm';

    final convertedWeight = weightUnit == 'kg'
        ? userData['weight']
        : unitPreferences.kgToLbs(userData['weight']);
    final convertedHeight = heightUnit == 'cm'
        ? userData['height']
        : unitPreferences.cmToft(userData['height']);

    final myIsWebOrDektop = isWebOrDesktopCached;

    return Column(
      children: [
        Text(
          userData[fbFullName] ?? userData[fbRandomName] ?? l10n.unknown,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        /*
        // Premium Member Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: myBlue60.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'PREMIUM MEMBER',
            style: GoogleFonts.plusJakartaSans(
              color: myBlue60,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        */
        //const SizedBox(height: 24),

        // Info Row
        Container(
          constraints: BoxConstraints(
            maxWidth: myIsWebOrDektop ? 600 : double.infinity,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(context, l10n.weight,
                    '${convertedWeight.round()}', weightUnit),
                Container(
                  width: 1,
                  height: 40,
                  color: theme.brightness == Brightness.light
                      ? myGrey20
                      : myGrey70,
                ),
                _buildInfoItem(context, l10n.age, '$age', 'y'),
                Container(
                  width: 1,
                  height: 40,
                  color: theme.brightness == Brightness.light
                      ? myGrey20
                      : myGrey70,
                ),
                _buildInfoItem(context, l10n.height,
                    '${convertedHeight.round()}', heightUnit),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Location and Gender Row
        if (userData['location'] != null || userData['gender'] != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (userData['gender'] != null) ...[
                Icon(
                  userData['gender'] == 'Male'
                      ? Icons.male_outlined
                      : Icons.female_outlined,
                  size: 16,
                  color: theme.brightness == Brightness.light
                      ? myGrey90
                      : Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  localizedGender,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.brightness == Brightness.light
                        ? myGrey90
                        : Colors.white70,
                  ),
                ),
              ],
              if (userData['location'] != null && userData['gender'] != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light
                          ? myGrey40
                          : myGrey60,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              if (userData['location'] != null) ...[
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: theme.brightness == Brightness.light
                      ? myGrey90
                      : Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  userData['location'],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.brightness == Brightness.light
                        ? myGrey90
                        : Colors.white70,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Bio
        if (userData['bio'] != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              userData['bio'],
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoItem(
      BuildContext context, String label, String value, String unit) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.brightness == Brightness.light
                    ? myGrey80
                    : Colors.white,
              ),
            ),
            Text(
              unit,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.brightness == Brightness.light
                    ? myGrey60
                    : Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.brightness == Brightness.light
                ? myGrey60
                : Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final userData = context.watch<UserProvider>().userData;
    final l10n = AppLocalizations.of(context)!;
    if (userData == null) return const SizedBox.shrink();

    // Get years of experience
    final yearsOfExperience = (userData['yearsOfExperience'] ?? 0).round();

    // Get specializations count
    final specializations =
        (userData['specializations'] as List<dynamic>?)?.length ?? 0;

    // Get experience list count
    final experienceList =
        (userData['experienceList'] as List<dynamic>?)?.length ?? 0;

    // Get education list count
    final educationList =
        (userData['education'] as List<dynamic>?)?.length ?? 0;

    final myIsWebOrDektop = isWebOrDesktopCached;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: myIsWebOrDektop
          ? Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildStatCardForWeb(
                      icon: Icons.fitness_center,
                      title: l10n.experience_title,
                      value: '$yearsOfExperience+',
                      subtitle: l10n.years,
                      color: myRed50,
                      context: context,
                      onTap: () {
                        debugPrint('Navigate to experience page');
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCardForWeb(
                      icon: Icons.star_border_rounded,
                      title: l10n.specializations,
                      value: specializations.toString(),
                      subtitle: l10n.areas,
                      color: myTeal30,
                      context: context,
                      onTap: () {
                        debugPrint('Navigate to specializations page');
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCardForWeb(
                      icon: Icons.work_outline_rounded,
                      title: l10n.work_history_title,
                      value: experienceList.toString(),
                      subtitle: l10n.positions,
                      color: myBlue60,
                      context: context,
                      onTap: () {
                        debugPrint('Navigate to work history page');
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCardForWeb(
                      icon: Icons.school_outlined,
                      title: l10n.education_title,
                      value: educationList.toString(),
                      subtitle: l10n.certificates,
                      color: myPurple60,
                      context: context,
                      onTap: () {
                        debugPrint('Navigate to education page');
                      },
                    ),
                  ),
                ],
              ),
            )
          : GridView.count(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard(
                  icon: Icons.fitness_center,
                  title: l10n.experience_title,
                  value: '$yearsOfExperience+',
                  subtitle: l10n.years,
                  color: myRed50,
                  context: context,
                  onTap: () {
                    // Navigate to experience page
                    debugPrint('Navigate to experience page');
                  },
                ),
                _buildStatCard(
                  icon: Icons.star_border_rounded,
                  title: l10n.specializations,
                  value: specializations.toString(),
                  subtitle: l10n.areas,
                  color: myTeal30,
                  context: context,
                  onTap: () {
                    // Navigate to specializations page
                    debugPrint('Navigate to specializations page');
                  },
                ),
                _buildStatCard(
                  icon: Icons.work_outline_rounded,
                  title: l10n.work_history_title,
                  value: experienceList.toString(),
                  subtitle: l10n.positions,
                  color: myBlue60,
                  context: context,
                  onTap: () {
                    // Navigate to work history page
                    debugPrint('Navigate to work history page');
                  },
                ),
                _buildStatCard(
                  icon: Icons.school_outlined,
                  title: l10n.education_title,
                  value: educationList.toString(),
                  subtitle: l10n.certificates,
                  color: myPurple60,
                  context: context,
                  onTap: () {
                    // Navigate to education page
                    debugPrint('Navigate to education page');
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
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
            Icon(icon, color: color),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w400,
                letterSpacing: -0.2,
              ),
            ),
            /*
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey[500],
                letterSpacing: -0.2,
              ),
            ),
            */
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardForWeb({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 16),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w400,
                letterSpacing: -0.2,
              ),
            ),
            /*
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey[500],
                letterSpacing: -0.2,
              ),
            ),
            */
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableHoursSection(
      BuildContext context, Map<String, dynamic> userData) {
    final theme = Theme.of(context);
    final Map<String, List<dynamic>> availableHours = {};
    final l10n = AppLocalizations.of(context)!;

    // Check if availableHours exists in userData
    if (userData['availableHours'] == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          elevation: 1,
          color: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding:
                const EdgeInsets.only(top: 16, bottom: 16, left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: myBlue60),
                    const SizedBox(width: 8),
                    Text(
                      l10n.available_hours,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.not_available,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.brightness == Brightness.light
                        ? myGrey60
                        : myGrey40,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Parse the availableHours data from userData
    try {
      final Map<String, dynamic> rawHours =
          Map<String, dynamic>.from(userData['availableHours'] as Map);
      rawHours.forEach((day, slots) {
        if (slots is List) {
          availableHours[day] = slots;
        } else if (slots is Map) {
          availableHours[day] = [slots];
        }
      });
    } catch (e) {
      debugPrint('Error parsing availableHours: $e');
      return const SizedBox.shrink();
    }

    // Define ordered days
    final orderedDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    String formatTimeString(String timeStr) {
      // Split the time string into hours and minutes
      final parts = timeStr.split(':');
      if (parts.length != 2) return timeStr;

      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;

      // Create a DateTime object for today with the given hours and minutes
      final time = DateTime(2024, 1, 1, hours, minutes);

      // Get user's time format preference
      final userData = context.read<UserProvider>().userData;
      final is24Hour = userData?['timeFormat'] == '24-hour';

      // Format the time based on preference
      final timeFormat = is24Hour ? 'HH:mm' : 'h:mm a';
      return DateFormat(timeFormat).format(time);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 1,
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: myBlue60),
                  const SizedBox(width: 8),
                  Text(
                    l10n.available_hours,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...orderedDays.map((day) {
                final slots = availableHours[day] ?? [];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          _getDayName(day, context),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.brightness == Brightness.light
                                ? myGrey90
                                : Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        child: slots.isEmpty
                            ? Text(
                                l10n.not_available,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.brightness == Brightness.light
                                      ? myGrey60
                                      : myGrey40,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: slots.map<Widget>((slot) {
                                  final timeSlot = slot as Map<String, dynamic>;
                                  final startTime = formatTimeString(
                                      timeSlot['start'].toString());
                                  final endTime = formatTimeString(
                                      timeSlot['end'].toString());

                                  return Text(
                                    '$startTime - $endTime',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color:
                                          theme.brightness == Brightness.light
                                              ? myGrey60
                                              : Colors.white70,
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  String _getDayName(String shortDay, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (shortDay) {
      case 'Mon':
        return l10n.monday;
      case 'Tue':
        return l10n.tuesday;
      case 'Wed':
        return l10n.wednesday;
      case 'Thu':
        return l10n.thursday;
      case 'Fri':
        return l10n.friday;
      case 'Sat':
        return l10n.saturday;
      case 'Sun':
        return l10n.sunday;
      default:
        return shortDay;
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color.fromARGB(255, 0, 102, 255),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialMediaSection(
      BuildContext context, Map<String, dynamic> userData) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final List<dynamic>? socialMediaList =
        userData['socialMedia'] as List<dynamic>?;
    if (socialMediaList == null || socialMediaList.isEmpty)
      return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 1,
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.link_outlined, color: myBlue60),
                  const SizedBox(width: 8),
                  Text(
                    l10n.social_media,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: socialMediaList.map((socialMedia) {
                  // Add null checks and safe casting
                  if (socialMedia is! Map<String, dynamic>)
                    return const SizedBox.shrink();

                  final platform = socialMedia['platform']?.toString() ?? '';
                  final username =
                      socialMedia['platformLink']?.toString() ?? '';

                  // Skip if platform is empty
                  if (platform.isEmpty) return const SizedBox.shrink();

                  IconData icon;
                  Color color;

                  switch (platform.toLowerCase()) {
                    case 'instagram':
                      icon = Icons.camera_alt_outlined;
                      color = theme.brightness == Brightness.light
                          ? myGrey60
                          : Colors.white70;
                      break;
                    case 'linkedin':
                      icon = Icons.work_outline_rounded;
                      color = theme.brightness == Brightness.light
                          ? myGrey60
                          : Colors.white70;
                      break;
                    default:
                      icon = Icons.link;
                      color = theme.brightness == Brightness.light
                          ? myGrey60
                          : Colors.white70;
                  }

                  return _buildSocialButton(
                    platform,
                    icon,
                    color,
                    () => debugPrint('Open $platform: $username'),
                    context,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(String platform, IconData icon, Color color,
      VoidCallback onTap, BuildContext context) {
    final theme = Theme.of(context);

    // Adjust color based on theme
    final buttonColor =
        theme.brightness == Brightness.light ? myGrey60 : Colors.white70;
    final backgroundColor = theme.brightness == Brightness.light
        ? myGrey60.withOpacity(0.1)
        : Colors.white.withOpacity(0.1);

    return Padding(
      padding: const EdgeInsets.only(right: 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: buttonColor),
              const SizedBox(width: 8),
              Text(
                platform,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: buttonColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoadingOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (BuildContext context) {
        return const CustomLoadingView();
      },
    );
  }

  Future<void> _handleBackgroundImage(
      BuildContext context, UserProvider userProvider) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Update local user data immediately to show preview
      final updatedUserData =
          Map<String, dynamic>.from(userProvider.userData ?? {});
      updatedUserData['tempBackgroundImagePath'] =
          image.path; // Store temp path
      userProvider.setUserData(updatedUserData);
    }
  }

  Future<void> _saveBackgroundImage(
      BuildContext context, UserProvider userProvider) async {
    final userData = userProvider.userData;
    final l10n = AppLocalizations.of(context)!;
    if (userData == null || userData['tempBackgroundImagePath'] == null) return;

    final navigator = Navigator.of(context);
    _showLoadingOverlay(context);

    try {
      final userId = userData['userId'];
      final imagePath = userData['tempBackgroundImagePath'];

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_backgrounds')
          .child('$userId.jpg');

      await storageRef.putFile(File(imagePath));
      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'backgroundImageURL': imageUrl});

      final updatedUserData = Map<String, dynamic>.from(userData);
      updatedUserData['backgroundImageURL'] = imageUrl;
      updatedUserData.remove('tempBackgroundImagePath');
      userProvider.setUserData(updatedUserData);

      navigator.pop();
    } catch (e) {
      navigator.pop();
      debugPrint('Error saving image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
          title: l10n.background_image,
          message: l10n.failed_save_image,
          type: SnackBarType.error,
        ),
      );
    }
  }

  Future<void> _removeBackgroundImage(
      BuildContext context, UserProvider userProvider,
      {bool isTemp = false}) async {
    final userData = userProvider.userData;
    final l10n = AppLocalizations.of(context)!;
    if (userData == null) return;

    if (isTemp) {
      final updatedUserData = Map<String, dynamic>.from(userData);
      updatedUserData.remove('tempBackgroundImagePath');
      userProvider.setUserData(updatedUserData);
      return;
    }

    final navigator = Navigator.of(context);
    _showLoadingOverlay(context);

    try {
      final userId = userData['userId'];

      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_backgrounds')
            .child('$userId.jpg');
        await storageRef.delete();
      } catch (e) {
        debugPrint('No existing image to delete or error: $e');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'backgroundImageURL': null});

      final updatedUserData = Map<String, dynamic>.from(userData);
      updatedUserData['backgroundImageURL'] = null;
      userProvider.setUserData(updatedUserData);

      navigator.pop();
    } catch (e) {
      navigator.pop();
      debugPrint('Error removing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
          title: l10n.background_image,
          message: l10n.failed_save_image,
          type: SnackBarType.error,
        ),
      );
    }
  }

  void _showBackgroundImageOptions(
      BuildContext context, UserProvider userProvider) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: myGrey30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: myBlue60),
                title: Text(
                  l10n.edit_background_photo,
                  style: GoogleFonts.plusJakartaSans(
                    color: myBlue60,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleBackgroundImage(context, userProvider);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: myRed50),
                title: Text(
                  l10n.remove_background_photo,
                  style: GoogleFonts.plusJakartaSans(
                    color: myRed50,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeBackgroundImage(context, userProvider);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
