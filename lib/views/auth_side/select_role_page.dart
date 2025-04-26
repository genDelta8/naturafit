import 'dart:math';
import 'package:naturafit/services/auth/bloc/my_auth_bloc.dart';
import 'package:naturafit/services/locale_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/views/client_side/client_onboarding_steps.dart';
import 'package:naturafit/views/trainer_side/trainer_onboarding_steps.dart';
import 'package:naturafit/views/web/web_client_side.dart';
import 'package:naturafit/views/web/web_coach_side.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/views/client_side/client_side.dart';
import 'package:naturafit/views/trainer_side/coach_side.dart';
import 'package:naturafit/services/firebase_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
class UserTypeScreen extends StatefulWidget {
  final String passedUserId;
  const UserTypeScreen({super.key, required this.passedUserId});

  @override
  State<UserTypeScreen> createState() => _UserTypeScreenState();
}

class _UserTypeScreenState extends State<UserTypeScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    //_checkExistingUser();
  }

  

  String generateUsername() {
    final random = Random();
    // Generate a 6-digit random number
    final number = random.nextInt(999999).toString().padLeft(6, '0');
    return 'user$number';
  }

  Future<void> _handleRoleSelection(BuildContext context, String role) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      //await context.read<LocaleProvider>().setLocale('en');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: myBlue60)),
      );

      final userId = widget.passedUserId;
      final username = generateUsername();

      const timeFormat = '12-hour';
      const dateFormat = 'MM/dd/yyyy';

      if (role == 'trainer') {
        // Update trainer's main profile first
        await _firebaseService.updateUserData(
          userId: userId,
          data: {
            'role': role,
            'fullName': username,
            'username': username,
            'trainerClientId': '', // Initially empty
            'hasClientProfile': false,
            'timeFormat': timeFormat,
            'dateFormat': dateFormat,
            'language': 'en',
            'onboardingCompleted': false,
            'onboardingStep': 1,
            'isLoggedIn': false, // Will be set to true after completing onboarding
          },
        );

        // Then create associated client profile
        final trainerClientId =
            await _firebaseService.createTrainerClientProfile(userId);

        // Update trainer profile with client ID
        await _firebaseService.updateTrainerProfile(userId, trainerClientId);

        if (mounted) {
          Navigator.pop(context); // Remove loading dialog
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TrainerOnboardingSteps(
                userId: userId,
                username: username,
                trainerClientId: trainerClientId,
              ),
            ),
          );
        }
      } else {
        // Handle client role
        await _firebaseService.updateUserData(
          userId: userId,
          data: {
            'role': role,
            'fullName': username,
            'username': username,
            'trainerClientId': '',
            'hasClientProfile': false,
            'timeFormat': timeFormat,
            'dateFormat': dateFormat,
            'language': 'en',
            'onboardingCompleted': false,
            'onboardingStep': 1,
            'isLoggedIn': false,
          },
        );

        if (mounted) {
          Navigator.pop(context);
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ClientOnboardingSteps(
                  userId: userId,
                  username: username,
                ),
              ),
            );
          // ... handle other roles
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
                                    title: l10n.error,
                                    message: l10n.error_setting_up_profile(e.toString()),
                                    type: SnackBarType.error,
                                  ),
        );
      }
    }
  }

  

  @override
  Widget build(BuildContext context) {
    final myIsWebOrDektop = isWebOrDesktopCached;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light ? myGrey10 : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.brightness == Brightness.light ? myGrey10 : theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: const SizedBox.shrink(),
        centerTitle: true,
        title: Text(
          l10n.select_your_role,
          style: GoogleFonts.plusJakartaSans(
            color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.i_am_a,
              style: GoogleFonts.plusJakartaSans(
                fontSize: myIsWebOrDektop ? 32 : 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: myIsWebOrDektop
                  ? Row(
                      children: [
                        Expanded(child: _buildTrainerCard()),
                        const SizedBox(width: 24),
                        Expanded(child: _buildClientCard()),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(child: _buildTrainerCard()),
                        const SizedBox(height: 24),
                        Expanded(child: _buildClientCard()),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainerCard() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool showDescription = constraints.maxHeight > 300;
        final bool showTitle = constraints.maxHeight > 200;
        
        // Calculate icon size based on available height
        final double iconContainerSize = constraints.maxHeight < 150 ? 50 : 80;
        final double iconSize = iconContainerSize * 0.5;
        
        return GestureDetector(
          onTap: () => _handleRoleSelection(context, 'trainer'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 0, 102, 255).withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 102, 255).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(iconContainerSize * 0.25),
                  ),
                  child: Icon(
                    Icons.sports_gymnastics,
                    size: iconSize,
                    color: const Color.fromARGB(255, 0, 102, 255),
                  ),
                ),
                if (showTitle) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.personal_trainer,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                    ),
                  ),
                ],
                if (showDescription) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.manage_clients_create_workout_plans_and_track_progress,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClientCard() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool showDescription = constraints.maxHeight > 300;
        final bool showTitle = constraints.maxHeight > 200;
        
        // Calculate icon size based on available height
        final double iconContainerSize = constraints.maxHeight < 150 ? 50 : 80;
        final double iconSize = iconContainerSize * 0.5;
        
        return GestureDetector(
          onTap: () => _handleRoleSelection(context, 'client'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 255, 147, 92).withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 147, 92).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(iconContainerSize * 0.25),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: iconSize,
                    color: const Color.fromARGB(255, 255, 147, 92),
                  ),
                ),
                if (showTitle) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.client,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                    ),
                  ),
                ],
                if (showDescription) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.track_workouts_meals_and_your_fitness_journey,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
