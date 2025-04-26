import 'package:naturafit/services/auth/bloc/my_auth_bloc.dart';
import 'package:naturafit/services/unit_preferences.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/views/all_shared_settings/contact_info_page.dart';
import 'package:naturafit/views/all_shared_settings/help_center_page.dart';
import 'package:naturafit/views/all_shared_settings/privacy_policy_page.dart';
import 'package:naturafit/views/all_shared_settings/terms_and_conditions.dart';
import 'package:naturafit/views/auth_side/welcome_page.dart';
import 'package:naturafit/views/client_side/all_client_settings/client_availability_settings_page.dart';
import 'package:naturafit/views/client_side/all_client_settings/client_sensitive_data_settings_page.dart';
import 'package:naturafit/views/web/landing_page.dart';
import 'package:naturafit/widgets/custom_available_hours_selector.dart';
import 'package:naturafit/widgets/custom_social_media_selector.dart';
import 'package:naturafit/widgets/custom_user_profile_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/services/firebase_service.dart';
import 'package:naturafit/widgets/custom_toggle_switch.dart';
import 'package:naturafit/views/trainer_side/all_trainer_settings/trainer_certifications_page.dart';
import 'package:naturafit/views/trainer_side/all_trainer_settings/trainer_specializations_page.dart';
import 'package:naturafit/views/trainer_side/all_trainer_settings/trainer_experience_page.dart';
import 'package:naturafit/views/trainer_side/all_trainer_settings/trainer_sensitive_data_page.dart';
import 'package:naturafit/views/trainer_side/all_trainer_settings/trainer_working_hours_page.dart';
import 'package:naturafit/views/all_shared_settings/language_settings_page.dart';
import 'package:naturafit/services/theme_provider.dart';
import 'package:naturafit/views/all_shared_settings/feedback_sheet.dart';
import 'package:naturafit/views/trainer_side/all_trainer_settings/trainer_profile_settings_page.dart';
import 'package:naturafit/views/trainer_side/all_trainer_settings/trainer_account_settings_page.dart';
import 'package:naturafit/views/client_side/all_client_settings/client_unit_preferences_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:naturafit/views/auth_side/forgot_password_page.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';

class ClientSettingsPage extends StatefulWidget {
  const ClientSettingsPage({super.key});

  @override
  State<ClientSettingsPage> createState() => _ClientSettingsPageState();
}

