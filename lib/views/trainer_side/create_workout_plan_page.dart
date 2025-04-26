import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/models/exercise_set.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/views/trainer_side/widgets/workout_schedule_step.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_loading_bar_view.dart';
import 'package:naturafit/widgets/custom_loading_view.dart';
import 'package:naturafit/widgets/custom_select_exercise_textfield.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:naturafit/widgets/custom_top_selector.dart';
import 'package:naturafit/widgets/custom_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/widgets/client_selection_sheet.dart';
import 'package:naturafit/widgets/custom_select_textfield.dart';
import 'package:naturafit/widgets/custom_step_indicator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:naturafit/models/workout_models.dart';
import 'package:naturafit/blocs/workout_plan_bloc.dart';
import 'package:naturafit/views/trainer_side/widgets/exercise_sets_view.dart';
import 'package:naturafit/widgets/custom_select_multiple_textfield.dart';
import 'package:naturafit/views/trainer_side/widgets/add_exercise_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Add this class after imports
/*
class ExerciseSet {
  final TextEditingController repsController;
  final TextEditingController weightController;
  final TextEditingController restController;

  ExerciseSet({
    String? reps = '12',
    String? weight = '20',
    String? rest = '60s',
  })  : repsController = TextEditingController(text: reps),
        weightController = TextEditingController(text: weight),
        restController = TextEditingController(text: rest);

  void dispose() {
    repsController.dispose();
    weightController.dispose();
    restController.dispose();
  }

  Map<String, dynamic> toMap() {
    return {
      'reps': repsController.text,
      'weight': weightController.text,
      'rest': restController.text,
    };
  }
}
*/

class CreateWorkoutPlanPage extends StatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? existingPlan;
  final bool isUsingTemplate;

  const CreateWorkoutPlanPage({
    Key? key,
    this.isEditing = false,
    this.existingPlan,
    this.isUsingTemplate = false,
  }) : super(key: key);

  @override
  State<CreateWorkoutPlanPage> createState() => _CreateWorkoutPlanPageState();
}

class _CreateWorkoutPlanPageState extends State<CreateWorkoutPlanPage> {
  final _createWorkoutPlanContentKey =
      GlobalKey<_CreateWorkoutPlanContentState>();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => WorkoutPlanBloc(context)),
      ],
      child: _CreateWorkoutPlanContent(
        key: _createWorkoutPlanContentKey,
        isEditing: widget.isEditing,
        existingPlan: widget.existingPlan,
        isUsingTemplate: widget.isUsingTemplate,
      ),
    );
  }
}

class _CreateWorkoutPlanContent extends StatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? existingPlan;
  final bool isUsingTemplate;
  const _CreateWorkoutPlanContent({
    Key? key,
    this.isEditing = false,
    this.existingPlan,
    this.isUsingTemplate = false,
  }) : super(key: key);

  @override
  State<_CreateWorkoutPlanContent> createState() =>
      _CreateWorkoutPlanContentState();
}

