import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_search_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/views/trainer_side/workout_templates_page.dart';
import 'package:naturafit/views/trainer_side/meal_templates_page.dart';
import 'package:naturafit/views/trainer_side/exercise_resources_page.dart';
import 'package:naturafit/views/trainer_side/meal_resources_page.dart';
import 'package:naturafit/views/trainer_side/exercise_images_page.dart';
import 'package:naturafit/views/trainer_side/exercise_videos_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ResourcesPage extends StatelessWidget {
  const ResourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          l10n.resources,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        centerTitle: false,
      ),
      
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: CustomFocusTextField(
              label: '', 
              hintText: l10n.search_resources, 
              prefixIcon: Icons.search, 
              controller: TextEditingController()
            )
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResourceSection(
                    l10n.templates_section,
                    [
                      _ResourceItem(
                        icon: Icons.fitness_center,
                        color: myBlue60,
                        title: l10n.workout_plan_title,
                        subtitle: '12 templates',
                      ),
                      _ResourceItem(
                        icon: Icons.restaurant_menu,
                        color: myGreen50,
                        title: l10n.meal_plan_title,
                        subtitle: '8 templates',
                      ),
                    ],
                    context,
                  ),
                  const SizedBox(height: 24),
                  _buildResourceSection(
                    l10n.database_section,
                    [
                      _ResourceItem(
                        icon: Icons.fitness_center,
                        color: myPurple50,
                        title: l10n.exercises_title_resources,
                        subtitle: '156 exercises',
                      ),
                      _ResourceItem(
                        icon: Icons.lunch_dining,
                        color: myYellow50,
                        title: l10n.meals_title,
                        subtitle: '89 meals',
                      ),
                    ],
                    context,
                  ),
                  const SizedBox(height: 24),
                  _buildResourceSection(
                    l10n.exercise_library_section,
                    [
                      _ResourceItem(
                        icon: Icons.video_library,
                        color: myRed50,
                        title: l10n.videos_title,
                        subtitle: '45 videos',
                      ),
                      _ResourceItem(
                        icon: Icons.photo_library,
                        color: myTeal30,
                        title: l10n.images_title,
                        subtitle: '120 images',
                      ),
                      /*
                      _ResourceItem(
                        icon: Icons.description,
                        color: myYellow50,
                        title: 'Descriptions',
                        subtitle: '85 exercises',
                      ),
                      */
                    ],
                    context,
                  ),
                  /*
                  const SizedBox(height: 24),
                  _buildResourceSection(
                    'Documents',
                    [
                      _ResourceItem(
                        icon: Icons.picture_as_pdf,
                        color: myRed50,
                        title: 'PDF Resources',
                        subtitle: '15 files',
                      ),
                      _ResourceItem(
                        icon: Icons.article,
                        color: myBlue50,
                        title: 'Articles & Guides',
                        subtitle: '23 documents',
                      ),
                      _ResourceItem(
                        icon: Icons.assignment,
                        color: myGreen50,
                        title: 'Client Forms',
                        subtitle: '7 forms',
                      ),
                    ],
                    context,
                  ),
                  const SizedBox(height: 24),
                  _buildResourceSection(
                    'Client Resources',
                    [
                      _ResourceItem(
                        icon: Icons.book,
                        color: myPurple50,
                        title: 'Educational',
                        subtitle: '18 resources',
                      ),
                      _ResourceItem(
                        icon: Icons.timeline,
                        color: myTeal30,
                        title: 'Progress Trackers',
                        subtitle: '9 templates',
                      ),
                      _ResourceItem(
                        icon: Icons.calendar_today,
                        color: myYellow50,
                        title: 'Schedule Templates',
                        subtitle: '6 templates',
                      ),
                    ],
                    context,
                  ),
                  */
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceSection(String title, List<_ResourceItem> items, BuildContext context) {
    final theme = Theme.of(context);
    final myIsWebOrDektop = isWebOrDesktopCached;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: myIsWebOrDektop ? 20 : 18,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
            /*
            TextButton(
              onPressed: () {
                // View all items in this section
              },
              child: Text(
                'View All',
                style: GoogleFonts.plusJakartaSans(
                  color: myBlue60,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            */
          ],
        ),
        const SizedBox(height: 0),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: items.map((item) => _buildResourceCard(item, context)).toList(),
        ),
      ],
    );
  }

  Widget _buildResourceCard(_ResourceItem item, BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final webScreenWidth = MediaQuery.of(context).size.width;
    final myIsWebOrDektop = isWebOrDesktopCached;

    final isSmall = webScreenWidth*0.8 < 600;

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle resource item tap
            if (item.title == l10n.workout_plan_title) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorkoutTemplatesPage(),
                ),
              );
            } else if (item.title == l10n.meal_plan_title) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MealTemplatesPage(),
                ),
              );
            } else if (item.title == l10n.exercises_title_resources) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExerciseResourcesPage(),
                ),
              );
            } else if (item.title == l10n.meals_title) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MealResourcesPage(),
                ),
              );
            } else if (item.title == l10n.images_title) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExerciseImagesPage(),
                ),
              );
            } else if (item.title == l10n.videos_title) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExerciseVideosPage(),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: myIsWebOrDektop ? MainAxisAlignment.center : MainAxisAlignment.start,
              crossAxisAlignment: myIsWebOrDektop ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.color,
                    size: myIsWebOrDektop ? 40 : 20,
                  ),
                ),
                if (!myIsWebOrDektop)
                const Spacer(),
                if (!isSmall || !myIsWebOrDektop)
                Text(
                  item.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: myIsWebOrDektop ? 28 : 20,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                /*
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
                */
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResourceItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  _ResourceItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}