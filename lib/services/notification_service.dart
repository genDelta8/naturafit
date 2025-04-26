import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:flutter/material.dart';








class NotificationService {
  final FirebaseFirestore _firestore;

  NotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> createSessionNotification({
    required String clientId,
    required String senderId,
    required String sessionId,
    required Map<String, dynamic> sessionData,
    required String connectionType,
    bool isRecurring = false,
    bool isGroupSession = false,
  }) async {
    try {
      if (clientId != senderId && connectionType == fbAppConnectionType) {
        final notificationRef = _firestore
            .collection('notifications')
            .doc(clientId)
            .collection('allNotifications')
            .doc();

        // Create base notification data
        final notificationData = {
          'title': _getNotificationTitle(isRecurring, isGroupSession),
          'message': _getNotificationMessage(
            sessionCategory: sessionData['sessionCategory'],
            isRecurring: isRecurring,
            totalWeeks: sessionData['totalRecurringWeeks'],
            isGroupSession: isGroupSession,
          ),
          'type': _getNotificationType(isRecurring, isGroupSession),
          'senderId': senderId,
          'relatedDocId': sessionId,
          'data': Map<String, dynamic>.from(sessionData), // Create a copy
          'read': false,
          'requiresAction': true,
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Add recurring fields only if the session is recurring
        if (isRecurring) {
          (notificationData['data'] as Map<String, dynamic>)['recurringId'] =
              sessionData['recurringId'];
          (notificationData['data']
                  as Map<String, dynamic>)['totalRecurringWeeks'] =
              sessionData['totalRecurringWeeks'];
          (notificationData['data'] as Map<String, dynamic>)['recurringWeek'] =
              sessionData['recurringWeek'];
        }

        await notificationRef.set(notificationData);
      }
      else {
        debugPrint('Client ID is the same as sender ID');
      }
    } catch (e) {
      debugPrint('Error creating notification: $e');
      rethrow;
    }
  }

  Future<void> createWorkoutPlanNotification({
    required String clientId,
    required String trainerId,
    required String planId,
    required Map<String, dynamic> planData,
  }) async {
    try {
      if (clientId != trainerId && planData['connectionType'] == fbAppConnectionType) {
        final notificationRef = _firestore
            .collection('notifications')
            .doc(clientId)
            .collection('allNotifications')
            .doc();

        await notificationRef.set({
          'userId': clientId,
          'type': 'new_workout_plan',
          'title': 'New Workout Plan',
          'message': '${planData['trainerFullName'] ?? planData['trainerName']} has created a new workout plan: ${planData['planName']}',
          'senderRole': 'trainer',
          'senderId': trainerId,
          'senderFullName': planData['trainerFullName'] ?? planData['trainerName'],
          'senderUsername': planData['trainerName'],
          'senderProfileImageUrl': planData['trainerProfileImageUrl'] ?? '',
          'relatedDocId': planId,
          'status': 'unread',
          'requiresAction': true,
          'actionType': 'workout_plan_approval',
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
          'data': {
            'planName': planData['planName'],
            'planId': planId,
            'senderId': trainerId,
            'duration': planData['duration'],
            'workoutType': planData['workoutType'],
          },
        });
      }
    } catch (e) {
      debugPrint('Error creating workout plan notification: $e');
      rethrow;
    }
  }

  Future<void> createMealPlanNotification({
    required String clientId,
    required String trainerId,
    required String planId,
    required Map<String, dynamic> planData,
  }) async {
    try {
      if (clientId != trainerId && planData['connectionType'] == fbAppConnectionType) {
        final notificationRef = _firestore
            .collection('notifications')
            .doc(clientId)
            .collection('allNotifications')
            .doc();

        await notificationRef.set({
          'userId': clientId,
          'type': 'new_meal_plan',
          'title': 'New Meal Plan',
          'message': '${planData['trainerName']} has created a new meal plan: ${planData['planName']}',
          'senderRole': 'trainer',
          'professionalRole': 'trainer',
          'senderId': trainerId,
          'senderName': planData['trainerName'],
          'relatedDocId': planId,
          'status': 'unread',
          'requiresAction': true,
          'actionType': 'meal_plan_approval',
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
          'data': {
            'planName': planData['planName'],
            'planId': planId,
            'senderId': trainerId,
            'duration': planData['duration'],
            'dietType': planData['dietType'],
            'calories': planData['caloriesTarget'],
          },
        });
      }
    } catch (e) {
      debugPrint('Error creating meal plan notification: $e');
      rethrow;
    }
  }

  Future<void> createSessionRequestNotification({
    required String trainerId,
    required String clientId,
    required String sessionId,
    required Map<String, dynamic> sessionData,
    required Map<String, dynamic> clientData,
    required bool isGroupSession,
  }) async {
    
    try {
      
      if (trainerId != clientId) {
      final notificationRef = _firestore
          .collection('notifications')
          .doc(trainerId)
          .collection('allNotifications')
          .doc();

      await notificationRef.set({
        'userId': trainerId,
        'type': isGroupSession ? 'group_session_request' : 'session_request',
        'title': isGroupSession ? 'New Group Session Request' : 'New Session Request',
        'message': isGroupSession 
            ? '${clientData['fullName'] ?? clientData['username']} wants to participate in your group ${sessionData['sessionCategory']} session'
            : '${clientData['fullName'] ?? clientData['username']} wants to book your available ${sessionData['sessionCategory']} session',
        'senderRole': 'client',
        'senderId': clientId,
        'senderFullName': clientData['fullName'],
        'senderUsername': clientData['username'],
        'senderProfileImageUrl': clientData['profileImageUrl'] ?? '',
        'relatedDocId': sessionId,
        'status': 'unread',
        'requiresAction': false,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'data': {
          'senderId': clientId,
          'sessionId': sessionId,
          'sessionCategory': sessionData['sessionCategory'],
          'sessionDate': sessionData['sessionDate'],
          'time': sessionData['time'],
        },
      });
      }
      else {
        debugPrint('Trainer ID is the same as client ID');
      }
    } catch (e) {
      debugPrint('Error creating session request notification: $e');
      rethrow;
    }
  }

  Future<void> createSessionRequestResponseNotification({
    required String clientId,
    required String trainerId,
    required String sessionId,
    required Map<String, dynamic> sessionData,
    required Map<String, dynamic> trainerData,
    required bool isAccepted,
    bool isGroupSession = true,
  }) async {
    try {
      if (clientId != trainerId) {
        final notificationRef = _firestore
            .collection('notifications')
            .doc(clientId)
            .collection('allNotifications')
            .doc();

        await notificationRef.set({
          'userId': clientId,
          'type': isAccepted ? 'session_request_accepted' : 'session_request_declined',
          'title': isAccepted ? 'Session Request Accepted' : 'Session Request Declined',
          'message': isAccepted 
              ? '${trainerData['fullName'] ?? trainerData['username']} has accepted your request to join the ${sessionData['sessionCategory']} group session'
              : '${trainerData['fullName'] ?? trainerData['username']} has declined your request to join the ${sessionData['sessionCategory']} group session',
          'senderRole': 'trainer',
          'senderId': trainerId,
          'senderFullName': trainerData['fullName'],
          'senderUsername': trainerData['username'],
          'senderProfileImageUrl': trainerData['profileImageUrl'] ?? '',
          'relatedDocId': sessionId,
          'status': 'unread',
          'requiresAction': false,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
          'data': {
            'senderId': trainerId,
            'sessionId': sessionId,
            'sessionCategory': sessionData['sessionCategory'],
            'sessionDate': sessionData['sessionDate'],
            'time': sessionData['time'],
          },
        });
      }
    } catch (e) {
      debugPrint('Error creating session request response notification: $e');
      rethrow;
    }
  }

  Future<void> createSessionCancelledNotificationByTrainer({
    required String clientId,
    required String trainerId,
    required String sessionId,
    required Map<String, dynamic> sessionData,
    required Map<String, dynamic> trainerData,
    bool isGroupSession = false,
  }) async {
    try {
      if (clientId != trainerId) {
        final notificationRef = _firestore
            .collection('notifications')
            .doc(clientId)
            .collection('allNotifications')
            .doc();

        await notificationRef.set({
          'userId': clientId,
          'type': isGroupSession ? 'group_session_cancelled' : 'session_cancelled',
          'title': 'Session Cancelled',
          'message': '${trainerData['fullName'] ?? trainerData['username']} has cancelled the ${isGroupSession ? "group " : ""}${sessionData['sessionCategory']} session',
          'senderRole': 'trainer',
          'senderId': trainerId,
          'senderFullName': trainerData['fullName'],
          'senderUsername': trainerData['username'],
          'senderProfileImageUrl': trainerData['profileImageUrl'] ?? '',
          'relatedDocId': sessionId,
          'status': 'unread',
          'requiresAction': false,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
          'data': {
            'senderId': trainerId,
            'sessionId': sessionId,
            'sessionCategory': sessionData['sessionCategory'],
            'sessionDate': sessionData['sessionDate'],
            'time': sessionData['time'],
          },
        });
      }
    } catch (e) {
      debugPrint('Error creating session cancelled notification: $e');
      rethrow;
    }
  }

  Future<void> createSessionCancelledNotificationByClient({
    required String trainerId,
    required String clientId,
    required String sessionId,
    required Map<String, dynamic> sessionData,
    required Map<String, dynamic> clientData,
    bool isGroupSession = false,
  }) async {
    try {
      if (trainerId != clientId) {
        final notificationRef = _firestore
            .collection('notifications')
            .doc(trainerId)
            .collection('allNotifications')
            .doc();

        await notificationRef.set({
          'userId': trainerId,
          'type': isGroupSession ? 'client_left_group' : 'session_cancelled_by_client',
          'title': isGroupSession ? 'Client Left Group' : 'Session Cancelled',
          'message': isGroupSession 
              ? '${clientData['fullName'] ?? clientData['username']} has left your ${sessionData['sessionCategory']} group session'
              : '${clientData['fullName'] ?? clientData['username']} has cancelled the ${sessionData['sessionCategory']} session',
          'senderRole': 'client',
          'senderId': clientId,
          'senderFullName': clientData['fullName'],
          'senderUsername': clientData['username'],
          'senderProfileImageUrl': clientData['profileImageUrl'] ?? '',
          'relatedDocId': sessionId,
          'status': 'unread',
          'requiresAction': false,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
          'data': {
            'senderId': clientId,
            'sessionId': sessionId,
            'sessionCategory': sessionData['sessionCategory'],
            'sessionDate': sessionData['sessionDate'],
            'time': sessionData['time'],
          },
        });
      }
    } catch (e) {
      debugPrint('Error creating session cancelled notification: $e');
      rethrow;
    }
  }

  Future<void> createAssessmentRequestNotification({
    required String clientId,
    required String trainerId,
    required String assessmentId,
    required Map<String, dynamic> trainerData,
  }) async {
    try {
      //if (clientId != trainerId) {
      if (true) {
        final notificationRef = _firestore
            .collection('notifications')
            .doc(clientId)
            .collection('allNotifications')
            .doc();

        await notificationRef.set({
          'userId': clientId,
          'type': 'assessment_request',
          'title': 'New Assessment Form',
          'message': '${trainerData['fullName'] ?? trainerData['name']} has requested you to fill out an assessment form',
          'senderRole': 'trainer',
          'senderId': trainerId,
          'senderFullName': trainerData['fullName'] ?? trainerData['name'],
          'senderUsername': trainerData['name'],
          'senderProfileImageUrl': trainerData['profileImageUrl'] ?? '',
          'relatedDocId': assessmentId,
          'status': 'unread',
          'requiresAction': true,
          'actionType': 'assessment_form',
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
          'data': {
            'assessmentId': assessmentId,
            'senderId': trainerId,
          },
        });
      }
    } catch (e) {
      debugPrint('Error creating assessment request notification: $e');
      rethrow;
    }
  }

  Future<void> createSessionUpdatedNotification({
    required String clientId,
    required String trainerId,
    required String sessionId,
    required Map<String, dynamic> sessionData,
    required Map<String, dynamic> trainerData,
    bool isGroupSession = false,
  }) async {
    try {
      if (clientId != trainerId) {
        final notificationRef = _firestore
            .collection('notifications')
            .doc(clientId)
            .collection('allNotifications')
            .doc();

        await notificationRef.set({
          'userId': clientId,
          'type': isGroupSession ? 'group_session_updated' : 'session_updated',
          'title': 'Session Updated',
          'message': '${trainerData['fullName'] ?? trainerData['username']} has updated the ${isGroupSession ? "group " : ""}${sessionData['sessionCategory']} session details',
          'senderRole': 'trainer',
          'senderId': trainerId,
          'senderFullName': trainerData['fullName'],
          'senderUsername': trainerData['username'],
          'senderProfileImageUrl': trainerData['profileImageUrl'] ?? '',
          'relatedDocId': sessionId,
          'status': 'unread',
          'requiresAction': false,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
          'data': {
            'senderId': trainerId,
            'sessionId': sessionId,
            'sessionCategory': sessionData['sessionCategory'],
            'sessionDate': sessionData['sessionDate'],
            'time': sessionData['time'],
            'duration': sessionData['duration'],
            'mode': sessionData['mode'],
          },
        });
      }
    } catch (e) {
      debugPrint('Error creating session updated notification: $e');
      rethrow;
    }
  }

  Future<void> createWorkoutCompletedNotification({
    required String trainerId,
    required String clientId,
    required String workoutHistoryId,
    required Map<String, dynamic> workoutData,
    required Map<String, dynamic> clientData,
  }) async {
    try {
      if (trainerId != clientId) {
        final notificationRef = _firestore
            .collection('notifications')
            .doc(trainerId)
            .collection('allNotifications')
            .doc();

        await notificationRef.set({
          'userId': trainerId,
          'type': 'workout_completed',
          'title': 'Workout Completed',
          'message': '${clientData['fullName'] ?? clientData['username']} has completed the workout: ${workoutData['planName']}',
          'senderRole': 'client',
          'senderId': clientId,
          'senderFullName': clientData['fullName'],
          'senderUsername': clientData['username'],
          'senderProfileImageUrl': clientData['profileImageUrl'] ?? '',
          'relatedDocId': workoutHistoryId,
          'status': 'unread',
          'requiresAction': false,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
          'data': {
            'workoutHistoryId': workoutHistoryId,
            'planId': workoutData['planId'],
            'planName': workoutData['planName'],
            'dayNumber': workoutData['dayNumber'],
            'difficulty': workoutData['finishDifficulty'],
            'duration': workoutData['totalDuration'],
            'senderId': clientId,
          },
        });
      }
    } catch (e) {
      debugPrint('Error creating workout completed notification: $e');
      rethrow;
    }
  }


  Future<void> createAssessmentSubmittedNotification({
    required String userId,  // trainer's ID
    required String title,
    required String message,
    required Map<String, dynamic> data,
  }) async {
    try {
      final notificationRef = _firestore
          .collection('notifications')
          .doc(userId)
          .collection('allNotifications')
          .doc();

      await notificationRef.set({
        'userId': userId,
        'type': 'assessment_submitted',
        'title': title,
        'message': message,
        'senderRole': 'client',
        'senderId': data['clientId'],
        'senderFullName': data['clientName'],
        'relatedDocId': data['formId'],
        'status': 'unread',
        'requiresAction': false,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'data': data,
      });
    } catch (e) {
      debugPrint('Error creating assessment submitted notification: $e');
      rethrow;
    }
  }

  String _getNotificationTitle(bool isRecurring, bool isGroupSession) {
    if (isRecurring && isGroupSession) {
      return 'New Recurring Group Session Request';
    } else if (isRecurring) {
      return 'New Recurring Session Request';
    } else if (isGroupSession) {
      return 'New Group Session Request';
    } else {
      return 'New Session Request';
    }
  }

  String _getNotificationMessage({
    required String sessionCategory,
    required bool isRecurring,
    required bool isGroupSession,
    int? totalWeeks,
  }) {
    if (isRecurring) {
      return 'You have a new recurring ${isGroupSession ? "group " : ""}$sessionCategory session request for $totalWeeks weeks';
    } else {
      return 'You have ${isGroupSession ? "been invited to a group" : "a new"} $sessionCategory session request';
    }
  }

  String _getNotificationType(bool isRecurring, bool isGroupSession) {
    if (isRecurring && isGroupSession) {
      return 'new_recurring_group_session_request';
    } else if (isRecurring) {
      return 'new_recurring_session_request';
    } else if (isGroupSession) {
      return 'new_group_session_request';
    } else {
      return 'new_session_request';
    }
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      // Get all unread notifications
      final unreadNotificationsSnapshot = await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('allNotifications')
          .where('read', isEqualTo: false)
          .get();

      // Create a batch write
      final batch = _firestore.batch();

      // Add update operations to batch
      for (var doc in unreadNotificationsSnapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      // Commit the batch
      await batch.commit();
      
      debugPrint('Marked ${unreadNotificationsSnapshot.docs.length} notifications as read');
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
      rethrow;
    }
  }
}
