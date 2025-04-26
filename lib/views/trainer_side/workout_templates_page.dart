import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/views/trainer_side/workout_plan_details_page.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WorkoutTemplatesPage extends StatefulWidget {
  const WorkoutTemplatesPage({Key? key}) : super(key: key);

  @override
  State<WorkoutTemplatesPage> createState() => _WorkoutTemplatesPageState();
}

class _WorkoutTemplatesPageState extends State<WorkoutTemplatesPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final workoutPlans = context.watch<UserProvider>().workoutPlans ?? [];
    final templates = workoutPlans.where((plan) => plan['status'] == 'template').toList();
    
    // Filter templates based on search
    final filteredTemplates = templates.where((template) {
      return _searchController.text.isEmpty ||
          template['planName'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Row(
          children: [
            Text(
              l10n.templates_title,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.fitness_center_outlined, color: Colors.white),
          ],
        ),
        backgroundColor: myBlue60,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to create template page
              },
              label: Text(
                l10n.create_template,
                style: GoogleFonts.plusJakartaSans(),
              ),
              icon: const Icon(
                Icons.add,
                size: 18,
                color: Colors.white,
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                foregroundColor: Colors.white,
                backgroundColor: myBlue60,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white, width: 1),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: myBlue60,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: CustomFocusTextField(
                    label: '',
                    hintText: l10n.search_templates,
                    controller: _searchController,
                    prefixIcon: Icons.search,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: filteredTemplates.isEmpty
                ? _buildEmptyState(theme)
                : _buildTemplatesList(filteredTemplates, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesList(List<Map<String, dynamic>> templates, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(template, theme);
      },
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: theme.cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TrainerWorkoutPlanDetailsPage(planData: template),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light ? myGrey70 : myGrey90,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      template['planName'] ?? l10n.unnamed_template,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  /*
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${template['exercises']?.length ?? 0} exercises',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  */
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (template['goal'] != null && template['goal'].toString().isNotEmpty)
                    _buildTemplateDetail(
                      Icons.track_changes_outlined,
                      'Goal',
                      template['goal'],
                      theme,
                    ),
                  if (template['duration'] != null && template['duration'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildTemplateDetail(
                      Icons.timer_outlined,
                      'Duration',
                      template['duration'],
                      theme,
                    ),
                  ],
                  if (template['difficulty'] != null && template['difficulty'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildTemplateDetail(
                      Icons.fitness_center_outlined,
                      'Difficulty',
                      template['difficulty'],
                      theme,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateDetail(IconData icon, String label, String value, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    String localizedLabel;
    switch (label.toLowerCase()) {
      case 'goal':
        localizedLabel = l10n.goal_section;
        break;
      case 'duration':
        localizedLabel = l10n.duration_section;
        break;
      case 'difficulty':
        localizedLabel = l10n.difficulty_section;
        break;
      default:
        localizedLabel = label;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light ? myGrey20 : myGrey80,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: theme.brightness == Brightness.light ? myGrey70 : myGrey30,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizedLabel.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodySmall?.color,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 64,
            color: theme.brightness == Brightness.light ? myGrey40 : myGrey60,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.no_templates,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.create_first_template,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
} 