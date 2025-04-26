import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/views/trainer_side/add_exercise_page.dart';
import 'package:naturafit/widgets/custom_video_player.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ExerciseResourcesPage extends StatefulWidget {
  const ExerciseResourcesPage({Key? key}) : super(key: key);

  @override
  State<ExerciseResourcesPage> createState() => _ExerciseResourcesPageState();
}

class _ExerciseResourcesPageState extends State<ExerciseResourcesPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> exercises = [];
  bool isLoading = true;
  Set<String> _expandedCards = {};
  Set<String> _updatingBookmarks = {};

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchExercises() async {
    try {
      final userData = context.read<UserProvider>().userData;
      final trainerId = userData?['userId'];
      if (trainerId == null) return debugPrint('trainerId is null');

      final snapshot = await FirebaseFirestore.instance
          .collection('trainer_exercises')
          .doc(trainerId)
          .collection('all_exercises')
          .get();

      setState(() {
        exercises = snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle error
    }
  }

  List<Map<String, dynamic>> getFilteredExercises() {
    if (_searchController.text.isEmpty) return exercises;
    
    return exercises.where((exercise) {
      final name = exercise['name']?.toString().toLowerCase() ?? '';
      final category = exercise['category']?.toString().toLowerCase() ?? '';
      final searchTerm = _searchController.text.toLowerCase();
      
      return name.contains(searchTerm) || category.contains(searchTerm);
    }).toList();
  }

  String _formatSets(String setsString) {
    try {
      // Remove any whitespace and clean up the string
      final cleanString = setsString.trim().replaceAll(' ', '');
      if (cleanString.isEmpty || cleanString == '[]') return '';

      // Parse the string into structured data
      final List<Map<String, dynamic>> sets = [];
      final setMatches = RegExp(r'{([^}]+)}').allMatches(cleanString);
      
      for (var match in setMatches) {
        final setStr = match.group(1);
        if (setStr != null) {
          final set = <String, dynamic>{};
          final pairs = setStr.split(',');
          
          for (var pair in pairs) {
            final keyValue = pair.split(':');
            if (keyValue.length == 2) {
              final key = keyValue[0].trim();
              final value = keyValue[1].trim();
              set[key] = value;
            }
          }
          
          if (set.isNotEmpty) {
            sets.add(set);
          }
        }
      }

      // Format each set into a readable string
      return sets.map((set) {
        final reps = set['reps']?.toString().replaceAll('"', '') ?? '';
        final weight = set['weight']?.toString().replaceAll('"', '') ?? '';
        final rest = set['rest']?.toString().replaceAll('"', '') ?? '';
        
        return '${sets.indexOf(set) + 1}. $reps reps'
            '${weight.isNotEmpty ? ' @ ${weight}kg' : ''}'
            '${rest.isNotEmpty ? ' (Rest: $rest)' : ''}';
      }).join('\n');
    } catch (e) {
      debugPrint('Error formatting sets: $e');
      return setsString;
    }
  }

  Future<void> _toggleBookmark(Map<String, dynamic> exercise) async {
    final l10n = AppLocalizations.of(context)!;
    final exerciseId = exercise['exerciseId'] ?? exercise['id'];
    if (exerciseId == null) return debugPrint('exerciseId is null');
    
    if (_updatingBookmarks.contains(exerciseId)) return;

    try {
      setState(() {
        _updatingBookmarks.add(exerciseId);
      });

      final userData = context.read<UserProvider>().userData;
      final trainerId = userData?['userId'];
      if (trainerId == null) return debugPrint('trainerId is null');

      final isCurrentlyBookmarked = exercise['isBookmarked'] == true;
      
      // Update Firestore
      await FirebaseFirestore.instance
          .collection('trainer_exercises')
          .doc(trainerId)
          .collection('all_exercises')
          .doc(exerciseId)
          .update({'isBookmarked': !isCurrentlyBookmarked});

      // Update local state
      if (mounted) {
        setState(() {
          final index = exercises.indexWhere((e) => (e['exerciseId'] ?? e['id']) == exerciseId);
          if (index != -1) {
            exercises[index] = {
              ...exercises[index],
              'isBookmarked': !isCurrentlyBookmarked,
            };
          }
          _updatingBookmarks.remove(exerciseId);
        });
      }
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      if (mounted) {
        setState(() {
          _updatingBookmarks.remove(exerciseId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.exercise,
            message: l10n.failed_update_bookmark,
            type: SnackBarType.error,
          ),
        );
      }
    }
  }

  // Add this method to handle full screen image view
  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                // Center image with pinch to zoom
                Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      height: double.infinity,
                      width: double.infinity,
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
                ),
                    
                
                // Close button
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final filteredExercises = getFilteredExercises();

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
              l10n.exercises,
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddExercisePage(),
                  ),
                ).then((added) {
                  if (added == true) {
                    // Refresh exercises list
                    _fetchExercises();
                  }
                });
              },
              label: Text(
                l10n.add,
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
            decoration: BoxDecoration(
              color: myBlue60,
              borderRadius: const BorderRadius.only(
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
                    hintText: l10n.search_exercises,
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
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredExercises.isEmpty
                    ? _buildEmptyState()
                    : _buildExercisesList(filteredExercises),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList(List<Map<String, dynamic>> exercises) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return _buildExerciseCard(exercise);
      },
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isExpanded = _expandedCards.contains(exercise['exerciseId'] ?? exercise['id']);
    final hasInstructions = exercise['instructions'] != null && 
                          exercise['instructions'].toString().isNotEmpty && 
                          exercise['instructions'].toString() != '[]';
    final hasSets = exercise['sets'] != null && 
                    exercise['sets'].toString().isNotEmpty && 
                    exercise['sets'].toString() != '[]';
    
    // Add these checks for media
    final hasVideo = exercise['videoUrl'] != null && exercise['videoUrl'] != '' && exercise['videoUrl'] != 'null';
    final hasImages = (exercise['imageUrls'] as List?)?.isNotEmpty ?? false;

    return GestureDetector(
      onTap: () {
        setState(() {
          final id = exercise['exerciseId'] ?? exercise['id'];
          if (isExpanded) {
            _expandedCards.remove(id);
          } else {
            _expandedCards.add(id);
          }
        });
      },
      child: Card(
        color: theme.cardColor,
        margin: const EdgeInsets.only(bottom: 24),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light ? myGrey70 : myGrey90,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(
                  bottom: BorderSide(
                    color: theme.brightness == Brightness.light ? myGrey30 : myGrey80,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      exercise['name'] ?? l10n.unnamed_exercise,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _buildBookmarkIcon(exercise),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddExercisePage(
                                    isEditing: true,
                                    exerciseToEdit: exercise,
                                  ),
                                ),
                              ).then((edited) {
                                if (edited == true) {
                                  // Refresh exercises list
                                  _fetchExercises();
                                }
                              });
                            },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            AnimatedCrossFade(
              firstChild: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Only show equipment in collapsed view
                    if (exercise['equipment'] != null && exercise['equipment'].toString().isNotEmpty)
                      _buildPlanDetail(
                        Icons.sports_gymnastics,
                        l10n.equipment_title,
                        exercise['equipment'].toString(),
                      ),
                  ],
                ),
              ),
              secondChild: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show media first in expanded view
                    if (hasVideo) ...[
                      const SizedBox(height: 12),
                      CustomVideoPlayer(
                        videoUrl: exercise['videoUrl'],
                        width: double.infinity,
                        showControls: true,
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    if (hasImages) ...[
                      SizedBox(
                        height: 100, // Reduced height for thumbnails
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: (exercise['imageUrls'] as List).length,
                          itemBuilder: (context, index) {
                            final imageUrl = (exercise['imageUrls'] as List)[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                right: index < (exercise['imageUrls'] as List).length - 1 ? 8.0 : 0,
                              ),
                              child: GestureDetector(
                                onTap: () => _showFullScreenImage(imageUrl),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    //border: Border.all(color: myGrey30),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      height: 100,
                                      width: 100,
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
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Show other details after media
                    if (exercise['equipment'] != null && exercise['equipment'].toString().isNotEmpty)
                      _buildPlanDetail(
                        Icons.sports_gymnastics,
                        l10n.equipment_title,
                        exercise['equipment'].toString(),
                      ),
                    if (hasSets) ...[
                      const SizedBox(height: 12),
                      _buildPlanDetail(
                        Icons.repeat,
                        l10n.sets_title,
                        _formatSets(exercise['sets'].toString()),
                      ),
                    ],
                    if (hasInstructions) ...[
                      const SizedBox(height: 12),
                      _buildPlanDetail(
                        Icons.list_alt,
                        l10n.instructions_title,
                        exercise['instructions'].toString(),
                      ),
                    ],
                  ],
                ),
              ),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light ? myGrey20 : myGrey80,
                border: Border(
                  top: BorderSide(
                    color: theme.brightness == Brightness.light ? myGrey30 : myGrey70,
                  ),
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (exercise['usageCount'] != null)
                    Text(
                      l10n.used_times(exercise['usageCount']),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: theme.textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.textTheme.bodySmall?.color,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkIcon(Map<String, dynamic> exercise) {
    final exerciseId = exercise['exerciseId'] ?? exercise['id'];
    final isUpdating = _updatingBookmarks.contains(exerciseId);

    return GestureDetector(
      onTap: isUpdating ? null : () => _toggleBookmark(exercise),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isUpdating)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(
                  exercise['isBookmarked'] == true 
                      ? Icons.bookmark 
                      : Icons.bookmark_outline,
                  color: Colors.white,
                  size: 16,
                ),
            ],
          ),
      ),
    );
  }

  Widget _buildPlanDetail(IconData icon, String label, String value) {
    final theme = Theme.of(context);
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
                label.toUpperCase(),
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
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
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
            l10n.no_exercises_yet,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.add_first_exercise,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
} 