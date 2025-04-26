import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/services/notification_service.dart';

// Events
abstract class WorkoutPlanEvent {}

class CreateWorkoutPlan extends WorkoutPlanEvent {
  final Map<String, dynamic> data;
  CreateWorkoutPlan({required this.data});
}

class UpdateWorkoutPlan extends WorkoutPlanEvent {
  final String? planId;
  final Map<String, dynamic> data;

  UpdateWorkoutPlan({
    required this.planId,
    required this.data,
  });
}

// States
abstract class WorkoutPlanState {}

class WorkoutPlanInitial extends WorkoutPlanState {}

class WorkoutPlanLoading extends WorkoutPlanState {
  final double progress;
  final String status;
  
  WorkoutPlanLoading({
    required this.progress,
    required this.status,
  });
}

class WorkoutPlanSuccess extends WorkoutPlanState {}

class WorkoutPlanError extends WorkoutPlanState {
  final String message;
  WorkoutPlanError(this.message);
}

class WorkoutPlanBloc extends Bloc<WorkoutPlanEvent, WorkoutPlanState> {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final BuildContext context;
  final _notificationService = NotificationService();

  WorkoutPlanBloc(this.context) : super(WorkoutPlanInitial()) {
    on<CreateWorkoutPlan>(_createWorkoutPlan);
    on<UpdateWorkoutPlan>((event, emit) async {
      try {
        emit(WorkoutPlanLoading(progress: 0.0, status: 'Loading...'));
        
        if (event.planId == null) {
          throw Exception('Plan ID is required for updating');
        }

        await _firestore
            .collection('workout_plans')
            .doc(event.planId)
            .update(event.data);

        emit(WorkoutPlanSuccess());
      } catch (e) {
        emit(WorkoutPlanError('Failed to update workout plan: ${e.toString()}'));
      }
    });
  }


