import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/models/exercise_set.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/views/trainer_side/create_workout_plan_page.dart';
import 'package:naturafit/views/trainer_side/widgets/exercise_sets_view.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_select_textfield.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:naturafit/widgets/custom_top_selector.dart';
import 'package:naturafit/widgets/custom_video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddExercisePage extends StatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? exerciseToEdit;

  const AddExercisePage({
    Key? key,
    this.isEditing = false,
    this.exerciseToEdit,
  }) : super(key: key);

  @override
  State<AddExercisePage> createState() => _AddExercisePageState();
}

class _AddExercisePageState extends State<AddExercisePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _equipmentController = TextEditingController();
  final TextEditingController _instructionController = TextEditingController();
  List<ExerciseSet> exerciseSets = [
    ExerciseSet(),
    ExerciseSet(),
    ExerciseSet(),
  ];
  List<String> instructions = [];
  File? videoFile;
  List<File> imageFiles = [];
  bool isLoading = false;
  final ImagePicker picker = ImagePicker();

  final List<TopSelectorOption> topSelectorOptions = [
    TopSelectorOption(title: 'Basic'),
    TopSelectorOption(title: 'Media'),
    TopSelectorOption(title: 'Instructions'),
  ];

  int selectedTopSelectorIndex = 0;

  bool _hasVideoChanged = false;
  bool _hasImagesChanged = false;
  String? _originalVideoUrl;
  List<String> _originalImageUrls = [];
  File? _originalVideoFile;
  List<File> _originalImageFiles = [];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.exerciseToEdit != null) {
      _initializeEditData();
    }
  }

  void _initializeEditData() {
    final exercise = widget.exerciseToEdit!;

    // Store original media state
    _originalVideoUrl = exercise['videoUrl'];
    _originalImageUrls = List<String>.from(exercise['imageUrls'] ?? []);

    // Store original files if they exist
    if (exercise['videoFile'] != null && exercise['videoFile'].isNotEmpty) {
      _originalVideoFile = File(exercise['videoFile']);
      videoFile = _originalVideoFile;
    }
    
    if (exercise['imageFiles'] != null && exercise['imageFiles'].isNotEmpty) {
      _originalImageFiles = (exercise['imageFiles'] as List)
          .map((path) => File(path))
          .toList();
      imageFiles = List.from(_originalImageFiles);
    }

    // Initialize text controllers
    _nameController.text = exercise['name'] ?? '';
    _equipmentController.text = exercise['equipment'] ?? '';

    // Initialize sets
    if (exercise['sets'] != null) {
      exerciseSets = (exercise['sets'] as List).map((setData) {
        final set = ExerciseSet();
        set.repsController.text =
            setData['reps']?.toString().replaceAll('"', '') ?? '';
        set.weightController.text =
            setData['weight']?.toString().replaceAll('"', '') ?? '';
        set.restController.text =
            setData['rest']?.toString().replaceAll('"', '') ?? '';
        return set;
      }).toList();
    }

    // Initialize instructions
    if (exercise['instructions'] != null) {
      instructions = List<String>.from(exercise['instructions']);
    }
  }

  void _checkForChanges() {
    if (!widget.isEditing) return;

    setState(() {
      // Check if video has changed
      if (_originalVideoFile == null) {
        // No original video
        _hasVideoChanged = videoFile != null;
      } else if (videoFile == null) {
        // Video was removed
        _hasVideoChanged = true;
      } else {
        // Compare video files
        _hasVideoChanged = videoFile!.path != _originalVideoFile!.path;
      }

      // Check if images have changed
      if (_originalImageFiles.isEmpty) {
        // No original images
        _hasImagesChanged = imageFiles.isNotEmpty;
      } else if (imageFiles.isEmpty) {
        // All images were removed
        _hasImagesChanged = true;
      } else {
        // Compare image files
        final originalPaths = _originalImageFiles.map((f) => f.path).toSet();
        final currentPaths = imageFiles.map((f) => f.path).toSet();
        _hasImagesChanged = !setEquals(originalPaths, currentPaths);
      }

      debugPrint('hasVideoChanged: $_hasVideoChanged');
      debugPrint('hasImagesChanged: $_hasImagesChanged');
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _equipmentController.dispose();
    _instructionController.dispose();
    for (var set in exerciseSets) {
      set.dispose();
    }
    super.dispose();
  }

  Future<void> _addExercise() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
          title: l10n.add_exercise,
          message: l10n.please_enter_exercise_name,
          type: SnackBarType.error,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final userData = context.read<UserProvider>().userData;
      final trainerId = userData?['userId'];
      if (trainerId == null) {
        throw Exception(l10n.trainer_id_not_found);
      }

      // Upload media files if any
      List<String> imageUrls = [];
      String? videoUrl;

      if (videoFile != null) {
        final videoRef = FirebaseStorage.instance
            .ref()
            .child('trainer_exercises')
            .child(trainerId)
            .child('videos')
            .child('${DateTime.now().millisecondsSinceEpoch}.mp4');
        await videoRef.putFile(videoFile!);
        videoUrl = await videoRef.getDownloadURL();
      }

      for (var imageFile in imageFiles) {
        final imageRef = FirebaseStorage.instance
            .ref()
            .child('trainer_exercises')
            .child(trainerId)
            .child('images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await imageRef.putFile(imageFile);
        final imageUrl = await imageRef.getDownloadURL();
        imageUrls.add(imageUrl);
      }

      // Create exercise document
      final exerciseData = {
        'name': _nameController.text,
        'equipment': _equipmentController.text,
        'sets': exerciseSets.map((set) => set.toMap()).toList(),
        'instructions': instructions,
        'videoUrl': videoUrl,
        'imageUrls': imageUrls,
        'videoFile': videoFile,
        'imageFiles': imageFiles,
        'isBookmarked': false,
        'usageCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('trainer_exercises')
          .doc(trainerId)
          .collection('all_exercises')
          .add(exerciseData);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      debugPrint('Error adding exercise: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.add_exercise,
            message: l10n.failed_add_exercise,
            type: SnackBarType.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _updateExercise() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
          title: l10n.add_exercise,
          message: l10n.please_enter_exercise_name,
          type: SnackBarType.error,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final userData = context.read<UserProvider>().userData;
      final trainerId = userData?['userId'];
      if (trainerId == null) {
        throw Exception(l10n.trainer_id_not_found);
      }

      // Handle media files
      List<String> imageUrls = [];
      String? videoUrl;

      // Check if video has changed
      if (_hasVideoChanged) {
        if (videoFile != null) {
          // Upload new video
          final videoRef = FirebaseStorage.instance
              .ref()
              .child('trainer_exercises')
              .child(trainerId)
              .child('videos')
              .child('${DateTime.now().millisecondsSinceEpoch}.mp4');
          await videoRef.putFile(videoFile!);
          videoUrl = await videoRef.getDownloadURL();
        } else {
          // Video was removed
          videoUrl = null;
        }
      } else {
        // Keep existing video URL
        videoUrl = widget.exerciseToEdit?['videoUrl'];
      }

      // Check if images have changed
      if (_hasImagesChanged) {
        if (imageFiles.isNotEmpty) {
          // Upload new images
          for (var imageFile in imageFiles) {
            final imageRef = FirebaseStorage.instance
                .ref()
                .child('trainer_exercises')
                .child(trainerId)
                .child('images')
                .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
            await imageRef.putFile(imageFile);
            final imageUrl = await imageRef.getDownloadURL();
            imageUrls.add(imageUrl);
          }
        }
        // If imageFiles is empty, imageUrls will remain empty (effectively removing all images)
      } else {
        // Keep existing image URLs
        imageUrls = List<String>.from(widget.exerciseToEdit?['imageUrls'] ?? []);
      }

      // Create update data
      final Map<String, dynamic> exerciseData = {
        'name': _nameController.text,
        'equipment': _equipmentController.text,
        'sets': exerciseSets.map((set) => set.toMap()).toList(),
        'instructions': instructions,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Handle video changes
      if (_hasVideoChanged) {
        exerciseData['videoUrl'] = videoUrl;
      }

      // Handle image changes
      if (_hasImagesChanged) {
        exerciseData['imageUrls'] = imageUrls;
      }

      // Update the exercise
      await FirebaseFirestore.instance
          .collection('trainer_exercises')
          .doc(trainerId)
          .collection('all_exercises')
          .doc(widget.exerciseToEdit!['id'])
          .update(exerciseData);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error updating exercise: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.add_exercise,
            message: l10n.failed_update_exercise,
            type: SnackBarType.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    double videoWidth = screenWidth < 800 ? screenWidth * 0.5 : 400;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
              width: 1
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.chevron_left,
              color: theme.brightness == Brightness.light ? Colors.black : Colors.white
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          widget.isEditing ? l10n.edit_exercise_title : l10n.add_exercise_title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: CustomTopSelector(
                      options: [
                        TopSelectorOption(title: l10n.basic),
                        TopSelectorOption(title: l10n.media),
                        TopSelectorOption(title: l10n.instructions),
                      ],
                      selectedIndex: selectedTopSelectorIndex,
                      onOptionSelected: (value) {
                        setState(() {
                          selectedTopSelectorIndex = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (selectedTopSelectorIndex == 0) ...[
                            CustomFocusTextField(
                              label: l10n.exercise_name,
                              hintText: l10n.exercise_name_hint,
                              controller: _nameController,
                              prefixIcon: Icons.sports_gymnastics,
                              isRequired: true,
                            ),
                            const SizedBox(height: 16),
                            CustomFocusTextField(
                              label: l10n.equipment,
                              hintText: l10n.select_enter_equipment,
                              controller: _equipmentController,
                              prefixIcon: Icons.fitness_center,
                            ),
                            const SizedBox(height: 32),
                            ExerciseSetsView(
                              exerciseSets: exerciseSets,
                              onAddSet: (set) {
                                setState(() {
                                  if (exerciseSets.isEmpty) {
                                    exerciseSets.add(
                                        ExerciseSet()); // Add first set with defaults
                                  } else {
                                    // Get values from the last set
                                    final lastSet = exerciseSets.last;
                                    exerciseSets.add(ExerciseSet(
                                      reps: lastSet.repsController.text,
                                      weight: lastSet.weightController.text,
                                      rest: lastSet.restController.text,
                                    ));
                                  }
                                });
                              },
                              onRemoveSet: (index) {
                                setState(() {
                                  exerciseSets[index].dispose();
                                  exerciseSets.removeAt(index);
                                });
                              },
                              setModalState: setState,
                            ),
                          ] else if (selectedTopSelectorIndex == 1) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.exercise_video_title,
                                        style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: theme.brightness == Brightness.light ? myGrey90 : myGrey10),
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
                                        GestureDetector(
                                          onTap: () async {
                                            final XFile? video =
                                                await picker.pickVideo(
                                                    source: ImageSource.gallery);
                                            if (video != null) {
                                              setState(() {
                                                videoFile = File(video.path);
                                                _checkForChanges();
                                              });
                                            }
                                          },
                                          child: Container(
                                            alignment: Alignment.center,
                                            width: videoWidth,
                                            height: videoWidth * (1920 / 1080),
                                            decoration: BoxDecoration(
                                              color: theme.brightness == Brightness.light ? Colors.white : myGrey100,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: myGrey30, width: 1),
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: theme.brightness == Brightness.light ? myBlue10 : myGrey80,
                                                    borderRadius:
                                                        BorderRadius.circular(20),
                                                  ),
                                                  padding: const EdgeInsets.all(8),
                                                  child: Icon(
                                                      Icons.video_library_outlined,
                                                      color: theme.brightness == Brightness.light ? myBlue60 : myGrey60,
                                                      size: 24),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  l10n.add_video,
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                    color: theme.brightness == Brightness.light ? myBlue60 : myGrey60,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      ],
                                    ]),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          l10n.exercise_images_title,
                                          style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: theme.brightness == Brightness.light ? myGrey90 : myGrey10),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${imageFiles.length}/4',
                                          style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: theme.brightness == Brightness.light ? myGrey60 : myGrey40),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          if (imageFiles.isNotEmpty) ...[
                                            for (var image in imageFiles) ...[
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 8),
                                                child: Stack(
                                                  children: [
                                                    Container(
                                                      width: 100,
                                                      height: 100,
                                                      decoration: BoxDecoration(
                                                        color: myGrey30,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                12),
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                12),
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
                                                            imageFiles
                                                                .remove(image);
                                                            _checkForChanges();
                                                          });
                                                        },
                                                        child: Container(
                                                          width: 20,
                                                          height: 20,
                                                          //padding: const EdgeInsets.all(4),
                                                          decoration: BoxDecoration(
                                                            color: myGrey10,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(10),
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
                                              ),
                                            ],
                                          ],
                                          if (imageFiles.length < 4) ...[
                                            GestureDetector(
                                              onTap: () async {
                                                final List<XFile> images =
                                                    await picker.pickMultiImage();
                                                if (images.isNotEmpty) {
                                                  setState(() {
                                                    imageFiles.addAll(images.map(
                                                        (image) =>
                                                            File(image.path)));
                                                    _checkForChanges();
                                                  });
                                                }
                                              },
                                              child: Container(
                                                alignment: Alignment.center,
                                                width: 100,
                                                height: 100,
                                                decoration: BoxDecoration(
                                                  color: theme.brightness == Brightness.light ? Colors.white : myGrey100,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                      color: myGrey30, width: 1),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.add_a_photo,
                                                        color: theme.brightness == Brightness.light ? myBlue60 : myGrey60, size: 24),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      l10n.add_image,
                                                      style: GoogleFonts
                                                          .plusJakartaSans(
                                                        color: theme.brightness == Brightness.light ? myBlue60 : myGrey60,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ] else ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.instructions,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomFocusTextField(
                                        label: '',
                                        hintText: l10n.add_instruction,
                                        controller: _instructionController,
                                        prefixIcon: Icons.format_list_bulleted,
                                        maxLines: 4,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        if (_instructionController
                                            .text.isNotEmpty) {
                                          setState(() {
                                            instructions
                                                .add(_instructionController.text);
                                            _instructionController.clear();
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
                                          child: const Icon(Icons.add,
                                              color: Colors.white, size: 24),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (instructions.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: instructions.asMap().entries.map((entry) {
                                        int idx = entry.key;
                                        String instruction = entry.value;
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          decoration: BoxDecoration(
                                            color: theme.brightness == Brightness.light 
                                                ? myGrey20 
                                                : myGrey80,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 16, right: 0, top: 8, bottom: 8),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${idx + 1}. ',
                                                  style: theme.textTheme.bodyLarge?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    instruction,
                                                    style: theme.textTheme.bodyLarge,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      MediaQuery.of(context).padding.bottom + 16,
                    ),
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
                              foregroundColor: theme.textTheme.bodyLarge?.color,
                            ),
                            child: Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : widget.isEditing ? _updateExercise : _addExercise,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: myBlue60,
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              widget.isEditing ? l10n.save_changes : l10n.add_exercise,
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
              if (isLoading)
                Container(
                  color: theme.brightness == Brightness.light 
                      ? Colors.black.withOpacity(0.5)
                      : Colors.white.withOpacity(0.1),
                  child: const Center(
                    child: CircularProgressIndicator(color: myBlue60),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
