import 'package:naturafit/services/unit_preferences.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/widgets/image_gallery_screen.dart';
import 'package:naturafit/widgets/video_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:naturafit/widgets/custom_video_player.dart';

class WorkoutPhaseCard extends StatelessWidget {
  final Map<String, dynamic> phase;
  final EdgeInsetsGeometry? padding;
  final Widget Function(Map<String, dynamic>)? exerciseBuilder;

  const WorkoutPhaseCard({
    Key? key,
    required this.phase,
    this.padding,
    this.exerciseBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      color: theme.cardColor,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phase header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light ? myGrey70 : myGrey80,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(
                  color: theme.brightness == Brightness.light ? myGrey30 : myGrey70,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        phase['name'].toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: theme.brightness == Brightness.light ? myGrey10 : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.light ? myGrey20 : myGrey70,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${phase['exercises']?.length ?? 0} ${l10n.exercises}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: theme.brightness == Brightness.light ? myGrey70 : myGrey20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _getPhaseIcon(phase['name']),
                  size: 18,
                  color: theme.brightness == Brightness.light ? myGrey30 : myGrey50,
                ),
              ],
            ),
          ),
          
          // Exercises
          if (phase['exercises']?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...phase['exercises'].map((exercise) => Padding(
                    padding: padding ?? EdgeInsets.zero,
                    child: exerciseBuilder != null 
                      ? exerciseBuilder!(exercise)
                      : WorkoutExerciseCard(exercise: exercise),
                  )).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getPhaseIcon(String phaseName) {
    switch (phaseName.toLowerCase()) {
      case 'warm up phase':
        return Icons.whatshot_outlined;
      case 'main workout phase':
        return Icons.fitness_center_outlined;
      case 'cool down phase':
        return Icons.ac_unit_outlined;
      default:
        return Icons.fitness_center_outlined;
    }
  }
}

class WorkoutExerciseCard extends StatelessWidget {
  final Map<String, dynamic> exercise;

  const WorkoutExerciseCard({
    Key? key,
    required this.exercise,
  }) : super(key: key);

  String _formatSetsInfo(List<Map<String, dynamic>> sets, BuildContext context) {
    if (sets.isEmpty) return '';
    
    final userData = Provider.of<UserProvider>(context).userData;
    final weightUnit = userData?['weightUnit'];
    final unitPrefs = Provider.of<UnitPreferences>(context, listen: false);
    
    bool allSetsIdentical = sets.every((set) =>
        set['reps'] == sets[0]['reps'] &&
        set['weight'] == sets[0]['weight'] &&
        set['rest'] == sets[0]['rest']);

    if (allSetsIdentical) {
      return '${sets.length}×${sets[0]['reps']} reps @ ${weightUnit == 'kg' ? ((double.parse(sets[0]['weight'])*2).round()/2).toStringAsFixed(1) : unitPrefs.kgToLbs(double.parse(sets[0]['weight'])).toStringAsFixed(0)} $weightUnit';
    } else {
      return sets.map((set) => 
        '${set['reps']} reps @ ${weightUnit == 'kg' ? ((double.parse(set['weight'])*2).round()/2).toStringAsFixed(1) : unitPrefs.kgToLbs(double.parse(set['weight'])).toStringAsFixed(0)} $weightUnit'
      ).join('\n');
    }
  }

  IconData _getExerciseIcon(String? equipment) {
    if (equipment == null || equipment.isEmpty) {
      return Icons.fitness_center_outlined;
    } else {
      return Icons.fitness_center;
    }
  }

  void _showFullScreenVideo(BuildContext context, String videoUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            elevation: 0,
          ),
          body: SafeArea(
            child: Center(
              child: CustomVideoPlayer(
                videoUrl: videoUrl,
                showControls: true,
                showFullscreenButton: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullScreenImages(BuildContext context, List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ImageGalleryScreen(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.light ? myGrey30 : myGrey70,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Equipment icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.light ? myGrey20 : myGrey80,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getExerciseIcon(exercise['equipment']),
                        color: theme.brightness == Brightness.light ? myGrey80 : myGrey30,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Exercise name and details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise['name'] ?? '',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (exercise['equipment']?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 4),
                            Text(
                              exercise['equipment'],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                              ),
                            ),
                          ],
                          
                          
                        ],
                      ),
                    ),
                  ],
                ),


                // Add Video and Images buttons if available
                      if ((exercise['videoUrl']?.isNotEmpty ?? false) || 
                          (exercise['imageUrls']?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (exercise['videoUrl']?.isNotEmpty ?? false)
                              IconButton(
                                onPressed: () => _showFullScreenVideo(
                                  context,
                                  exercise['videoUrl'],
                                ),
                                icon: const Icon(Icons.play_circle_outline),
                                iconSize: 20,
                                color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            if ((exercise['videoUrl']?.isNotEmpty ?? false) && 
                                (exercise['imageUrls']?.isNotEmpty ?? false))
                              const SizedBox(width: 4),
                            if (exercise['imageUrls']?.isNotEmpty ?? false)
                              GestureDetector(
                                onTap: () => _showFullScreenImages(
                                  context,
                                  List<String>.from(exercise['imageUrls']),
                                  0,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.brightness == Brightness.light ? myGrey20 : myGrey80,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.photo_library_outlined,
                                        size: 16,
                                        color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${(exercise['imageUrls'] as List?)?.length ?? 0}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
              ],
            ),
          ),

          // Sets information
          if (exercise['sets']?.isNotEmpty ?? false)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light ? myGrey20 : myGrey80,
                border: Border(
                  top: BorderSide(
                    color: theme.brightness == Brightness.light ? myGrey30 : myGrey70,
                  ),
                  bottom: exercise['instructions']?.isNotEmpty ?? false 
                    ? BorderSide(
                        color: theme.brightness == Brightness.light ? myGrey30 : myGrey70,
                      )
                    : BorderSide.none,
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.fitness_center_outlined, 
                    size: 16,
                    color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatSetsInfo(List<Map<String, dynamic>>.from(exercise['sets']), context),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

          // Instructions
          if (exercise['instructions']?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.instructions,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List<String>.from(exercise['instructions']).asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key + 1}. ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
} 