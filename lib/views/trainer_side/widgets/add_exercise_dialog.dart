import 'dart:io';
import 'package:naturafit/models/workout_models.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:naturafit/models/exercise_set.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_select_exercise_textfield.dart';
import 'package:naturafit/widgets/custom_select_textfield.dart';
import 'package:naturafit/widgets/custom_top_selector.dart';
import 'package:naturafit/widgets/custom_video_player.dart';
import 'package:naturafit/views/trainer_side/widgets/exercise_sets_view.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/services/unit_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';

class AddExerciseDialog extends StatefulWidget {
  final List<Map<String, dynamic>> trainerExercises;
  final List<String> equipmentTypes;
  final Function(Map<String, dynamic> exercise) onAdd;
  final bool isEditing;
  final Exercise? existingExercise;

  const AddExerciseDialog({
    Key? key,
    required this.trainerExercises,
    required this.equipmentTypes,
    required this.onAdd,
    this.isEditing = false,
    this.existingExercise,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required List<Map<String, dynamic>> trainerExercises,
    required List<String> equipmentTypes,
    required Function(Map<String, dynamic> exercise) onAdd,
    bool isEditing = false,
    Exercise? existingExercise,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddExerciseDialog(
        trainerExercises: trainerExercises,
        equipmentTypes: equipmentTypes,
        onAdd: onAdd,
        isEditing: isEditing,
        existingExercise: existingExercise,
      ),
    );
  }

