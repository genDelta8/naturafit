import 'package:naturafit/models/achievements/client_achievements.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/views/client_side/client_progress_page.dart';
import 'package:naturafit/views/client_side/client_settings_page.dart';
import 'package:naturafit/views/shared_side/direct_message_page.dart';
import 'package:naturafit/views/shared_side/messages_page.dart';
import 'package:naturafit/views/trainer_side/all_trainer_settings/trainer_account_settings_page.dart';
import 'package:naturafit/views/web/web_client_side.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:naturafit/widgets/custom_user_profile_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/views/client_side/client_achievements_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:naturafit/widgets/custom_loading_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ClientProfilePage extends StatelessWidget {
  const ClientProfilePage({
    super.key,
    this.passedClient,
    this.isEnteredByTrainer = false,
    this.passedConsentSettingsForTrainer,
    this.passedWidgetClient,
  });
  final Map<String, dynamic>? passedClient;
  final bool isEnteredByTrainer;
  final Map<String, dynamic>? passedConsentSettingsForTrainer;
  final Map<String, dynamic>? passedWidgetClient;

  @override
  Widget build(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      userProvider.refreshAchievements();
    });

    final double screenWidth = MediaQuery.of(context).size.width;
    final double headerHeight = screenWidth * (9 / 16);
    const double profileImageRadius = 60;

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final myIsWebOrDektop = isWebOrDesktopCached;

    final userData = isEnteredByTrainer
        ? passedClient
        : context.watch<UserProvider>().userData;
    debugPrint('myuserData: $userData');

    if (userData == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: myBlue60),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
        body: !myIsWebOrDektop
          ? Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(context, headerHeight, profileImageRadius,
                        userData, l10n),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 80),
                            _buildNameAndBio(context, userData, l10n),
                            const SizedBox(height: 16),
                            _buildPrimaryGoalSection(context, userData, l10n),
                            const SizedBox(height: 16),
                            _buildAchievementsSection(context, userData, l10n),
                            const SizedBox(height: 16),
                            _buildSocialMediaSection(context, userData, l10n),
                            const SizedBox(height: 16),
                            _buildAvailableHoursSection(context, userData),
                            const SizedBox(height: 32),
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
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            _buildHeader(context, headerHeight, profileImageRadius,
                                userData, l10n),
                            SingleChildScrollView(
                              child: Column(
                                children: [
                                  const SizedBox(height: 80),
                                  _buildNameAndBio(context, userData, l10n),
                                  const SizedBox(height: 16),
                                  _buildPrimaryGoalSection(context, userData, l10n),
                                  const SizedBox(height: 16),
                                  _buildAchievementsSection(
                                      context, userData, l10n),
                                  const SizedBox(height: 16),
                                  _buildSocialMediaSection(context, userData, l10n),
                                  const SizedBox(height: 16),
                                  _buildAvailableHoursSection(context, userData),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ],
                        ),
                        _buildProfileImage(
                            context, userData, headerHeight, profileImageRadius),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showLoadingOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (BuildContext context) {
        return const CustomLoadingView(
            //message: 'Please wait...',
            );
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
    final l10n = AppLocalizations.of(context)!;
    final userData = userProvider.userData;
    if (userData == null || userData['tempBackgroundImagePath'] == null) return;

    _showLoadingOverlay(context);

    try {
      final userId = userData['userId'];
      final imagePath = userData['tempBackgroundImagePath'];

      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_backgrounds')
          .child('$userId.jpg');

      await storageRef.putFile(File(imagePath));
      final imageUrl = await storageRef.getDownloadURL();

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'backgroundImageURL': imageUrl});

      // Update local user data
      final updatedUserData = Map<String, dynamic>.from(userData);
      updatedUserData['backgroundImageURL'] = imageUrl;
      updatedUserData.remove('tempBackgroundImagePath');
      userProvider.setUserData(updatedUserData);

      // Close loading overlay
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } catch (e) {
      // Close loading overlay
      Navigator.pop(context);
      debugPrint('Error saving image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
                                    title: l10n.error,
                                    message: l10n.failed_to_save_image,
                                    type: SnackBarType.error,
                                  ),
      );
    }
  }

  Future<void> _removeBackgroundImage(
      BuildContext context, UserProvider userProvider,
      {bool isTemp = false}) async {
    final l10n = AppLocalizations.of(context)!;
    final userData = userProvider.userData;
    if (userData == null) return;

    if (isTemp) {
      // Just remove the temp image
      final updatedUserData = Map<String, dynamic>.from(userData);
      updatedUserData.remove('tempBackgroundImagePath');
      userProvider.setUserData(updatedUserData);
      return;
    }

    // Get the navigator state
    final navigator = Navigator.of(context);
    _showLoadingOverlay(context);

    try {
      final userId = userData['userId'];

      // Delete from Firebase Storage if exists
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_backgrounds')
            .child('$userId.jpg');
        await storageRef.delete();
      } catch (e) {
        debugPrint('No existing image to delete or error: $e');
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'backgroundImageURL': null});

      // Update local user data
      final updatedUserData = Map<String, dynamic>.from(userData);
      updatedUserData['backgroundImageURL'] = null;
      userProvider.setUserData(updatedUserData);

      // Close loading overlay using stored navigator
      // ignore: use_build_context_synchronously
      navigator.pop();
    } catch (e) {
      // Close loading overlay using stored navigator
      navigator.pop();
      debugPrint('Error removing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
                                    title: l10n.error,
                                    message: l10n.failed_to_remove_image,
                                    type: SnackBarType.error,
                                  ),
      );
    }
  }

  Widget _buildHeader(
      BuildContext context,
      double headerHeight,
      double profileImageRadius,
      Map<String, dynamic> userData,
      AppLocalizations l10n) {
    final hasBackgroundImage = userData['backgroundImageURL'] != null;
    final hasTempImage = userData['tempBackgroundImagePath'] != null;
    final userProvider = context.read<UserProvider>();
    final theme = Theme.of(context);
    final myIsWebOrDektop = isWebOrDesktopCached;

    const emptyWidth = 210 + 300 + 100;
    final screenWidth = MediaQuery.of(context).size.width;
    final webScreenWidth = screenWidth - emptyWidth;

    final isSmall = webScreenWidth*0.8 < 400;



    final myHeaderWidth = isSmall ? 400.0 : webScreenWidth*0.8;
    final myHeaderHeight = myHeaderWidth * (9 / 16);

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
                    ? FileImage(File(userData['tempBackgroundImagePath']!))
                    : NetworkImage(userData['backgroundImageURL']!)
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
                color: theme.brightness == Brightness.light ? myGrey40 : myGrey80,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 40,
                      color: myGrey70,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.background_photo,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                            icon: Icon(Icons.chevron_left, color: Colors.white, size: 24),
                            onPressed: null,
                          ),
                        ),
                      ),
                if (!isEnteredByTrainer)
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
                                  l10n.save,
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
        final myIsWebOrDektop = isWebOrDesktopCached;


    const emptyWidth = 210 + 300 + 100;
    final screenWidth = MediaQuery.of(context).size.width;
    final webScreenWidth = screenWidth - emptyWidth;

    final isSmall = webScreenWidth*0.8 < 400;
    final isSmallForButtons = webScreenWidth*0.8 < 200;


    final spaceBetween = isSmallForButtons ? 16.0 : webScreenWidth*0.1;



    final myHeaderWidth = isSmall ? 400.0 : webScreenWidth*0.8;
    final myHeaderHeight = myHeaderWidth * (9 / 16);

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
                  final webClientState =
                      context.findAncestorStateOfType<WebClientSideState>();

                      if (isEnteredByTrainer) {
                        final userProvider = context.read<UserProvider>();
                        final trainerUserData = userProvider.userData;
                        final trainerClientId = trainerUserData?['trainerClientId'];
                        final clientId = userData['userId'];
                        if (trainerClientId == null) {
                          return;
                        }
                        if (trainerClientId == clientId) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MessagesPage(isVisitingProfile: true)),
                          );
                        }
                        else {
                          final otherUserId = clientId;
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
                                      otherUserName:
                                          userData[fbFullName] ??
                                              'Unknown',
                                      chatType: 'client',
                                      otherUserProfileImageUrl:
                                          userData['profileImageUrl'] ??
                                              '',
                                    ),
                                  ),
                                );

                        }

                      }
                      else {

                        if (webClientState != null && myIsWebOrDektop) {
                    webClientState.setState(() {
                      webClientState
                          .setCurrentPage(const MessagesPage(), 'MessagesPage');
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
                if (!isEnteredByTrainer)
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
            if (isEnteredByTrainer) ...[
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
                  icon: const Icon(Icons.trending_up, color: Colors.white),
                  onPressed: () {
                    final consentSettings = userData['dataConsent'] ??
                        {
                          'birthday': false,
                          'email': false,
                          'phone': false,
                          'location': false,
                          'measurements': false,
                          'progressPhotos': false,
                          'socialMedia': false,
                        };

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProgressPage(
                          isEnteredByTrainer: true,
                          passedClientForTrainer: passedWidgetClient,
                          passedConsentSettingsForTrainer: consentSettings,
                          passedHeight: _toDouble(userData['height']),
                          passedWeight: _toDouble(userData['weight']),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
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
                          builder: (context) => const ClientSettingsPage()),
                    );
                  },
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // Helper method to safely convert to double
  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Widget _buildNameAndBio(BuildContext context, Map<String, dynamic> userData,
      AppLocalizations l10n) {
        final myIsWebOrDektop = isWebOrDesktopCached;
    final theme = Theme.of(context);
    final localizedGender = userData['gender'] == 'Male'
        ? l10n.male
        : userData['gender'] == 'Other'
            ? l10n.other
            : l10n.female;
    // Calculate age from birthday
    int calculateAge(dynamic birthday) {
      debugPrint('myBirthday: $birthday');
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

        debugPrint('myAge: $age');
        return age;
      } catch (e) {
        debugPrint('Error calculating age: $e');
        return 0;
      }
    }

    // Get the calculated age
    final age = calculateAge(userData['birthday']);

    // Add this function to get formatted measurement
    String getFormattedMeasurement(
        double value, String storedUnit, bool isHeight) {
      final userData = context.read<UserProvider>().userData;
      final userUnit = userData?[isHeight ? 'heightUnit' : 'weightUnit'] ?? storedUnit;

      if (isHeight) {
        if (userUnit == 'ft') {
          final inches = value / 2.54; // Convert cm to inches
          final feet = (inches / 12).floor();
          final remainingInches = (inches % 12).round();
          return "$feet'$remainingInches\"";
        }
        return '${value.round()}';
      } else {
        if (userUnit == 'lbs') {
          final lbs = value * 2.20462; // Convert kg to lbs
          return '${lbs.round()}';
        }
        return '${value.round()}';
      }
    }

    return Column(
      children: [
        Text(
          userData[fbFullName] ?? userData[fbRandomName] ?? l10n.unknown,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.brightness == Brightness.light
                ? Colors.black
                : Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        // Premium Member Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: myBlue60.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            l10n.premium_member,
            style: GoogleFonts.plusJakartaSans(
              color: myBlue60,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Info Row
        if ((isEnteredByTrainer &&
                (userData['dataConsent']['birthday'] == true ||
                    userData['dataConsent']['measurements'] == true)) ||
            !isEnteredByTrainer) ...[
          Container(
            constraints: BoxConstraints(
            maxWidth: myIsWebOrDektop ? 600 : double.infinity,
          ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Row(

                mainAxisAlignment: ((isEnteredByTrainer &&
                            userData['dataConsent']['measurements'] == true) ||
                        !isEnteredByTrainer)
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.center,
                children: [
                  if ((isEnteredByTrainer &&
                          userData['dataConsent']['measurements'] == true) ||
                      !isEnteredByTrainer) ...[
                    _buildInfoItem(
                        context,
                        l10n.weight,
                        getFormattedMeasurement(
                            (userData['weight'] ?? 0).toDouble(),
                            userData['weightUnit'] ?? 'kg',
                            false),
                        userData['weightUnit'] ?? 'kg'),
                    Container(
                      width: 1,
                      height: 40,
                      color: myGrey20,
                    ),
                  ],
                  if ((isEnteredByTrainer &&
                          userData['dataConsent']['birthday'] == true) ||
                      !isEnteredByTrainer) ...[
                    _buildInfoItem(context, l10n.age, '$age', 'y'),
                  ],
                  if ((isEnteredByTrainer &&
                          userData['dataConsent']['measurements'] == true) ||
                      !isEnteredByTrainer) ...[
                    if ((isEnteredByTrainer &&
                            userData['dataConsent']['birthday'] == true) ||
                        !isEnteredByTrainer) ...[
                      Container(
                        width: 1,
                        height: 40,
                        color: myGrey20,
                      ),
                    ],
                    _buildInfoItem(
                        context,
                        l10n.height,
                        getFormattedMeasurement(
                            (userData['height'] ?? 0).toDouble(),
                            userData['heightUnit'] ?? 'cm',
                            true),
                        userData['heightUnit'] ?? 'cm'),
                  ]
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Location and Gender Row
        if (userData['location'] != null || userData['gender'] != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gender first
              if (userData['gender'] != null) ...[
                Icon(
                  userData['gender'] == 'Male'
                      ? Icons.male_outlined
                      : Icons.female_outlined,
                  size: 16,
                  color: theme.brightness == Brightness.light
                      ? myGrey90
                      : myGrey10,
                ),
                const SizedBox(width: 4),
                Text(
                  localizedGender,
                  style: GoogleFonts.plusJakartaSans(
                    color: theme.brightness == Brightness.light
                        ? myGrey90
                        : myGrey10,
                    fontSize: 14,
                  ),
                ),
              ],
              // Separator dot
              if (userData['location'] != null && userData['gender'] != null)
                if ((isEnteredByTrainer &&
                        (userData['dataConsent']['location'] == true)) ||
                    !isEnteredByTrainer) ...[
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
                ],
              // Location second
              if (userData['location'] != null) ...[
                if ((isEnteredByTrainer &&
                        (userData['dataConsent']['location'] == true)) ||
                    !isEnteredByTrainer) ...[
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: theme.brightness == Brightness.light
                        ? myGrey90
                        : myGrey10,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    userData['location'],
                    style: GoogleFonts.plusJakartaSans(
                      color: theme.brightness == Brightness.light
                          ? myGrey90
                          : myGrey10,
                      fontSize: 14,
                    ),
                  ),
                ]
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
              style: GoogleFonts.plusJakartaSans(
                color: myGrey60,
                fontSize: 14,
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
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color:
                    theme.brightness == Brightness.light ? myGrey80 : myGrey10,
              ),
            ),
            Text(
              unit,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color:
                    theme.brightness == Brightness.light ? myGrey60 : myGrey30,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: theme.brightness == Brightness.light ? myGrey60 : myGrey30,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryGoalSection(BuildContext context,
      Map<String, dynamic> userData, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final primaryGoal = userData['primaryGoal'] as String?;
    if (primaryGoal == null || primaryGoal.isEmpty)
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
                  const Icon(Icons.flag_outlined, color: myBlue60),
                  const SizedBox(width: 8),
                  Text(
                    l10n.primary_goal,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.brightness == Brightness.light
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                primaryGoal,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: theme.brightness == Brightness.light
                      ? Colors.black
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context,
      Map<String, dynamic> userData, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    final unlockedAchievements = userProvider.unlockedAchievements ?? [];
    final allAchievements = ClientAchievements.getAllAchievements();

    // Calculate completion percentage
    final completionPercentage =
        (unlockedAchievements.length / allAchievements.length * 100).round();

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events_outlined, color: myBlue60),
                      const SizedBox(width: 8),
                      Text(
                        l10n.achievements,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.brightness == Brightness.light
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        //color: myBlue60.withOpacity(0.1),
                        //borderRadius: BorderRadius.circular(20),
                        ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ClientAchievementsPage(),
                          ),
                        );
                      },
                      child: Text(
                        '${l10n.view_all} >',
                        style: GoogleFonts.plusJakartaSans(
                          color: myBlue60,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (unlockedAchievements.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      l10n.no_achievements_unlocked_yet,
                      style: GoogleFonts.plusJakartaSans(
                        color: myGrey60,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: unlockedAchievements.map((achievementId) {
                    final achievement = allAchievements.firstWhere(
                      (a) => a.id == achievementId,
                      orElse: () => allAchievements.first,
                    );

                    return _buildAchievementItem(achievement);
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementItem(Achievement achievement) {
    Color backgroundColor;
    switch (achievement.difficulty) {
      case AchievementDifficulty.easy:
        backgroundColor = const Color(0xFF4CAF50).withOpacity(0.1);
        break;
      case AchievementDifficulty.medium:
        backgroundColor = const Color(0xFFFFA726).withOpacity(0.1);
        break;
      case AchievementDifficulty.hard:
        backgroundColor = const Color(0xFFF44336).withOpacity(0.1);
        break;
    }

    return Tooltip(
      message: achievement.description,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: backgroundColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              achievement.icon,
              size: 16,
              color: Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              achievement.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
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
                Text(
                  l10n.no_available_hours,
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
                                  final startTime = formatTimeString(timeSlot['start'].toString());
                                  final endTime = formatTimeString(timeSlot['end'].toString());
                                  
                                  return Text(
                                    '$startTime - $endTime',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.brightness == Brightness.light
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

  Widget _buildSocialMediaSection(BuildContext context,
      Map<String, dynamic> userData, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final List<dynamic>? socialMediaList =
        userData['socialMedia'] as List<dynamic>?;
    if (socialMediaList == null || socialMediaList.isEmpty)
      return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 1,
        color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.brightness == Brightness.light
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: socialMediaList.map((socialMedia) {
                  if (socialMedia is! Map<String, dynamic>)
                    return const SizedBox.shrink();

                  final platform = socialMedia['platform']?.toString() ?? '';
                  final username =
                      socialMedia['platformLink']?.toString() ?? '';

                  if (platform.isEmpty) return const SizedBox.shrink();

                  IconData icon;
                  Color color;

                  switch (platform.toLowerCase()) {
                    case 'instagram':
                      icon = Icons.camera_alt_outlined;
                      color = myGrey60;
                      break;
                    case 'linkedin':
                      icon = Icons.work_outline_rounded;
                      color = myGrey60;
                      break;
                    default:
                      icon = Icons.link;
                      color = myGrey60;
                  }

                  return _buildSocialButton(
                    platform,
                    icon,
                    color,
                    () => debugPrint('Open $platform: $username'),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(
      String platform, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                platform,
                style: GoogleFonts.plusJakartaSans(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add this method to show the bottom sheet
  void _showBackgroundImageOptions(
      BuildContext context, UserProvider userProvider) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                theme.brightness == Brightness.light ? Colors.white : myGrey80,
            borderRadius: const BorderRadius.vertical(
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
                  l10n.edit_background,
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
                  l10n.remove_background,
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