class _ClientSettingsPageState extends State<ClientSettingsPage> {
  Future<void> _handleLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    // Show confirmation dialog
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: theme.brightness == Brightness.light ? Colors.white : myGrey80,
        title: Text(
          l10n.sign_out,
          style: GoogleFonts.plusJakartaSans(
            color: myRed50,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          l10n.sign_out_confirmation_message,
          style: GoogleFonts.plusJakartaSans(
            color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.plusJakartaSans(
                color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.sign_out,
              style: GoogleFonts.plusJakartaSans(
                color: myRed50,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmLogout == true) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => const Center(
            child: CircularProgressIndicator(color: myBlue60),
          ),
        );

        // Use AuthBloc for logout
        context.read<AuthBloc>().add(AuthLogout(context));

        // Close loading dialog and navigate to welcome screen
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          
          // Navigate to welcome screen and clear navigation stack
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => kIsWeb ? const LandingPage() : const WelcomeScreen(),
            ),
            (route) => false, // Remove all previous routes
          );
        }
      } catch (e) {
        // Close loading dialog if open
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        // Show error dialog
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: Text(l10n.logout_failed),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.ok),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final passwordController = TextEditingController();
    
    // Show confirmation dialog with password field
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: theme.brightness == Brightness.light ? Colors.white : myGrey80,
        title: Text(
          l10n.delete_account_confirmation_title,
          style: GoogleFonts.plusJakartaSans(
            color: myRed50,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.delete_account_confirmation_message,
              style: GoogleFonts.plusJakartaSans(
                color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            CustomFocusTextField(
              controller: passwordController,
              label: l10n.password,
              hintText: l10n.password,
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              isRequired: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.plusJakartaSans(
                color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.delete,
              style: GoogleFonts.plusJakartaSans(
                color: myRed50,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => const Center(
            child: CircularProgressIndicator(color: myBlue60),
          ),
        );

        // Delete account with password
        await FirebaseService().deleteUserAccount(passwordController.text);

        // Navigate to welcome screen
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => kIsWeb ? const LandingPage() : const WelcomeScreen(),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        // Close loading dialog if open
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        // Show error dialog
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: Text(l10n.delete_account_failed),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.ok),
                ),
              ],
            ),
          );
        }
      } finally {
        passwordController.dispose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userData = context.watch<UserProvider>().userData;
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    final unitPreferences = context.watch<UnitPreferences>();
    
    return AnimatedTheme(
      data: Theme.of(context),
      duration: ThemeProvider.themeAnimationDuration,
      curve: ThemeProvider.themeAnimationCurve,
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: _buildAppBarSettings(context),
          body: AnimatedContainer(
            duration: ThemeProvider.themeAnimationDuration,
            curve: ThemeProvider.themeAnimationCurve,
            color: theme.scaffoldBackgroundColor,
            child: Column(
              children: [
                // Profile Card
                AnimatedContainer(
                  duration: ThemeProvider.themeAnimationDuration,
                  curve: ThemeProvider.themeAnimationCurve,
                  margin: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light ? myBlue30 : myBlue90,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AnimatedContainer(
                    duration: ThemeProvider.themeAnimationDuration,
                    curve: ThemeProvider.themeAnimationCurve,
                    margin: const EdgeInsets.all(3),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light ? myBlue60 : myBlue60,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        // Profile Image Container
                        AnimatedContainer(
                          duration: ThemeProvider.themeAnimationDuration,
                          curve: ThemeProvider.themeAnimationCurve,
                          decoration: BoxDecoration(
                            color: myGrey10,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: AnimatedContainer(
                            duration: ThemeProvider.themeAnimationDuration,
                            curve: ThemeProvider.themeAnimationCurve,
                            margin: const EdgeInsets.all(2),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),  
                              
                              color: theme.brightness == Brightness.light ? myBlue40 : myBlue60,
                            ),
                            child: CustomUserProfileImage(
                              imageUrl: userData?[fbProfileImageURL] ?? '',
                              name: userData?[fbFullName] ?? userData?[fbRandomName] ?? 'User',
                              size: 60,
                              borderRadius: 12,
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),
                        // Name and Email
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: ThemeProvider.themeAnimationDuration,
                                curve: ThemeProvider.themeAnimationCurve,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ) ?? const TextStyle(),
                                child: Text(userData?[fbFullName] ?? 'User Name'),
                              ),
                              const SizedBox(height: 4),
                              AnimatedDefaultTextStyle(
                                duration: ThemeProvider.themeAnimationDuration,
                                curve: ThemeProvider.themeAnimationCurve,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ) ?? const TextStyle(),
                                child: Text(userData?['email'] ?? 'email@example.com'),
                              ),
                            ],
                          ),
                        ),
                        // Edit Button
                        AnimatedContainer(
                          duration: ThemeProvider.themeAnimationDuration,
                          curve: ThemeProvider.themeAnimationCurve,
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 16),
                            onPressed: () {
                              final userData = context.read<UserProvider>().userData;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TrainerAccountSettingsPage(
                                    initialFullName: userData?['fullName'] as String? ?? '',
                                    initialEmail: userData?['email'] as String? ?? '',
                                    initialPhone: userData?['phone'] as String? ?? '',
                                    initialLocation: userData?['location'] as String? ?? '',
                                    initialProfileImageURL: userData?[fbProfileImageURL] as String?,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Settings List
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(
                          l10n.account,
                          [
                            _buildSettingItem(
                              icon: Icons.person_outline,
                              title: l10n.profile,
                              onTap: () {
                                final userData = context.read<UserProvider>().userData;
                                
                                
                                // Convert Timestamp to formatted string
                                String formattedBirthday = '';
                                if (userData?['birthday'] != null) {
                                  if (userData!['birthday'] is Timestamp) {
                                    final DateTime birthdayDate = (userData['birthday'] as Timestamp).toDate();
                                    formattedBirthday = birthdayDate.toString().split(' ')[0]; // Format as YYYY-MM-DD
                                  } else {
                                    formattedBirthday = userData['birthday'].toString();
                                  }
                                }

                                double initialHeight = 170.0;
                                double initialWeight = 70.0;

                                if (userData?['heightUnit'] == 'cm') {
                                  initialHeight = userData?['height']?.toDouble() ?? 170.0;
                                } else {
                                  initialHeight = unitPreferences.cmToft(userData?['height']?.toDouble() ?? 170.0);
                                }

                                if (userData?['weightUnit'] == 'kg') {
                                  initialWeight = userData?['weight']?.toDouble() ?? 70.0;
                                } else {
                                  initialWeight = unitPreferences.kgToLbs(userData?['weight']?.toDouble() ?? 70.0);
                                }



                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TrainerProfileSettingsPage(
                                      initialBio: userData?['bio'] ?? '',
                                      initialSocialMedia: (userData?['socialMedia'] as List<dynamic>? ?? [])
                                          .map((profile) => SocialMediaProfile(
                                                platform: profile['platform'],
                                                platformLink: profile['platformLink'],
                                              ))
                                          .toList(),
                                      initialBirthday: formattedBirthday,
                                      initialGender: userData?['gender'] ?? 'Not Specified',
                                      initialHeight: initialHeight,
                                      initialWeight: initialWeight,
                                      initialHeightUnit: userData?['heightUnit'] ?? 'cm',
                                      initialWeightUnit: userData?['weightUnit'] ?? 'kg',
                                    ),
                                  ),
                                );
                              },
                            ),


                            _buildSettingItem(
                              icon: Icons.calendar_month_outlined,
                              title: l10n.available_hours,
                              subtitle: l10n.available_hours_subtitle,
                              onTap: () {
                                final userData = context.read<UserProvider>().userData;
                                final availableHours = (userData?['availableHours'] as Map<String, dynamic>?)?.map(
                                  (key, value) => MapEntry(
                                    key,
                                    (value as List<dynamic>).map((range) => TimeRange(
                                      start: TimeOfDay(
                                        hour: int.parse(range['start'].split(':')[0]),
                                        minute: int.parse(range['start'].split(':')[1].split(' ')[0]),
                                      ),
                                      end: TimeOfDay(
                                        hour: int.parse(range['end'].split(':')[0]),
                                        minute: int.parse(range['end'].split(':')[1].split(' ')[0]),
                                      ),
                                    )).toList(),
                                  ),
                                ) ?? {};

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ClientAvailableHoursPage(
                                      initialAvailableHours: availableHours,
                                    ),
                                  ),
                                );
                              },
                            ),

/*
                            _buildSettingItem(
                              icon: Icons.payments_outlined,
                              title: l10n.payment_settings,
                              subtitle: l10n.payment_settings_subtitle,
                              onTap: () {},
                            ),
                            */
                            
                            
                            
                          ],
                          Icons.person_outline,
                        ),
                        _buildSection(
                          l10n.security,
                          [
                            _buildSettingItem(
                              icon: Icons.visibility_off,
                              title: l10n.sensitive_data,
                              onTap: () {
                                final userData = context.read<UserProvider>().userData;
                                final consentSettings = (userData?['consentSettings'] as Map<String, dynamic>?)?.map(
                                  (key, value) => MapEntry(key, value as bool),
                                ) ?? {};

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ClientSensitiveDataPage(
                                      initialConsentSettings: consentSettings,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildSettingItem(
                              icon: Icons.vpn_key_outlined,
                              title: l10n.password,
                              subtitle: l10n.password_subtitle,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ForgotPasswordPage(),
                                  ),
                                );
                              },
                            ),
                            
                            
                          ],
                          Icons.lock_outline,
                        ),
                        /*
                        _buildSection(
                          l10n.notifications,
                          [
                            _buildSettingItem(
                              icon: Icons.notifications_outlined,
                              title: l10n.push_notifications,
                              subtitle: l10n.push_notifications_subtitle,
                              onTap: () {},
                            ),
                            _buildSettingItem(
                              icon: Icons.email_outlined,
                              title: l10n.email_notifications,
                              subtitle: l10n.email_notifications_subtitle,
                              onTap: () {},
                            ),
                          ],
                          Icons.notifications_outlined,
                        ),
                        */
                        _buildSection(
                          l10n.app_settings,
                          [
                            _buildSettingItem(
                              icon: Icons.language,
                              title: l10n.language,
                              subtitle: l10n.language_subtitle,
                              onTap: () {
                                final userData = context.read<UserProvider>().userData;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LanguageSettingsPage(
                                      initialLanguage: userData?['language'] as String?,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildSettingItem(
                              icon: Icons.bar_chart_outlined,
                              title: l10n.unit_preferences,
                              subtitle: l10n.unit_preferences_subtitle,
                              onTap: () {
                                final userData = context.read<UserProvider>().userData;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ClientUnitPreferencesPage(
                                      initialHeightUnit: userData?['heightUnit'] as String? ?? 'cm',
                                      initialWeightUnit: userData?['weightUnit'] as String? ?? 'kg',
                                      initialDistanceUnit: userData?['distanceUnit'] as String? ?? 'km',
                                      initialTimeFormat: userData?['timeFormat'] as String? ?? '12-hour\n(1:30 PM)',
                                      initialDateFormat: userData?['dateFormat'] as String? ?? 'MM/DD/YYYY',
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildSettingItem(
                              icon: Icons.dark_mode_outlined,
                              title: l10n.dark_mode,
                              isSwitch: true,
                              onToggle: (value) {
                                themeProvider.toggleTheme();
                              },
                              value: themeProvider.isDarkMode,
                            ),
                          ],
                          Icons.dark_mode_outlined,
                        ),
                        _buildSection(
                          l10n.support,
                          [
                            _buildSettingItem(
                              icon: Icons.support_agent_outlined,
                              title: l10n.help_center,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HelpCenterPage(),
                                  ),
                                );
                              },
                            ),
                            _buildSettingItem(
                              icon: Icons.policy_outlined,
                              title: l10n.privacy_policy,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PrivacyPolicyPage(),
                                  ),
                                );
                              },
                            ),
                            _buildSettingItem(
                              icon: Icons.description_outlined,
                              title: l10n.terms_of_service,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TermsAndConditionsPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                          Icons.help_outline,
                        ),

                        _buildSection(
                          l10n.about_us,
                          [
                            /*
                            _buildSettingItem(
                              icon: Icons.info_outlined,
                              title: 'Our Story',
                              onTap: () {},
                            ),
                            */
                            
                            
                            _buildSettingItem(
                              icon: Icons.rate_review_outlined,
                              title: l10n.feedback,
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => const FeedbackSheet(),
                                );
                              },
                            ),
                            /*
                            _buildSettingItem(
                              icon: Icons.star_border_outlined,
                              title: l10n.rate_us,
                              onTap: () {},
                            ),
                            */
                            _buildSettingItem(
                              icon: Icons.question_mark_outlined,
                              title: l10n.faqs,
                              onTap: () {},
                            ),
                            _buildSettingItem(
                              icon: Icons.phone_android_outlined,
                              title: l10n.contact_us,
                              onTap: () {

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ContactInfoPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                          Icons.group_outlined,
                        ),

                        _buildSection(
                          l10n.sign_out,
                          [
                            _buildSettingItem(
                              icon: Icons.logout,
                              title: l10n.sign_out,
                              titleColor: myRed50,
                              onTap: () => _handleLogout(context),
                            ),
                          ],
                          Icons.logout,
                        ),
                        _buildSection(
                          l10n.danger_zone,
                          [
                            _buildSettingItem(
                              icon: Icons.delete_outline,
                              title: l10n.delete_account,
                              titleColor: Colors.red,
                              onTap: () => _handleDeleteAccount(context),
                              isDangerZone: true,
                            ),
                          ],
                          Icons.warning_rounded,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  AppBar _buildAppBarSettings(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return AppBar(
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(
            Icons.chevron_left,
            color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Text(
        l10n.settings,
        style: theme.appBarTheme.titleTextStyle,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
    );
  }

  Widget _buildSection(String title, List<Widget> items, IconData? icon) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 24, 16, 8),
                  child: Icon(icon, color: theme.brightness == Brightness.light ? myGrey40 : myGrey60, size: 20),
                ),
            ],
          ),
        ...items,
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    bool isSwitch = false,
    Function()? onTap,
    Function(bool)? onToggle,
    bool? value,
    bool isDangerZone = false,
  }) {
    final theme = Theme.of(context);
    
    return AnimatedContainer(
      duration: ThemeProvider.themeAnimationDuration,
      curve: ThemeProvider.themeAnimationCurve,
      margin: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 8),
      child: InkWell(
        onTap: isSwitch ? null : onTap,
        child: AnimatedContainer(
          duration: ThemeProvider.themeAnimationDuration,
          curve: ThemeProvider.themeAnimationCurve,
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDangerZone 
                ? myRed20 
                : theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: ThemeProvider.themeAnimationDuration,
                curve: ThemeProvider.themeAnimationCurve,
                alignment: Alignment.center,
                child: AnimatedContainer(
                  duration: ThemeProvider.themeAnimationDuration,
                  curve: ThemeProvider.themeAnimationCurve,
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDangerZone 
                        ? myRed50 
                        : theme.brightness == Brightness.light ? myGrey20 : myGrey80,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isDangerZone 
                        ? Colors.white 
                        : theme.brightness == Brightness.light ? myGrey80 : myGrey20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: ThemeProvider.themeAnimationDuration,
                      curve: ThemeProvider.themeAnimationCurve,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: titleColor ?? (isDangerZone ? myRed50 : theme.textTheme.bodyLarge?.color),
                        letterSpacing: -0.2,
                      ) ?? const TextStyle(),
                      child: Text(title),
                    ),
                  ],
                ),
              ),
              if (isSwitch)
                CustomToggleSwitch(
                  value: value ?? false,
                  onChanged: onToggle ?? (_) {},
                )
              else
                AnimatedSwitcher(
                  duration: ThemeProvider.themeAnimationDuration,
                  child: Icon(
                    Icons.chevron_right,
                    color: isDangerZone ? myRed50 : theme.iconTheme.color,
                    key: ValueKey<bool>(theme.brightness == Brightness.light),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}