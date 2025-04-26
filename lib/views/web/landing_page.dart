import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:naturafit/views/auth_side/select_role_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:naturafit/views/auth_side/email_auth_page.dart';
import 'package:country_flags/country_flags.dart';
import 'package:naturafit/services/locale_provider.dart';
import 'package:naturafit/views/all_shared_settings/language_settings_page.dart';
import 'package:naturafit/views/all_shared_settings/privacy_policy_page.dart';
import 'package:naturafit/views/all_shared_settings/terms_and_conditions.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
  
}


class _LandingPageState extends State<LandingPage> {
  /*
  @override
  void initState() async {
    super.initState();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('theme_mode', false);
      debugPrint('Theme preference set to false');
    } catch (e) {
      debugPrint('Error setting theme preference: $e');
    }
  }
  */
  
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(theme, l10n),
            _buildFeaturesSection(theme, l10n),
            _buildForWhoSection(theme, l10n),
            _buildTestimonialsSection(theme, l10n),
            _buildFAQSection(theme, l10n),
            _buildFooter(theme, l10n),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isNarrowScreen = MediaQuery.of(context).size.width < 900;
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      title: Row(
        children: [
          // Updated logo section
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              theme.brightness == Brightness.dark 
                  ? 'assets/darkTransparent.png'
                  : 'assets/lightTransparent.png',
              height: 56,
              width: 56,
              fit: BoxFit.contain,
            ),
          ),
          if (!isNarrowScreen) ...[
          const SizedBox(width: 12),
          Text(
            'NaturaFit',
            style: GoogleFonts.plusJakartaSans(
              color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: theme.brightness == Brightness.dark ? Colors.white : myBlue60, width: 1),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EmailAuthPage(isLogin: true),
              ),
            );
          },
          child: Text(
            l10n.login,
            style: GoogleFonts.plusJakartaSans(color: theme.brightness == Brightness.dark ? Colors.white : myBlue60),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(right: 32, left: 16),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmailAuthPage(isLogin: false),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: myBlue60,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              l10n.sign_up,
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(ThemeData theme, AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if screen is narrow
        final isNarrowScreen = constraints.maxWidth < 900;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
          child: isNarrowScreen
              ? Column( // Stack content vertically on narrow screens
                  children: [
                    _buildHeroContent(isNarrowScreen, theme, l10n),
                    const SizedBox(height: 40),
                    _buildHeroImage(theme, l10n),
                  ],
                )
              : Row( // Side by side on wider screens
                  children: [
                    Expanded(child: _buildHeroContent(isNarrowScreen, theme, l10n)),
                    const SizedBox(width: 40),
                    Expanded(child: _buildHeroImage(theme, l10n)),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildHeroContent(bool isNarrowScreen, ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: isNarrowScreen 
          ? CrossAxisAlignment.center 
          : CrossAxisAlignment.start,
      children: [
        Text(
          l10n.transform_your_fitness_business,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isNarrowScreen ? 36 : 48,
            fontWeight: FontWeight.bold,
            height: 1.2,
            color: theme.brightness == Brightness.dark ? Colors.white : Colors.black, 
          ),
          textAlign: isNarrowScreen ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 24),
        Text(
          l10n.streamline_your_coaching_practice,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isNarrowScreen ? 16 : 18,
            color: theme.brightness == Brightness.dark ? myGrey40 : myGrey60,
          ),
          textAlign: isNarrowScreen ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 32),
        Wrap(
          alignment: isNarrowScreen ? WrapAlignment.center : WrapAlignment.start,
          spacing: 16,
          runSpacing: 16,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmailAuthPage(isLogin: false),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: myBlue60,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: Text(
                l10n.get_started_free,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            /*
            OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.play_circle_outline, color: theme.brightness == Brightness.dark ? Colors.white : myBlue60),
              label: Text(
                'Watch Demo',
                style: GoogleFonts.plusJakartaSans(color: theme.brightness == Brightness.dark ? Colors.white : myBlue60),
              ),
            ),
            */
          ],
        ),
      ],
    );
  }

  Widget _buildHeroImage(ThemeData theme, AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate height based on width to maintain 16:9 aspect ratio
        final width = constraints.maxWidth;
        final height = (width * 9 / 16).clamp(0.0, 600.0); // Max height of 600px
        
        return Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              theme.brightness == Brightness.dark 
                  ? 'assets/hero_image_dark.png'
                  : 'assets/hero_image_light.png',
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    );
  }

  Widget _buildFeaturesSection(ThemeData theme, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
      color: theme.brightness == Brightness.dark ? myGrey90 : myGrey20,
      child: Column(
        children: [
          Text(
            'Everything You Need to Manage Your Fitness Business',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              height: 1.2,
              color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.powerful_features_to_help_you_grow_your_business_and_deliver_better_results,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              color: theme.brightness == Brightness.dark ? myGrey40 : myGrey60,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  _buildFeatureCard(
                    icon: Icons.people_outline,
                    title: l10n.client_management,
                    description: l10n.easily_manage_your_clients_track_their_progress_and_maintain_detailed_profiles,
                    maxWidth: constraints.maxWidth > 1200 ? 350 : 300,
                  ),
                  _buildFeatureCard(
                    icon: Icons.calendar_today,
                    title: l10n.smart_scheduling,
                    description: l10n.schedule_sessions_manage_availability_and_send_automatic_reminders,
                    maxWidth: constraints.maxWidth > 1200 ? 350 : 300,
                  ),
                  _buildFeatureCard(
                    icon: Icons.fitness_center,
                    title: l10n.workout_planning,
                    description: l10n.create_and_assign_personalized_workout_plans_with_our_intuitive_builder,
                    maxWidth: constraints.maxWidth > 1200 ? 350 : 300,
                  ),
                  _buildFeatureCard(
                    icon: Icons.restaurant_menu,
                    title: l10n.nutrition_tracking,
                    description: l10n.design_meal_plans_and_track_nutritional_progress_for_better_results,
                    maxWidth: constraints.maxWidth > 1200 ? 350 : 300,
                  ),
                  _buildFeatureCard(
                    icon: Icons.chat_bubble_outline,
                    title: l10n.client_communication,
                    description: l10n.built_in_messaging_system_to_stay_connected_with_your_clients,
                    maxWidth: constraints.maxWidth > 1200 ? 350 : 300,
                  ),
                  _buildFeatureCard(
                    icon: Icons.analytics_outlined,
                    title: l10n.progress_tracking,
                    description: l10n.track_and_visualize_client_progress_with_detailed_analytics_and_reports,
                    maxWidth: constraints.maxWidth > 1200 ? 350 : 300,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required double maxWidth,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: maxWidth,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? myGrey80 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark ? myBlue20 : myBlue20,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.brightness == Brightness.dark ? myBlue60 : myBlue60,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: theme.brightness == Brightness.dark ? myGrey40 : myGrey60,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForWhoSection(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
      child: Column(
        children: [
          Text(
            l10n.who_is_coachtrack_for('CoachTrack'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  _buildTargetUserCard(
                    icon: Icons.fitness_center,
                    title: l10n.personal_trainers,
                    points: [
                      l10n.independent_trainers_looking_to_grow_their_business,
                      l10n.gym_based_trainers_managing_multiple_clients,
                      l10n.online_coaches_expanding_their_reach,
                    ],
                    maxWidth: constraints.maxWidth > 1200 ? 350 : 300,
                  ),
                  _buildTargetUserCard(
                    icon: Icons.sports_gymnastics,
                    title: l10n.fitness_coaches,
                    points: [
                      l10n.crossfit_coaches_tracking_athlete_progress,
                      l10n.group_fitness_instructors_managing_classes,
                      l10n.sports_coaches_working_with_teams,
                    ],
                    maxWidth: constraints.maxWidth > 1200 ? 350 : 300,
                  ),
                  _buildTargetUserCard(
                    icon: Icons.restaurant_menu,
                    title: l10n.nutrition_coaches,
                    points: [
                      l10n.nutritionists_tracking_client_meal_plans,
                      l10n.diet_coaches_monitoring_progress,
                      l10n.wellness_coaches_offering_holistic_programs,
                    ],
                    maxWidth: constraints.maxWidth > 1200 ? 350 : 300,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTargetUserCard({
    required IconData icon,
    required String title,
    required List<String> points,
    required double maxWidth,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: maxWidth,
      height: 340,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? myGrey80 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.brightness == Brightness.dark ? myGrey40 : myGrey60),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.brightness == Brightness.dark ? myBlue60 : myBlue60, size: 32),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...points.map((point) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: theme.brightness == Brightness.dark ? myBlue60 : myBlue60,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        point,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          color: theme.brightness == Brightness.dark ? myGrey40 : myGrey60,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
      color: theme.brightness == Brightness.dark ? myGrey80 : myGrey20,
      child: Column(
        children: [
          Text(
            l10n.what_our_users_say,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  _buildTestimonialCard(
                    quote: l10n.coachtrack_has_transformed_how_i_manage_my_fitness_business_the_client_tracking_and_workout_planning_features_are_game_changers,
                    name: "Sarah Johnson",
                    role: l10n.personal_trainer,
                    imageUrl: "assets/sarah_trainer.png",
                    maxWidth: constraints.maxWidth > 1200 ? 350 : 300,
                  ),
                  _buildTestimonialCard(
                    quote: l10n.the_scheduling_system_alone_has_saved_me_hours_each_week_my_clients_love_the_easy_communication_and_progress_tracking,
                    name: "Mike Chen",
                    role: l10n.crossfit_coach,
                    imageUrl: "assets/mike_coach.png",
                    maxWidth: constraints.maxWidth > 1200 ? 350 : 300,
                  ),
                  _buildTestimonialCard(
                    quote: l10n.finally_a_platform_that_understands_what_fitness_professionals_need_the_meal_planning_features_are_exactly_what_i_was_looking_for,
                    name: "Emma Rodriguez",
                    role: l10n.nutrition_coach,
                    imageUrl: "assets/emma_nutritionist.png",
                    maxWidth: constraints.maxWidth > 1200 ? 350 : 300,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialCard({
    required String quote,
    required String name,
    required String role,
    required String imageUrl,
    required double maxWidth,
  }) {
    final theme = Theme.of(context);
    return VisibilityDetector(
      key: Key(name),
      onVisibilityChanged: (visibilityInfo) {
        // Add animation when card becomes visible
      },
      child: Container(
        width: maxWidth,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark ? myGrey70 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.format_quote,
              color: theme.brightness == Brightness.dark ? myBlue60 : myBlue60,
              size: 32,
            ),
            const SizedBox(height: 16),
            Text(
              quote,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: theme.brightness == Brightness.dark ? myGrey40 : myGrey60,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      role,
                      style: GoogleFonts.plusJakartaSans(
                        color: theme.brightness == Brightness.dark ? myGrey40 : myGrey60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection(ThemeData theme, AppLocalizations l10n) {
    final List<Map<String, String>> faqs = [
      {
        'question': l10n.how_do_i_get_started_with_coachtrack,
        'answer': l10n.simply_sign_up_for_a_free_account_complete_your_profile_and_start_adding_clients_our_intuitive_onboarding_process_will_guide_you_through_the_essential_features,
      },
      {
        'question': l10n.is_there_a_limit_to_how_many_clients_i_can_manage,
        'answer': l10n.during_our_initial_launch_period_you_can_manage_unlimited_clients_at_no_cost_we_ll_provide_advance_notice_before_introducing_any_limitations_or_pricing_tiers,
      },
      {
        'question': l10n.can_my_clients_access_their_workout_plans_and_progress,
        'answer': l10n.yes_clients_can_download_our_mobile_app_to_view_their_workout_plans_track_progress_and_communicate_with_you_directly,
      },
      {
        'question': l10n.what_platforms_does_coachtrack_support,
        'answer': l10n.coachtrack_is_available_on_web_ios_and_android_platforms_allowing_you_to_manage_your_business_from_anywhere,
      },
      {
        'question': l10n.how_secure_is_my_data,
        'answer': l10n.we_take_security_seriously_all_data_is_encrypted_and_stored_securely_using_industry_standard_protocols_and_compliant_with_privacy_regulations,
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
      child: Column(
        children: [
          Text(
            l10n.frequently_asked_questions,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: faqs
                      .map((faq) => _buildFAQItem(
                            question: faq['question']!,
                            answer: faq['answer']!,
                          ))
                      .toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.brightness == Brightness.dark ? myGrey40 : myGrey60),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: theme.brightness == Brightness.dark ? myGrey40 : myGrey60,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'native': 'English', 'country': 'GB'},
    {'code': 'es', 'name': 'Spanish', 'native': 'Español', 'country': 'ES'},
    {'code': 'fr', 'name': 'French', 'native': 'Français', 'country': 'FR'},
    {'code': 'de', 'name': 'German', 'native': 'Deutsch', 'country': 'DE'},
    {'code': 'it', 'name': 'Italian', 'native': 'Italiano', 'country': 'IT'},
    {'code': 'pt', 'name': 'Portuguese', 'native': 'Português', 'country': 'PT'},
    {'code': 'tr', 'name': 'Turkish', 'native': 'Türkçe', 'country': 'TR'},
  ];

  Widget _buildLanguageSelector() {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = context.watch<LocaleProvider>().locale;
    final currentLang = _languages.firstWhere(
      (lang) => lang['code'] == currentLocale?.languageCode,
      orElse: () => _languages.first,
    );

    return PopupMenuButton<String>(
      offset: const Offset(0, -180),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CountryFlag.fromCountryCode(
              currentLang['country']!,
              height: 16,
              width: 24,
            ),
            const SizedBox(width: 8),
            Text(
              currentLang['native']!,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => _languages.map((language) {
        return PopupMenuItem<String>(
          value: language['code'],
          child: Row(
            children: [
              CountryFlag.fromCountryCode(
                language['country']!,
                height: 16,
                width: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '${getLocalizedLanguage(l10n, language['name']!)} (${language['native']})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onSelected: (String langCode) async {
        await context.read<LocaleProvider>().setLocale(langCode);
      },
    );
  }

  Widget _buildFooter(ThemeData theme, AppLocalizations l10n) {
    final isNarrowScreen = MediaQuery.of(context).size.width < 900;
    return Container(
      width: double.infinity,
      color: theme.brightness == Brightness.dark ? myGrey90 : myGrey70,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Wrap(
                    spacing: 60,
                    runSpacing: 40,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children: [
                      _buildFooterSection(
                        title: 'Naturafit',
                        children: [
                          _buildFooterText(
                            l10n.empowering_fitness_professionals_to_deliver_exceptional_coaching_experiences,
                            maxWidth: 300,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildSocialIcon(Icons.facebook, 'https://facebook.com'),
                              const SizedBox(width: 16),
                              _buildSocialIcon(Icons.flutter_dash_outlined, 'https://x.com'),
                              const SizedBox(width: 16),
                              _buildSocialIcon(Icons.camera_alt_outlined, 'https://instagram.com'),
                              const SizedBox(width: 16),
                              _buildSocialIcon(Icons.work_outline, 'https://linkedin.com'),
                            ],
                          ),
                        ],
                      ),
                      /*
                      _buildFooterSection(
                        title: 'Company',
                        children: [
                          _buildFooterLink('About Us', () {}),
                          _buildFooterLink('Careers', () {}),
                          _buildFooterLink('Blog', () {}),
                          _buildFooterLink('Press', () {}),
                        ],
                      ),
                      _buildFooterSection(
                        title: 'Resources',
                        children: [
                          _buildFooterLink('Help Center', () {}),
                          _buildFooterLink('Documentation', () {}),
                          _buildFooterLink('API Reference', () {}),
                          _buildFooterLink('Status', () {}),
                        ],
                      ),
                      _buildFooterSection(
                        title: 'Legal',
                        children: [
                          _buildFooterLink('Privacy Policy', () {}),
                          _buildFooterLink('Terms of Service', () {}),
                          _buildFooterLink('Cookie Policy', () {}),
                          _buildFooterLink('GDPR', () {}),
                        ],
                      ),
                      */
                      _buildFooterSection(
                        title: 'Download the App',
                        children: [
                          _buildAppStoreButtons(),
                        ],
                      ),
                      _buildFooterSection(
                        title: 'Contact',
                        children: [
                          _buildFooterText('support@naturafit.app'),
                        ],
                      ),
                      
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 64),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.only(top: 32),
            child: isNarrowScreen 
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PrivacyPolicyPage(),
                              ),
                            );
                          },
                          child: Text(
                            l10n.privacy_policy,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TermsAndConditionsPage(),
                              ),
                            );
                          },
                          child: Text(
                            l10n.terms_and_conditions,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '© ${DateTime.now().year} NaturaFit. ${l10n.all_rights_reserved}',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLanguageSelector(),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLanguageSelector(),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PrivacyPolicyPage(),
                              ),
                            );
                          },
                          child: Text(
                            l10n.privacy_policy,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TermsAndConditionsPage(),
                              ),
                            );
                          },
                          child: Text(
                            l10n.terms_and_conditions,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '© ${DateTime.now().year} NaturaFit. ${l10n.all_rights_reserved}',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }

  Widget _buildFooterLink(String text, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterText(String text, {double? maxWidth}) {
    return Container(
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white.withOpacity(0.8),
          fontSize: 16,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, String url) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url));
          }
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildAppStoreButtons() {
    return SizedBox(
      width: 280,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStoreButton(
              'assets/app-store-badge.png',
              'Download on the App Store',
              'https://apps.apple.com/app/naturafit',
            ),
            const SizedBox(height: 12),
            _buildStoreButton(
              'assets/google-play-badge.png',
              'Get it on Google Play',
              'https://play.google.com/store/apps/details?id=com.naturafit',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreButton(String assetPath, String alt, String url) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url));
          }
        },
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              alt,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 