  Future<void> _createWorkoutPlan(
    CreateWorkoutPlan event,
    Emitter<WorkoutPlanState> emit,
  ) async {
    try {
      // Initialize progress tracking
      double progress = 0.0;
      emit(WorkoutPlanLoading(progress: progress, status: 'Initializing...'));

      final userProvider = context.read<UserProvider>();
      final data = event.data;

      // Count total operations for progress tracking
      int totalOperations = 1; // Base setup
      int mediaCount = 0;
      for (var day in data['workoutDays']) {
        for (var phase in day['phases']) {
          for (var exercise in phase['exercises']) {
            if (exercise['exerciseId'] == null) { // Only count new exercises
              if (exercise['videoFile'] != null && exercise['videoFile'].isNotEmpty) {
                mediaCount++;
              }
              if (exercise['imageFiles'] != null) {
                mediaCount += (exercise['imageFiles'] as List).length;
              }
              totalOperations++; // For exercise creation
            }
          }
        }
      }
      totalOperations += mediaCount;
      totalOperations += 2; // Final batch commit and data update
      
      int completedOperations = 0;

      // Continue with existing initialization
      final isAppClient = data['connectionType'] == fbAppConnectionType;
      final userTrainerClientId = userProvider.userData?['trainerClientId'] ?? '';
      final String docId = _firestore.collection('workouts').doc().id;
      final List<Map<String, dynamic>> processedWorkoutDays = [];
      final batch = _firestore.batch();

      // Update progress after initialization
      completedOperations++;
      progress = completedOperations / totalOperations;
      emit(WorkoutPlanLoading(progress: progress, status: 'Processing workout data...'));

      final trainerExercisesRef = _firestore
          .collection('trainer_exercises')
          .doc(data['trainerId'])
          .collection('all_exercises');

      // Process each day (keeping existing logic)
      for (var day in data['workoutDays']) {
        final List<Map<String, dynamic>> processedPhases = [];
        for (var phase in day['phases']) {
          final List<Map<String, dynamic>> processedExercises = [];
          for (var exercise in phase['exercises']) {
            final processedExercise = Map<String, dynamic>.from(exercise);
            
            debugPrint('Exercise name: ${exercise['name']}, exerciseId: ${exercise['exerciseId']}');
            
            // Only process and upload media for new exercises (exerciseId is null)
            String? videoUrl;
            List<String> imageUrls = [];
            
            
            if (exercise['exerciseId'] == null) {
              // Handle video upload
              if (exercise['videoFile'] != null && exercise['videoFile'].isNotEmpty) {
                emit(WorkoutPlanLoading(
                  progress: progress,
                  status: 'Uploading video for ${exercise['name']}...',
                ));
                
                final videoFile = File(exercise['videoFile']);
                if (await videoFile.exists()) {
                  final trainerVideoPath = 'trainer_exercises/${data['trainerId']}/videos/${DateTime.now().millisecondsSinceEpoch}.mp4';
                  final trainerVideoRef = _storage.ref().child(trainerVideoPath);
                  await trainerVideoRef.putFile(videoFile);
                  videoUrl = await trainerVideoRef.getDownloadURL();
                  processedExercise['videoUrl'] = videoUrl;

                  completedOperations++;
                  progress = completedOperations / totalOperations;
                  emit(WorkoutPlanLoading(progress: progress, status: 'Video uploaded'));
                }
              }
              

              // Handle image uploads
              if (exercise['imageFiles'] != null && exercise['imageFiles'].isNotEmpty) {
                for (var originalImagePath in exercise['imageFiles']) {
                  emit(WorkoutPlanLoading(
                    progress: progress,
                    status: 'Uploading images for ${exercise['name']}...',
                  ));

                  if (originalImagePath != null && originalImagePath.isNotEmpty) {
                    try {
                      final imageFile = File(originalImagePath);
                      if (await imageFile.exists()) {
                        final trainerImagePath = 'trainer_exercises/${data['trainerId']}/images/${DateTime.now().millisecondsSinceEpoch}.jpg';
                        final trainerImageRef = _storage.ref().child(trainerImagePath);
                        final compressedImage = await FlutterImageCompress.compressWithFile(
                          originalImagePath,
                          quality: 70,
                        );
                        if (compressedImage != null) {
                          await trainerImageRef.putData(compressedImage);
                          final imageUrl = await trainerImageRef.getDownloadURL();
                          imageUrls.add(imageUrl);

                          completedOperations++;
                          progress = completedOperations / totalOperations;
                          emit(WorkoutPlanLoading(progress: progress, status: 'Image uploaded'));
                        }
                      }
                    } catch (e) {
                      debugPrint('Error processing image: $e');
                      continue;
                    }
                  }
                }
                if (imageUrls.isNotEmpty) {
                  processedExercise['imageUrls'] = imageUrls;
                }
              }
            } else {
              // For existing exercises, use the existing URLs
              processedExercise['videoUrl'] = exercise['videoUrl'];
              processedExercise['imageUrls'] = exercise['imageUrls'];
            }

            if (exercise['exerciseId'] == null) {
              debugPrint('Creating new exercise: ${exercise['name']}');
              // New exercise - create and store it
              final exerciseId = trainerExercisesRef.doc().id;
              final exerciseData = {
                'exerciseId': exerciseId,
                'name': exercise['name'],
                'equipment': exercise['equipment'],
                'instructions': exercise['instructions'],
                'sets': exercise['sets'],
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
                'isBookmarked': false,
                'usageCount': 1,
                'videoFile': exercise['videoFile'],
                'imageFiles': exercise['imageFiles'],
                'videoUrl': videoUrl,
                'imageUrls': imageUrls,
              };
              
              batch.set(trainerExercisesRef.doc(exerciseId), exerciseData);
              processedExercise['exerciseId'] = exerciseId;
            } else {
              debugPrint('Updating existing exercise: ${exercise['name']}');
              // Existing exercise - update usage count
              batch.update(trainerExercisesRef.doc(exercise['exerciseId']), {
                'usageCount': FieldValue.increment(1),
                'updatedAt': FieldValue.serverTimestamp(),
              });


              completedOperations++;
              progress = completedOperations / totalOperations;
              emit(WorkoutPlanLoading(
                progress: progress,
                status: 'Exercise created: ${exercise['name']}',
              ));
            }

            processedExercises.add(processedExercise);
          }
          
          processedPhases.add({
            ...phase,
            'exercises': processedExercises,
          });
        }

        processedWorkoutDays.add({
          ...day,
          'phases': processedPhases,
        });
      }

      // Continue with existing final operations
      emit(WorkoutPlanLoading(progress: 0.9, status: 'Saving workout plan...'));

      final processedData = {
        ...data,
        'workoutDays': processedWorkoutDays,
      };

      final trainerWorkoutRef = _firestore
          .collection('workouts')
          .doc('trainers')
          .collection(data['trainerId'])
          .doc(docId);
      batch.set(trainerWorkoutRef, {...processedData, 'planId': docId});

      if (isAppClient) {
        final clientWorkoutRef = _firestore
            .collection('workouts')
            .doc('clients')
            .collection(data['clientId'])
            .doc(docId);
        batch.set(clientWorkoutRef, {...processedData, 'planId': docId});

        if (data['clientId'] != userTrainerClientId) {
          await _notificationService.createWorkoutPlanNotification(
            clientId: data['clientId'],
            trainerId: data['trainerId'],
            planId: docId,
            planData: processedData,
          );
        }
      }

      await batch.commit();
      completedOperations++;
      progress = completedOperations / totalOperations;
      emit(WorkoutPlanLoading(progress: progress, status: 'Finalizing...'));

      await userProvider.addWorkoutPlan(event.data['trainerId'], processedData);
      completedOperations++;
      progress = 1.0;
      emit(WorkoutPlanLoading(progress: progress, status: 'Complete!'));

      emit(WorkoutPlanSuccess());
    } catch (e) {
      debugPrint('Error creating workout plan: $e');
      emit(WorkoutPlanError('Failed to create workout plan: ${e.toString()}'));
    }
  }
} 