  @override
  State<AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<AddExerciseDialog> {
  String exerciseName = '';
  String? exerciseId;
  String? selectedEquipment;
  Map<String, dynamic>? selectedExercise;
  List<ExerciseSet> exerciseSets = [
    ExerciseSet(),
    ExerciseSet(),
    ExerciseSet(),
  ];
  List<String> instructions = [];
  File? videoFile;
  List<File> imageFiles = [];
  final instructionController = TextEditingController();
  final ImagePicker picker = ImagePicker();
  int selectedTopSelectorIndex = 0;
  bool hasChanged = false;
  bool hasNameChanged = false;
  Map<String, dynamic>? originalExercise; // To store initial state

  List<TopSelectorOption> _getTopSelectorOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      TopSelectorOption(title: l10n.basic),
      TopSelectorOption(title: l10n.media),
      TopSelectorOption(title: l10n.instructions),
    ];
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.existingExercise != null) {
      exerciseName = widget.existingExercise!.name;
      exerciseId = widget.existingExercise!.exerciseId;
      selectedEquipment = widget.existingExercise!.equipment;

      // Initialize instructions
      instructions = List<String>.from(widget.existingExercise!.instructions);
      
      // Initialize media
      videoFile = widget.existingExercise!.videoFile;
      imageFiles = List<File>.from(widget.existingExercise!.imageFiles);
      
      // Set selected exercise if it exists in trainer exercises
      if (exerciseId != null) {
        selectedExercise = widget.trainerExercises.firstWhere(
          (e) => e['exerciseId'] == exerciseId,
          orElse: () => {
            'exerciseId': exerciseId,
            'name': exerciseName,
            'equipment': selectedEquipment,
            'sets': exerciseSets.map((s) => s.toMap()).toList(),
            'instructions': instructions,
            'videoFile': widget.existingExercise!.videoFile,
            'imageFiles': widget.existingExercise!.imageFiles,
          },
        );
      }
    }
  }

  void _checkForChanges() {
    if (selectedExercise == null) return;
    
    if (originalExercise == null) {
      // Store original state when first selecting an exercise
      originalExercise = {
        'name': exerciseName,
        'equipment': selectedEquipment,
        'sets': exerciseSets.map((s) => {
          'reps': s.repsController.text,
          'weight': s.weightController.text,
          'rest': s.restController.text,
        }).toList(),
        'instructions': List<String>.from(instructions),
        'videoFile': videoFile?.path,
        'imageFiles': imageFiles.map((f) => f.path).toList(),
      };
      return;
    }

    bool changed = false;

    if (exerciseName != originalExercise!['name']) {
      hasNameChanged = true;
    }

    // Check each field for changes
    if (exerciseName != originalExercise!['name'] ||
        selectedEquipment != originalExercise!['equipment'] ||
        !_areListsEqual(instructions, originalExercise!['instructions']) ||
        videoFile?.path != originalExercise!['videoFile'] ||
        !_areListsEqual(
          imageFiles.map((f) => f.path).toList(),
          originalExercise!['imageFiles']
        )) {
      changed = true;
    }

    // Check sets separately
    if (!changed) {
      final originalSets = originalExercise!['sets'] as List;
      if (exerciseSets.length != originalSets.length) {
        changed = true;
      } else {
        for (int i = 0; i < exerciseSets.length; i++) {
          final currentSet = exerciseSets[i];
          final originalSet = originalSets[i] as Map<String, dynamic>;
          if (currentSet.repsController.text != originalSet['reps'] ||
              currentSet.weightController.text != originalSet['weight'] ||
              currentSet.restController.text != originalSet['rest']) {
            changed = true;
            break;
          }
        }
      }
    }

    if (changed != hasChanged) {
      hasChanged = changed;
      debugPrint('hasChanged: $hasChanged');
      if (hasChanged) {
        exerciseId = null;  // Clear exerciseId if changes detected
      }
    }
  }

  bool _areListsEqual(List? list1, List? list2) {
    if (list1 == null && list2 == null) return true;
    if (list1 == null || list2 == null) return false;
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].toString() != list2[i].toString()) return false;
    }
    return true;
  }

  Map<String, dynamic> _convertSetWeights(Map<String, dynamic> set, UnitPreferences unitPrefs) {
    if (set['weight'] != null && set['weight'].isNotEmpty) {
      // Convert from lbs to kg if needed
      double weightLbs = double.tryParse(set['weight']) ?? 0;
      double weightKg = unitPrefs.lbsToKg(weightLbs);
      return {
        ...set,
        'weight': weightKg.toStringAsFixed(1),
      };
    }
    return set;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final screenWidth = MediaQuery.of(context).size.width;
    double videoWidth = screenWidth < 800 ? screenWidth * 0.5 : 400;






    final userData = Provider.of<UserProvider>(context).userData;
    
    if (widget.isEditing && widget.existingExercise != null) {
      final weightUnit = userData?['weightUnit'];
      final unitPrefs = Provider.of<UnitPreferences>(context, listen: false);
      
      // Initialize sets
      exerciseSets.forEach((set) => set.dispose());

      exerciseSets = widget.existingExercise!.sets.map((setData) => ExerciseSet(
        reps: setData['reps'],
        weight: weightUnit == 'kg' ? setData['weight'] : unitPrefs.kgToLbs(double.parse(setData['weight'])).toStringAsFixed(0),
        rest: setData['rest'],
      )).toList();
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        border: Border.all(color: theme.brightness == Brightness.light ? myGrey20 : myGrey80),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light ? Colors.grey[300] : myGrey80,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.fitness_center, color: theme.brightness == Brightness.light ? myBlue60 : myGrey50, size: 24),
                const SizedBox(width: 12),
                Text(
                  widget.isEditing ? l10n.edit_exercise : l10n.add_exercise,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: CustomTopSelector(
              options: _getTopSelectorOptions(context),
              selectedIndex: selectedTopSelectorIndex,
              onOptionSelected: (value) {
                setState(() {
                  selectedTopSelectorIndex = value;
                });
              },
            ),
          ),

          if (selectedTopSelectorIndex == 0) ...[
            // Basic Info
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    CustomSelectExerciseMealTextField(
                      isExercise: true,
                      label: l10n.exercise_name,
                      hintText: l10n.exercise_name_hint,
                      controller: TextEditingController(text: exerciseName),
                      options: widget.trainerExercises,
                      prefixIcon: Icons.sports_gymnastics,
                      isRequired: true,
                      onChanged: (name, id) {
                        exerciseName = name;
                        exerciseId = id;

                        

                        if (id != null) {
                          selectedExercise = widget.trainerExercises.firstWhere(
                            (e) => e['exerciseId'] == id,
                          );
                          setState(() {
                            exerciseName = selectedExercise!['name'];
                            selectedEquipment = selectedExercise!['equipment'];
                            exerciseId = id;

                            // Clear existing sets and create new ones from stored data
                            exerciseSets.forEach((set) => set.dispose());
                            exerciseSets.clear();

                            final storedSets = selectedExercise!['sets'] as List<dynamic>? ?? [];
                            if (storedSets.isNotEmpty) {
                              exerciseSets.addAll(storedSets.map((setData) => ExerciseSet(
                                reps: setData['reps'],
                                weight: setData['weight'],
                                rest: setData['rest'],
                              )));
                            } else {
                              exerciseSets.add(ExerciseSet());
                            }

                            // Set instructions
                            instructions.clear();
                            instructions.addAll(List<String>.from(selectedExercise!['instructions'] ?? []));

                            // Handle media
                            if (selectedExercise!['videoFile'] != null && selectedExercise!['videoFile'].isNotEmpty) {
                              videoFile = File(selectedExercise!['videoFile']);
                            }
                            if (selectedExercise!['imageFiles'] != null && selectedExercise!['imageFiles'].isNotEmpty) {
                              for (var imageFile in selectedExercise!['imageFiles']) {
                              
                                imageFiles.add(File(imageFile));
                              }
                            }
                            originalExercise = null;  // Reset original state
                            
                          });
                        }

                        if (id != null || originalExercise != null) {
                          _checkForChanges();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomSelectTextField(
                      label: l10n.equipment,
                      hintText: l10n.select_enter_equipment,
                      controller: TextEditingController(text: selectedEquipment),
                      options: widget.equipmentTypes,
                      prefixIcon: Icons.fitness_center_outlined,
                      onChanged: (value) {
                        selectedEquipment = value;
                        _checkForChanges();
                      },
                    ),
                    const SizedBox(height: 32),
                    ExerciseSetsView(
                      exerciseSets: exerciseSets,
                      onAddSet: (set) {
                        setState(() {
                          final lastSet = exerciseSets.last;
                          exerciseSets.add(ExerciseSet(
                            reps: lastSet.repsController.text,
                            weight: lastSet.weightController.text,
                            rest: lastSet.restController.text,
                          ));
                          _checkForChanges();
                        });
                      },
                      onRemoveSet: (index) {
                        setState(() {
                          exerciseSets[index].dispose();
                          exerciseSets.removeAt(index);
                          _checkForChanges();
                        });
                      },
                      setModalState: setState,
                      onSetChanged: _checkForChanges,
                    ),
                  ],
                ),
              ),
            ),
          ] else if (selectedTopSelectorIndex == 1) ...[
            // Media section
            _buildMediaSection(videoWidth),
          ] else if (selectedTopSelectorIndex == 2) ...[
            // Instructions section
            _buildInstructionsSection(),
          ],

          // Action buttons
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.cancel,
                      style: GoogleFonts.plusJakartaSans(
                        color: theme.brightness == Brightness.light ? myGrey90 : myGrey40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (exerciseName.isNotEmpty) {
                        final unitPrefs = Provider.of<UnitPreferences>(context, listen: false);
                        
                        // Convert weights to kg before saving
                        final weightUnit = userData?['weightUnit'];
                        final convertedSets = weightUnit == 'lbs' ? exerciseSets.map((set) {
                          return _convertSetWeights(set.toMap(), unitPrefs);
                        }).toList() : exerciseSets.map((set) {
                          return set.toMap();
                        }).toList();

                        final exercise = {
                          'exerciseId': hasChanged ? null : ((widget.isEditing ? widget.existingExercise?.exerciseId : exerciseId)),
                          'name': hasChanged ? (hasNameChanged ? exerciseName : '$exerciseName (new)') : exerciseName,
                          'equipment': selectedEquipment,
                          'sets': convertedSets,  // Use the converted sets
                          'instructions': instructions,
                          'videoFile': videoFile,
                          'imageFiles': imageFiles,
                          'videoUrl': selectedExercise?['videoUrl'],
                          'imageUrls': selectedExercise?['imageUrls'],
                          'hasChanged': hasChanged,
                        };

                        // Call onAdd with the exercise data
                        widget.onAdd(exercise);
                        
                        // Close the dialog
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: myBlue60,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.isEditing ? l10n.save : l10n.add,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildMediaSection(double videoWidth) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.exercise_video,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: theme.brightness == Brightness.light ? myGrey90 : myGrey10
                  ),
                ),
                const SizedBox(height: 4),
                if (videoFile != null) ...[
                  CustomVideoPlayer(
                    videoFile: videoFile!,
                    width: videoWidth,
                    onDelete: () {
                      setState(() {
                        videoFile = null;
                        _checkForChanges();
                      });
                    },
                  ),
                ] else ...[
                  _buildAddVideoButton(videoWidth),
                ],
              ]
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.images,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: theme.brightness == Brightness.light ? myGrey90 : myGrey10
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${imageFiles.length + (selectedExercise?['imageUrls']?.length ?? 0)}/4',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: theme.brightness == Brightness.light ? myGrey60 : myGrey40
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      
                      if (imageFiles.isNotEmpty) ...[
                        for (var image in imageFiles) ...[
                          _buildLocalImageItem(image),
                        ],
                      ],
                      if ((imageFiles.length + (selectedExercise?['imageUrls']?.length ?? 0)) < 4) ...[
                        _buildAddImageButton(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsSection() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.instructions,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: theme.brightness == Brightness.light ? myGrey80 : myGrey20
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: CustomFocusTextField(
                        label: '',
                        hintText: l10n.add_instruction,
                        controller: instructionController,
                        prefixIcon: Icons.format_list_bulleted,
                        maxLines: 4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildAddInstructionButton(),
                  ],
                ),
              ],
            ),
            if (instructions.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInstructionsList(),
            ],
          ],
        ),
      ),
    );
  }

  // Helper widgets for media section
  Widget _buildAddVideoButton(double width) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () async {
        final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
        if (video != null) {
          // Create video player to check duration
          final videoPlayerController = VideoPlayerController.file(File(video.path));
          try {
            await videoPlayerController.initialize();
            final duration = videoPlayerController.value.duration;
            
            if (duration.inSeconds > 15) {
              // Show error message if video is too long
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  CustomSnackBar.show(
                    title: l10n.video,
                    message: l10n.video_too_long_error,
                    type: SnackBarType.error,
                  ),
                );
              }
            } else {
              // Video is within duration limit, set it
              setState(() {
                videoFile = File(video.path);
                _checkForChanges();
              });
            }
          } finally {
            await videoPlayerController.dispose();
          }
        }
      },
      child: Container(
        alignment: Alignment.center,
        width: width,
        height: width * (1920 / 1080),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.brightness == Brightness.light ? myGrey30 : myGrey80, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light ? myBlue10 : myGrey70,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.video_library_outlined, color: theme.brightness == Brightness.light ? myBlue60 : myGrey50, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.add_video} (max 15s)',
              style: GoogleFonts.plusJakartaSans(
                color: theme.brightness == Brightness.light ? myBlue60 : myGrey50,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLocalImageItem(File image) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: myGrey30,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                image,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  imageFiles.remove(image);
                  _checkForChanges();
                });
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: myGrey10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.close,
                  color: myRed50,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () async {
        final List<XFile> images = await picker.pickMultiImage();
        if (images.isNotEmpty) {
          setState(() {
            imageFiles.addAll(images.map((image) => File(image.path)));
            _checkForChanges();
          });
        }
      },
      child: Container(
        alignment: Alignment.center,
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.brightness == Brightness.light ? myGrey30 : myGrey80, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: theme.brightness == Brightness.light ? myBlue60 : myGrey50, size: 24),
            const SizedBox(height: 8),
            Text(
              l10n.add_image,
              style: GoogleFonts.plusJakartaSans(
                color: theme.brightness == Brightness.light ? myBlue60 : myGrey50,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddInstructionButton() {
    return GestureDetector(
      onTap: () {
        if (instructionController.text.isNotEmpty) {
          setState(() {
            instructions.add(instructionController.text);
            instructionController.clear();
            _checkForChanges();
          });
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          color: myBlue30,
          shape: BoxShape.circle,
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: myBlue60,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildInstructionsList() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: instructions.asMap().entries.map((entry) {
          int idx = entry.key;
          String instruction = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light ? myGrey20 : myGrey80,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 0,
                top: 8,
                bottom: 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${idx + 1}. ',
                    style: GoogleFonts.plusJakartaSans(
                      color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      instruction,
                      style: GoogleFonts.plusJakartaSans(
                        color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
} 