class _CreateWorkoutPlanContentState extends State<_CreateWorkoutPlanContent>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late List<WorkoutDay> workoutDays;
  int _currentStep = 0;
  late AnimationController _animationController;

  String? selectedClientId;
  String? selectedClientUsername;
  String? selectedClientFullName;
  String? selectedClientConnectionType;
  String? selectedClientProfileImageUrl;
  String selectedClientType = 'existing_client';
  String manualClientName = '';

  // Plan Overview Controllers
  final _planNameController = TextEditingController();
  final _goalController = TextEditingController();
  final _durationController = TextEditingController();
  final _workoutTypeController = TextEditingController();
  final _equipmentController = TextEditingController();

  // Schedule Controllers
  //List<WorkoutDay> workoutDays = [];

  // Progression Controllers
  final _progressionNotesController = TextEditingController();
  final _deloadWeekController = TextEditingController();

  // Additional Details Controllers
  final _warmUpController = TextEditingController();
  final _coolDownController = TextEditingController();
  final _additionalNotesController = TextEditingController();

  int _selectedDayIndex = 0;

  final _manualClientController = TextEditingController();

  final _templateNameController = TextEditingController();

  // Add these lists for predefined options
  

  

  

  

  

  

  // Add this variable to store trainer's exercises
  List<Map<String, dynamic>> trainerExercises = [];
  bool isLoadingExercises = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    workoutDays = [WorkoutDay(dayNumber: 1, context: context)];
    
    if ((widget.isEditing || widget.isUsingTemplate) &&
        widget.existingPlan != null) {
      _initializeWithExistingPlan(widget.existingPlan!);
    }
    
    _fetchTrainerExercises();
  }

  Future<void> _fetchTrainerExercises() async {
    final userProvider = context.read<UserProvider>();
    final trainerId = userProvider.userData?['userId'];

    if (trainerId == null) return;

    try {
      setState(() {
        isLoadingExercises = true;
      });

      final exercisesSnapshot = await FirebaseFirestore.instance
          .collection('trainer_exercises')
          .doc(trainerId)
          .collection('all_exercises')
          .get();

      setState(() {
        trainerExercises = exercisesSnapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'exerciseId': doc.id,
                })
            .toList();
        isLoadingExercises = false;
        debugPrint('Trainer exercises fetched: ${trainerExercises.length}');
      });
    } catch (e) {
      debugPrint('Error fetching trainer exercises: $e');
      setState(() {
        isLoadingExercises = false;
      });
    }
  }

  void _initializeWithExistingPlan(Map<String, dynamic> plan) {
    // Set client info
    selectedClientId = plan['clientId'];
    selectedClientUsername = plan['clientUsername'];
    selectedClientFullName = plan['clientFullName'];
    selectedClientConnectionType = plan['connectionType'];
    selectedClientProfileImageUrl = plan['clientProfileImageUrl'];

    // Set client type based on connection type
    if (widget.isUsingTemplate) {
      selectedClientType = 'existing_client';
    } else if (plan['connectionType'] == fbTemplateConnectionType) {
      selectedClientType = 'template';
      _templateNameController.text = plan['clientUsername'] ?? '';
    } else if (plan['connectionType'] == fbTypedConnectionType) {
      selectedClientType = 'manual_client';
      _manualClientController.text = plan['clientUsername'] ?? '';
    } else {
      selectedClientType = 'existing_client';
    }

    // Set basic plan details
    _planNameController.text = plan['planName'] ?? '';
    _goalController.text = plan['goal'] ?? '';
    _durationController.text = plan['duration'] ?? '';
    _workoutTypeController.text = plan['workoutType'] ?? '';
    _equipmentController.text = plan['equipment'] ?? '';

    // Set additional details
    _warmUpController.text = plan['warmUp'] ?? '';
    _coolDownController.text = plan['coolDown'] ?? '';
    _progressionNotesController.text = plan['progressionNotes'] ?? '';
    _deloadWeekController.text = plan['deloadWeek'] ?? '';
    _additionalNotesController.text = plan['additionalNotes'] ?? '';

    // Set workout days
    workoutDays.clear();
    final List<dynamic> planWorkoutDays = plan['workoutDays'] ?? [];
    for (var dayData in planWorkoutDays) {
      // Create phases first
      List<WorkoutPhase> phases = [];
      final List<dynamic> phasesData = dayData['phases'] ?? [];
      
      for (var phaseData in phasesData) {
        final phase = WorkoutPhase(
          id: phaseData['id'],
          name: phaseData['name'],
        );

        final List<dynamic> exercises = phaseData['exercises'] ?? [];
        for (var exerciseData in exercises) {
          phase.exercises.add(Exercise(
            name: exerciseData['name'],
            equipment: exerciseData['equipment'],
            sets: List<Map<String, dynamic>>.from(exerciseData['sets'] ?? []),
            instructions: List<String>.from(exerciseData['instructions'] ?? []),
            videoFile: exerciseData['videoFile']?.isNotEmpty == true
                ? File(exerciseData['videoFile'])
                : null,
            imageFiles: (exerciseData['imageFiles'] as List<dynamic>?)
                    ?.where((path) => path.isNotEmpty)
                    ?.map((path) => File(path))
                    ?.toList() ??
                [],
          ));
        }
        phases.add(phase);
      }

      // Create WorkoutDay with the existing phases
      final workoutDay = WorkoutDay(
        dayNumber: dayData['dayNumber'],
        initialPhases: phases, // Pass the existing phases
        context: context,
      );
      workoutDay.focusAreaController.text = dayData['focusArea'] ?? '';
      workoutDays.add(workoutDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WorkoutPlanBloc, WorkoutPlanState>(
        listener: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          


          if (state is WorkoutPlanSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              CustomSnackBar.show(
                title: l10n.workout_plan,
                message: l10n.workout_plan_created_successfully,
                type: SnackBarType.success,
              ),
            );
            Navigator.pop(context);
          } else if (state is WorkoutPlanError) {
            ScaffoldMessenger.of(context).showSnackBar(
              CustomSnackBar.show(
                title: l10n.workout_plan,
                message: l10n.unable_to_update_plan_status(state.message),
                type: SnackBarType.error,
              ),
            );
          }
        },
          builder: (context, state) {
            final theme = Theme.of(context);
          return Stack(
            children: [
              
              Stack(
            children: [
              Scaffold(
                backgroundColor: theme.scaffoldBackgroundColor,
                appBar: _buildAppBar(),
                body: Column(
                children: [
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: [
                              _buildPlanOverviewStep(),
                              _buildScheduleStep(),
                              _buildDetailsStep(),
                            ][_currentStep],
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildNavigationButtons(),
                ],
              ),
              ),

              if (state is WorkoutPlanLoading)
              CustomLoadingBarView(
                progress: state.progress,
                status: state.status,
              ),
          
            ]
            ),


            ],
          );
        },
      );
  }

  void _submitForm(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    // Add validation for exercises
    bool hasAtLeastOneExercise = false;
    List<int> daysWithoutExercises = [];
    List<int> daysWithoutPhases = [];

    // Check each workout day
    for (int i = 0; i < workoutDays.length; i++) {
      WorkoutDay day = workoutDays[i];

      // Check if day has phases
      if (day.phases.isEmpty) {
        daysWithoutPhases.add(i + 1);
        continue;
      }

      // Check if any phase in this day has exercises
      bool dayHasExercise = false;
      for (var phase in day.phases) {
        if (phase.exercises.isNotEmpty) {
          dayHasExercise = true;
          hasAtLeastOneExercise = true;
          break;
        }
      }

      if (!dayHasExercise) {
        daysWithoutExercises.add(i + 1);
      }
    }

    // Show appropriate error message if validation fails
    if (daysWithoutPhases.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
          title: l10n.workout_plan,
          message: l10n.please_add_at_least_one_phase_to_day(daysWithoutPhases.join(", Day ")),
          type: SnackBarType.error,
        ),
      );
      return;
    }

    if (daysWithoutExercises.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
          title: l10n.workout_plan,
          message: l10n.please_add_at_least_one_exercise_to_day(daysWithoutExercises.join(", Day ")),
          type: SnackBarType.error,
        ),
      );
      return;
    }

    if (!hasAtLeastOneExercise) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
          title: l10n.workout_plan,
          message: l10n.please_add_at_least_one_exercise_to_your_workout_plan,
          type: SnackBarType.error,
        ),
      );
      return;
    }

    // Continue with the existing validation and submission logic
    final userData = context.read<UserProvider>().userData;
    if (userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
          title: l10n.workout_plan,
          message: l10n.user_data_not_available,
          type: SnackBarType.error,
        ),
      );
      return;
    }

    final isClientSameAsTrainer = selectedClientId == userData['trainerClientId'];
    var shouldMarkWorkoutAsCurrent = false;


    if (isClientSameAsTrainer) {
      final currentWorkoutSnapshot = await FirebaseFirestore.instance
                    .collection('workouts')
                    .doc('clients')
                    .collection(selectedClientId!)
                    .where('status', isEqualTo: 'current')
                    .get();

      if (currentWorkoutSnapshot.docs.isEmpty) {
        debugPrint('Marking workout as current');
        shouldMarkWorkoutAsCurrent = true;
      }
    }

    

    

    DateTime myNow = DateTime.now();
    Timestamp myTimestamp = Timestamp.fromDate(myNow);

    if (selectedClientType == 'manual_client') {
      selectedClientId =
          'TYPED_${DateTime.now().millisecondsSinceEpoch}_${_manualClientController.text.replaceAll(' ', '_')}';
      selectedClientUsername = _manualClientController.text;
      selectedClientFullName = _manualClientController.text;
      selectedClientProfileImageUrl = '';
      selectedClientConnectionType = fbTypedConnectionType;
      // Create document for manual client
      FirebaseFirestore.instance
          .collection('clients')
          .doc('typed')
          .collection(userData['userId'])
          .doc(selectedClientId)
          .set({
        'clientId': selectedClientId,
        'clientUsername': selectedClientUsername,
        'clientFullName': selectedClientFullName,
        'trainerId': userData['userId'],
        'trainerName': userData[fbRandomName],
        'trainerFullName': userData[fbFullName] ?? userData[fbRandomName],
        'trainerProfileImageUrl': userData['profileImageUrl'],
        'connectionType': fbTypedConnectionType,
        'createdAt': myTimestamp,
      });
    } else if (selectedClientType == 'template') {
      // Generate template ID
      selectedClientId =
          'TEMPLATE_${DateTime.now().millisecondsSinceEpoch}_${_templateNameController.text.replaceAll(' ', '_')}';
      selectedClientUsername = _templateNameController.text;
      selectedClientFullName = _templateNameController.text;
      selectedClientProfileImageUrl = '';
      selectedClientConnectionType = fbTemplateConnectionType;
    }

    // Check if we have either a selected client or a manual client name
    if ((selectedClientType == 'existing_client' && selectedClientId == null) ||
        (selectedClientType == 'manual_client' &&
            _manualClientController.text.isEmpty) ||
        (selectedClientType == 'template' &&
            _templateNameController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
          title: l10n.workout_plan,
          message: selectedClientType == 'existing_client'
              ? l10n.please_select_a_client
              : selectedClientType == 'manual_client'
                  ? l10n.please_enter_client_name
                  : l10n.please_enter_template_name,
          type: SnackBarType.error,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final workoutPlanData = {
        'trainerId': userData['userId'],
        'trainerName': userData[fbRandomName],
        'trainerFullName': userData[fbFullName] ?? userData[fbRandomName],
        'trainerProfileImageUrl': userData['profileImageUrl'],
        'clientId': selectedClientId,
        'clientUsername': selectedClientUsername,
        'clientFullName': selectedClientFullName,
        'clientProfileImageUrl': selectedClientProfileImageUrl ?? '',
        'connectionType': selectedClientConnectionType,
        'planName': _planNameController.text,
        'goal': _goalController.text,
        'duration': _durationController.text,
        'workoutType': _workoutTypeController.text,
        'equipment': _equipmentController.text,
        'workoutDays': workoutDays
            .map((day) => {
                  'dayNumber': day.dayNumber,
                  'focusArea': day.focusAreaController.text,
                  'phases': day.phases
                      .map((phase) => {
                            'id': phase.id,
                            'name': phase.name,
                            'exercises': phase.exercises
                                .map((exercise) => {
                                      'exerciseId': exercise.exerciseId,
                                      'name': exercise.name,
                                      'equipment': exercise.equipment ?? '',
                                      'sets': exercise.sets,
                                      'instructions': exercise.instructions,
                                      'videoFile':
                                          exercise.videoFile?.path ?? '',
                                      'imageFiles': exercise.imageFiles
                                          .map((f) => f.path)
                                          .toList(),
                                      'isBookmarked': false,
                                    })
                                .toList(),
                          })
                      .toList(),
                })
            .toList(),
        'warmUp': _warmUpController.text,
        'coolDown': _coolDownController.text,
        'progressionNotes': _progressionNotesController.text,
        'deloadWeek': _deloadWeekController.text,
        'additionalNotes': _additionalNotesController.text,
        'status': selectedClientType == 'template'
            ? fbCreatedStatusForTemplate
            : (selectedClientType == 'existing_client' &&
                    selectedClientConnectionType == fbAppConnectionType)
                ? (selectedClientId == userData['trainerClientId']
                    ? (shouldMarkWorkoutAsCurrent ? 'current' : fbClientConfirmedStatus)
                    : fbCreatedStatusForAppUser)
                : fbCreatedStatusForNotAppUser,
        'createdAt': myTimestamp,
        'updatedAt': myTimestamp,
      };

      if (widget.isEditing) {
        // For editing, maintain the original creation timestamp
        workoutPlanData['createdAt'] =
            widget.existingPlan?['createdAt'] ?? myTimestamp;

        // Check if client is an app user
        if (selectedClientConnectionType == fbAppConnectionType) {
          // Compare changes and create notification message
          List<String> changes = [];

          if (_planNameController.text != widget.existingPlan?['planName']) {
            changes.add('Plan name updated to "${_planNameController.text}"');
          }
          if (_goalController.text != widget.existingPlan?['goal']) {
            changes.add('Goal updated to "${_goalController.text}"');
          }
          if (_durationController.text != widget.existingPlan?['duration']) {
            changes.add('Duration changed to "${_durationController.text}"');
          }
          if (_workoutTypeController.text !=
              widget.existingPlan?['workoutType']) {
            changes.add(
                'Workout type changed to "${_workoutTypeController.text}"');
          }

          // Check for schedule changes
          final oldDays =
              widget.existingPlan?['workoutDays'] as List<dynamic>? ?? [];
          if (workoutDays.length != oldDays.length) {
            changes.add('Workout schedule has been modified');
          } else {
            bool scheduleChanged = false;
            for (int i = 0; i < workoutDays.length; i++) {
              if (workoutDays[i].phases.length !=
                  (oldDays[i]['phases'] as List).length) {
                scheduleChanged = true;
                break;
              }
            }
            if (scheduleChanged) {
              changes.add('Workout exercises have been updated');
            }
          }

          // If there are changes, create notification
          if (changes.isNotEmpty) {
            final batch = FirebaseFirestore.instance.batch();
            final notificationRef = FirebaseFirestore.instance
                .collection('notifications')
                .doc(selectedClientId)
                .collection('allNotifications')
                .doc();

            batch.set(notificationRef, {
              'userId': selectedClientId,
              'type': 'workout_plan_updated',
              'title': 'Workout Plan Updated',
              'message':
                  'Your trainer has updated "${_planNameController.text}"',
              'senderRole': 'trainer',
              'senderId': userData['userId'],
              'senderFullName': userData[fbFullName] ?? userData[fbRandomName],
              'senderUsername': userData[fbRandomName],
              'senderProfileImageUrl': userData['profileImageUrl'] ?? '',
              'relatedDocId': widget.existingPlan?['planId'],
              'status': 'unread',
              'requiresAction': false,
              'createdAt': myTimestamp,
              'read': false,
              'data': {
                'senderId': userData['userId'],
                'planName': _planNameController.text,
                'planId': widget.existingPlan?['planId'],
                'changes': changes,
              },
            });

            // Update workout plan and send notification in one batch
            batch.update(
                FirebaseFirestore.instance
                    .collection('workouts')
                    .doc('clients')
                    .collection(selectedClientId!)
                    .doc(widget.existingPlan?['planId']),
                workoutPlanData);

            batch.commit();
          } else {
            // If no changes, just update the workout plan
            context.read<WorkoutPlanBloc>().add(UpdateWorkoutPlan(
                  planId: widget.existingPlan?['planId'],
                  data: workoutPlanData,
                ));
          }
        } else {
          // For non-app users, just update the workout plan
          context.read<WorkoutPlanBloc>().add(UpdateWorkoutPlan(
                planId: widget.existingPlan?['planId'],
                data: workoutPlanData,
              ));
        }
      } else {
        workoutPlanData['createdAt'] = myTimestamp;
        context.read<WorkoutPlanBloc>().add(CreateWorkoutPlan(
              data: workoutPlanData,
            ));
      }
    }
  }

  Widget _buildPlanOverviewStep() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;


    final List<String> planNameSuggestions = [
    l10n.strength_training_program,
    l10n.weight_loss_program,
    l10n.muscle_building_program,
    l10n.hiit_program,
    l10n.endurance_training_program,
    l10n.functional_fitness_program,
    l10n.body_transformation_program,
    l10n.athletic_performance_program,
    l10n.rehabilitation_program,
    l10n.mobility_flexibility_program
  ];


  final List<String> goalSuggestions = [
    l10n.build_muscle_mass,
    l10n.lose_body_fat,
    l10n.increase_strength,
    l10n.improve_endurance,
    l10n.enhance_flexibility,
    l10n.athletic_performance,
    l10n.general_fitness,
    l10n.body_recomposition,
    l10n.injury_recovery,
    l10n.sports_specific_training
  ];



  final List<String> durationSuggestions = [
    l10n.four_weeks,
    l10n.six_weeks,
    l10n.eight_weeks,
    l10n.twelve_weeks,
    l10n.sixteen_weeks,
    l10n.three_months,
    l10n.six_months,
    l10n.two_sessions_per_week,
    l10n.three_sessions_per_week,
    l10n.four_sessions_per_week,
    l10n.five_sessions_per_week
  ];



  final List<String> workoutTypeSuggestions = [
    l10n.strength_training_program,
    l10n.hypertrophy_training,
    l10n.circuit_training,
    l10n.hiit,
    l10n.endurance_training,
    l10n.crossfit_style,
    l10n.bodyweight_training,
    l10n.powerlifting,
    l10n.olympic_weightlifting,
    l10n.functional_training,
    l10n.mobility_work,
    l10n.mixed_training_styles
  ];



  final List<String> equipmentTypes = [
    l10n.bodyweight,
    l10n.barbell,
    l10n.dumbbell,
    l10n.kettlebell,
    l10n.machine,
    l10n.cable,
    l10n.resistance_band,
    l10n.medicine_ball,
    l10n.trx_suspension,
    l10n.other,
  ];




    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isEditing == false) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildClientTypeSelection(),
                    _buildClientField(),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            CustomSelectTextField(
              label: l10n.plan_name,
              hintText: l10n.e_g_6_week_strength_plan,
              controller: _planNameController,
              options: planNameSuggestions,
              isRequired: false,
              prefixIcon: Icons.description_outlined,
              onChanged: (value) {
                // Remove setState and don't set controller text
              },
            ),
            const SizedBox(height: 16),
            CustomSelectTextField(
              label: l10n.goal,
              hintText: l10n.e_g_weight_loss_muscle_gain_maintenance,
              controller: _goalController,
              options: goalSuggestions,
              prefixIcon: Icons.track_changes_outlined,
              onChanged: (value) {
                // Remove setState and don't set controller text
              },
            ),
            const SizedBox(height: 16),
            CustomSelectTextField(
              label: l10n.duration,
              hintText: l10n.e_g_4_weeks,
              controller: _durationController,
              options: durationSuggestions,
              prefixIcon: Icons.calendar_today_outlined,
              onChanged: (value) {
                // Remove setState and don't set controller text
              },
            ),
            const SizedBox(height: 16),
            CustomSelectTextField(
              label: l10n.workout_type,
              hintText: l10n.e_g_strength_hiit_cardio,
              controller: _workoutTypeController,
              options: workoutTypeSuggestions,
              prefixIcon: Icons.category_outlined,
              onChanged: (value) {
                // Remove setState and don't set controller text
              },
            ),
            const SizedBox(height: 16),
            CustomSelectMultipleTextField(
              label: l10n.equipment_needed,
              hintText: l10n.select_or_enter_equipment_needed,
              controller: _equipmentController,
              options: equipmentTypes,
              prefixIcon: Icons.fitness_center_outlined,
              onChanged: (selectedEquipment) {
                // Remove setState and don't set controller text
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleStep() {
    final l10n = AppLocalizations.of(context)!;
    final List<String> focusAreaSuggestions = [
    l10n.upper_body,
    l10n.lower_body,
    l10n.full_body,
    l10n.push_day,
    l10n.pull_day,
    l10n.legs_day,
    l10n.core_abs,
    l10n.back_shoulders,
    l10n.chest_triceps,
    l10n.back_biceps,
    l10n.shoulders_arms,
    l10n.cardio_hiit
  ];
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: WorkoutScheduleStep(
          workoutDays: workoutDays,
          selectedDayIndex: _selectedDayIndex,
          onDaySelected: (index) {
            setState(() {
              _selectedDayIndex = index;
            });
          },
          onAddExercise: (dayIndex, phaseId) =>
              _showAddExerciseDialog(dayIndex, phaseId),
          onRemoveDay: (index) {
            setState(() {
              workoutDays[index].dispose();
              workoutDays.removeAt(index);
              if (_selectedDayIndex >= workoutDays.length) {
                _selectedDayIndex = workoutDays.length - 1;
              }
            });
          },
          onAddDay: () {
            setState(() {
              workoutDays.add(WorkoutDay(
                dayNumber: workoutDays.length + 1,
                context: context,
              ));
              _selectedDayIndex = workoutDays.length - 1;
            });
          },
          focusAreaSuggestions: focusAreaSuggestions,
          onEditExercise: (dayIndex, exerciseIndex, phaseId) =>
              _showEditExerciseDialog(dayIndex, exerciseIndex, phaseId),
          onDeleteExercise: (dayIndex, exerciseIndex) {
            setState(() {
              workoutDays[dayIndex].phases.forEach((phase) {
                phase.exercises.removeAt(exerciseIndex);
              });
            });
          },
          getExerciseIcon: _getExerciseIcon,
        ),
      ),
    );
  }

  void _showAddExerciseDialog(int dayIndex, String phaseId) {
    final l10n = AppLocalizations.of(context)!;
    final List<String> equipmentTypes = [
    l10n.bodyweight,
    l10n.barbell,
    l10n.dumbbell,
    l10n.kettlebell,
    l10n.machine,
    l10n.cable,
    l10n.resistance_band,
    l10n.medicine_ball,
    l10n.trx_suspension,
    l10n.other,
  ];
    AddExerciseDialog.show(
      context: context,
      trainerExercises: trainerExercises,
      equipmentTypes: equipmentTypes,
      onAdd: (exercise) {
        setState(() {
          final phase = workoutDays[dayIndex].phases.firstWhere((p) => p.id == phaseId);
          phase.exercises.add(Exercise(
            exerciseId: exercise['exerciseId'],
            name: exercise['name'],
            equipment: exercise['equipment'],
            sets: exercise['sets'],
            instructions: exercise['instructions'],
            videoFile: exercise['videoFile'],
            imageFiles: exercise['imageFiles'],
          ));
        });
        //Navigator.pop(context);
      },
    );
  }

  void _showEditExerciseDialog(int dayIndex, int exerciseIndex, String phaseId) {
    final phase = workoutDays[dayIndex].phases.firstWhere((p) => p.id == phaseId);
    final exercise = phase.exercises[exerciseIndex];
    final l10n = AppLocalizations.of(context)!;
    final List<String> equipmentTypes = [
    l10n.bodyweight,
    l10n.barbell,
    l10n.dumbbell,
    l10n.kettlebell,
    l10n.machine,
    l10n.cable,
    l10n.resistance_band,
    l10n.medicine_ball,
    l10n.trx_suspension,
    l10n.other,
  ];

    AddExerciseDialog.show(
      context: context,
      trainerExercises: trainerExercises,
      equipmentTypes: equipmentTypes,
      isEditing: true,
      existingExercise: exercise,
      onAdd: (exerciseData) {
        setState(() {
          phase.exercises[exerciseIndex] = Exercise(
            exerciseId: exerciseData['exerciseId'],
            name: exerciseData['name'],
            equipment: exerciseData['equipment'],
            sets: exerciseData['sets'],
            instructions: exerciseData['instructions'],
            videoFile: exerciseData['videoFile'],
            imageFiles: exerciseData['imageFiles'],
          );
        });
        //Navigator.pop(context);
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final List<String> stepNames = [
      l10n.overview,
      l10n.schedule,
      l10n.details,
    ];

    return AppBar(
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: theme.brightness == Brightness.light ? Colors.black : Colors.white, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(Icons.chevron_left, color: theme.brightness == Brightness.light ? Colors.black : Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Row(
        children: [
          Text(
            widget.isEditing ? l10n.edit_plan : l10n.create_plan,
            style: GoogleFonts.plusJakartaSans(
              color: theme.brightness == Brightness.light
                  ? Colors.black
                  : Colors.white,
              fontWeight: FontWeight.w600,
              
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.fitness_center_outlined, color: theme.brightness == Brightness.light
                  ? Colors.black
                  : Colors.white, size: 20),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: CustomStepIndicator(
            currentStep: _currentStep,
            totalSteps: stepNames.length,
            stepName: stepNames[_currentStep],
          ),
        ),
      ],
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
    );
  }

  Widget _buildClientTypeSelection() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildClientTypeButton(
            'existing_client',
            'Existing Client',
            Icons.person_outline,
          ),
          const SizedBox(width: 8),
          _buildClientTypeButton(
            'manual_client',
            'Manual Client',
            Icons.person_add_outlined,
          ),
          if (!widget.isUsingTemplate) ...[
            const SizedBox(width: 8),
            _buildClientTypeButton(
              'template',
              'Template',
              Icons.save_outlined,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClientTypeButton(String type, String label, IconData icon) {
    final l10n = AppLocalizations.of(context)!;
    bool isSelected = selectedClientType == type;

    final String localizedLabel = {
      'Existing Client': l10n.existing_client,
      'Manual Client': l10n.manual_client,
      'Template': l10n.template,
    }[label] ?? label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedClientType = type;
          selectedClientId = null;
          selectedClientUsername = null;
          selectedClientFullName = null;
          selectedClientConnectionType = null;
          selectedClientProfileImageUrl = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? myBlue60.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? myBlue60 : Colors.grey[400],
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                localizedLabel,
                style: GoogleFonts.plusJakartaSans(
                  color: myBlue60,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClientField() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (selectedClientType == 'manual_client') {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: CustomFocusTextField(
          label: l10n.client_name,
          hintText: l10n.enter_client_name,
          controller: _manualClientController,
          isRequired: true,
          shouldShowBorder: true,
          prefixIcon: Icons.person_outline,
          onChanged: (value) {
            setState(() {
              manualClientName = value;
            });
          },
        ),
      );
    } else if (selectedClientType == 'template') {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light ? myBlue60.withOpacity(0.1) : myGrey10.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: theme.brightness == Brightness.light ? myBlue60.withOpacity(0.2) : myGrey10.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 20, color: theme.brightness == Brightness.light ? myBlue60 : myGrey10),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.template_info,
                    style: GoogleFonts.plusJakartaSans(
                      color: theme.brightness == Brightness.light ? myBlue60 : myGrey10,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: CustomFocusTextField(
              label: l10n.template_name,
              hintText: l10n.enter_template_name,
              controller: _templateNameController,
              isRequired: true,
              shouldShowBorder: true,
              prefixIcon: Icons.edit_document,
            ),
          ),
        ],
      );
    } else {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          onTap: () => _showClientSelectionModal(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.client} *',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        (selectedClientFullName ?? selectedClientUsername) ??
                            l10n.select_a_client,
                        style: GoogleFonts.plusJakartaSans(
                          color: selectedClientUsername != null
                              ? theme.brightness == Brightness.light ? Colors.black : Colors.white
                              : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _showClientSelectionModal(BuildContext context) {
    ClientSelectionSheet.show(
      context,
      (String clientId, String clientUsername, String clientFullName,
          String connectionType, String clientProfileImageUrl) {
        setState(() {
          selectedClientId = clientId;
          selectedClientUsername = clientUsername;
          selectedClientFullName = clientFullName;
          selectedClientConnectionType = connectionType;
          selectedClientProfileImageUrl = clientProfileImageUrl;
        });
      },
    );
  }

  Widget _buildDetailsStep() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomFocusTextField(
              label: l10n.warm_up_routine,
              hintText: l10n.describe_warmup,
              controller: _warmUpController,
              isRequired: false,
              maxLines: 3
            ),
            const SizedBox(height: 16),
            CustomFocusTextField(
              label: l10n.cool_down_routine,
              hintText: l10n.describe_cooldown,
              controller: _coolDownController,
              isRequired: false,
              maxLines: 3
            ),
            const SizedBox(height: 16),
            CustomFocusTextField(
              label: l10n.additional_notes,
              hintText: l10n.other_important_info,
              controller: _additionalNotesController,
              isRequired: false,
              maxLines: 4
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _currentStep == 0 ?
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                      _currentStep++;
                    });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: myBlue60,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.next,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ) : Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.back,
                  style: GoogleFonts.plusJakartaSans(
                    color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          if(_currentStep > 0)
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_currentStep < 2) {
                  setState(() {
                    _currentStep++;
                  });
                } else {
                  _submitForm(context);
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
                _currentStep == 2 ? (widget.isEditing ? l10n.save_changes : l10n.create_workout_plan) : l10n.next,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getExerciseIcon(String? equipment) {
    switch (equipment?.toLowerCase()) {
      case 'barbell':
        return Icons.fitness_center;
      case 'dumbbell':
        return Icons.sports_handball;
      case 'kettlebell':
        return Icons.fitness_center;
      case 'machine':
        return Icons.settings;
      case 'cable':
        return Icons.linear_scale;
      case 'resistance band':
        return Icons.waves;
      case 'bodyweight':
        return Icons.person_outline;
      default:
        return Icons.fitness_center;
    }
  }
}
