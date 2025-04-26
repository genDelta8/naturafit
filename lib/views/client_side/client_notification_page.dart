import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/views/trainer_side/assessment_form_page.dart';
import 'package:naturafit/widgets/custom_expandable_search.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String time;
  final String type;
  final String? senderName;
  final String? senderFullName;
  final String? senderUsername;
  final String? senderProfileImageUrl;
  final String? senderRole;
  final String? relatedDocId;
  final bool requiresAction;
  final Map<String, dynamic>? data;
  final bool read;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.senderName,
    this.senderFullName,
    this.senderUsername,
    this.senderProfileImageUrl,
    this.senderRole,
    this.relatedDocId,
    this.requiresAction = false,
    this.data,
    this.read = false,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      time: _formatTimestamp(data['createdAt'] as Timestamp?),
      type: data['type'] ?? '',
      senderName: data['senderName'],
      senderFullName: data['senderFullName'],
      senderUsername: data['senderUsername'],
      senderProfileImageUrl: data['senderProfileImageUrl'],
      senderRole: data['senderRole'],
      relatedDocId: data['relatedDocId'],
      requiresAction: data['requiresAction'] ?? false,
      data: data['data'] as Map<String, dynamic>?,
      read: data['read'] ?? false,
    );
  }

  static String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userId = userProvider.userData?['userId'];
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final myIsWebOrDektop = isWebOrDesktopCached;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: myIsWebOrDektop
            ? const SizedBox.shrink()
            : Container(
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
        actions: myIsWebOrDektop
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CustomExpandableSearch(
                    hintText: l10n.search_notifications,
                    onChanged: (value) {
                      setState(() {
                        _searchController.text = value;
                      });
                    },
                  ),
                ),
              ]
            : [],
        centerTitle: myIsWebOrDektop ? false : true,
        title: Text(
          l10n.notifications,
          style: GoogleFonts.plusJakartaSans(
            color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .doc(userId)
            .collection('allNotifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: myBlue60));
          }

          final notifications = snapshot.data!.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();

          if (notifications.isEmpty) {
            return Center(
              child: Text(
                l10n.no_notifications,
                style: GoogleFonts.plusJakartaSans(
                  color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                  fontSize: 16,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationsList(notifications, userId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationsList(
      List<NotificationModel> notifications, String userId) {
    final unreadNotifications = notifications.where((n) => !n.read).toList();
    final readNotifications = notifications.where((n) => n.read).toList();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (unreadNotifications.isNotEmpty) ...[
          Text(
            'New',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.brightness == Brightness.light ? myGrey70 : myGrey30,
            ),
          ),
          const SizedBox(height: 16),
          ...unreadNotifications.map(
              (notification) => _buildNotificationCard(notification, userId)),
          const SizedBox(height: 24),
        ],
        if (readNotifications.isNotEmpty) ...[
          Text(
            'Earlier',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.brightness == Brightness.light ? myGrey70 : myGrey30,
            ),
          ),
          const SizedBox(height: 16),
          ...readNotifications.map(
              (notification) => _buildNotificationCard(notification, userId)),
        ],
      ],
    );
  }

/*
Widget _buildNotificationsList(
    List<NotificationModel> notifications, String userId) {
  // Sort all notifications by timestamp (newest first)
  final sortedNotifications = List<NotificationModel>.from(notifications);
  sortedNotifications.sort((a, b) {
    final aMinutes = _getMinutesFromTimeString(a.time);
    final bMinutes = _getMinutesFromTimeString(b.time);
    return aMinutes.compareTo(bMinutes);
  });

  // Get the start of the current week (Sunday)
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday));

  // Separate notifications into this week and earlier
  final thisWeekNotifications = sortedNotifications.where((notification) {
    // Parse the notification time
    if (notification.time.contains('m ago') || 
        notification.time.contains('h ago') || 
        notification.time.contains('d ago') && 
        int.parse(notification.time.split('d')[0]) < 7) {
      return true;
    }
    
    // For date format dd/mm/yyyy
    if (notification.time.contains('/')) {
      final parts = notification.time.split('/');
      if (parts.length == 3) {
        final notificationDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
        return notificationDate.isAfter(startOfWeek);
      }
    }
    return false;
  }).toList();

  final earlierNotifications = sortedNotifications.where((notification) => 
    !thisWeekNotifications.contains(notification)).toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Show this week's notifications first
      if (thisWeekNotifications.isNotEmpty) ...[
        Text(
          'New',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 16),
        ...thisWeekNotifications.map((notification) => 
          _buildNotificationCard(notification, userId)
        ),
        if (earlierNotifications.isNotEmpty) 
          const SizedBox(height: 24),
      ],
      // Then show earlier notifications
      if (earlierNotifications.isNotEmpty) ...[
        Text(
          'Earlier',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 16),
        ...earlierNotifications.map((notification) => 
          _buildNotificationCard(notification, userId)
        ),
      ],
    ],
  );
}
*/

// Helper function to convert time strings to minutes for comparison
  int _getMinutesFromTimeString(String timeString) {
    if (timeString.contains('m ago')) {
      return int.parse(timeString.split('m')[0]);
    } else if (timeString.contains('h ago')) {
      return int.parse(timeString.split('h')[0]) * 60;
    } else if (timeString.contains('d ago')) {
      return int.parse(timeString.split('d')[0]) * 24 * 60;
    } else {
      // For dates in format 'dd/mm/yyyy', return a large number to put them at the end
      return 999999;
    }
  }

  Widget _buildNotificationCard(NotificationModel notification, String userId) {

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;


    return Builder(
      builder: (context) {
        IconData icon;
        Color iconColor;
        Color iconBackgroundColor;

        // Update notification type handling
        switch (notification.type) {
          case 'new_workout_plan':
            icon = Icons.fitness_center;
            iconColor = Colors.white;
            iconBackgroundColor = myBlue60;
            break;
          case 'new_meal_plan':
            icon = Icons.restaurant_menu;
            iconColor = Colors.white;
            iconBackgroundColor = myGreen50;
            break;
          case 'new_session_request':
          case 'new_group_session_request':
          case 'new_recurring_session_request':
          case 'new_recurring_group_session_request':
            icon = notification.type.contains('group') ? Icons.group : Icons.event;
            iconColor = Colors.white;
            iconBackgroundColor = myPurple60;
            break;
          case 'session_request_accepted':
            icon = Icons.check_circle;
            iconColor = Colors.white;
            iconBackgroundColor = Colors.green;
            break;
          case 'session_request_declined':
            icon = Icons.cancel;
            iconColor = Colors.white;
            iconBackgroundColor = Colors.red;
            break;
          case 'session_cancelled':
          case 'group_session_cancelled':
            icon = Icons.event_busy;
            iconColor = Colors.white;
            iconBackgroundColor = Colors.orange;
            break;
          case 'assessment_request':
            icon = Icons.assignment;
            iconColor = Colors.white;
            iconBackgroundColor = myTeal40;
            break;
          default:
            icon = Icons.notifications;
            iconColor = Colors.white;
            iconBackgroundColor = Colors.grey;
        }


        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light ? Colors.white : myGrey90,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.brightness == Brightness.light ? Colors.grey.withOpacity(0.1) : myGrey70.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                            color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (notification.type == 'new_workout_plan' &&
                            notification.data != null) ...[
                          const SizedBox(height: 8),
                          _buildWorkoutPlanDetails(notification.data!),
                        ] else if (notification.type == 'new_meal_plan' &&
                            notification.data != null) ...[
                          const SizedBox(height: 8),
                          _buildMealPlanDetails(notification.data!),
                        ] else if ((notification.type ==
                                    'new_session_request' ||
                                notification.type ==
                                    'new_group_session_request') &&
                            notification.data != null) ...[
                          const SizedBox(height: 8),
                          _buildSessionDetails(notification.data!),
                        ],
                        if (notification.type == 'new_assessment_request' &&
                            notification.data != null) ...[
                          const SizedBox(height: 8),
                          _buildAssessmentDetails(notification.data!),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    notification.time,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              // Add this condition for assessment notifications
              if (notification.type == 'assessment_request') ...[
                const SizedBox(height: 16),
                SizedBox(
                  //width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssessmentFormPage(
                            clientId: userId,
                            clientName: notification.data?['clientName'] ?? '',
                            //client: notification.data ?? {},
                            isEnteredByTrainer: false,  // This is client view
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      //backgroundColor: myTeal40,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: myTeal40,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      'View Assessment Form',
                      style: GoogleFonts.plusJakartaSans(
                        color: myTeal40,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              // Inside _buildNotificationCard, after the Row with icon and message
              if ((notification.type == 'new_workout_plan' ||
                      notification.type == 'new_meal_plan' ||
                      notification.type == 'new_session_request' ||
                      notification.type ==
                          'new_group_session_request') && // Add group session type
                  notification.requiresAction &&
                  !notification.read) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          switch (notification.type) {
                            case 'new_meal_plan':
                              _handleMealPlanResponse(
                                  context, notification, userId, false);
                              break;
                            case 'new_workout_plan':
                              _handleWorkoutPlanResponse(
                                  context, notification, userId, false);
                              break;
                            case 'new_session_request':
                              _handleSessionResponse(
                                  context, notification, userId, false);
                              break;
                            case 'new_group_session_request':
                              _handleGroupSessionResponse(
                                  context, notification, userId, false);
                              break;
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(
                            color: notification.type == 'new_meal_plan'
                                ? const Color(0xFF00B074)
                                : notification.type == 'new_session_request' ||
                                        notification.type ==
                                            'new_group_session_request'
                                    ? const Color(0xFF9747FF)
                                    : const Color(0xFF0066FF),
                          ),
                        ),
                        child: Text(
                          l10n.decline,
                          style: GoogleFonts.plusJakartaSans(
                            color: notification.type == 'new_meal_plan'
                                ? const Color(0xFF00B074)
                                : notification.type == 'new_session_request' ||
                                        notification.type ==
                                            'new_group_session_request'
                                    ? const Color(0xFF9747FF)
                                    : const Color(0xFF0066FF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          switch (notification.type) {
                            case 'new_meal_plan':
                              _handleMealPlanResponse(
                                  context, notification, userId, true);
                              break;
                            case 'new_workout_plan':
                              _handleWorkoutPlanResponse(
                                  context, notification, userId, true);
                              break;
                            case 'new_session_request':
                              _handleSessionResponse(
                                  context, notification, userId, true);
                              break;
                            case 'new_group_session_request':
                              _handleGroupSessionResponse(
                                  context, notification, userId, true);
                              break;
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: notification.type == 'new_meal_plan'
                              ? const Color(0xFF00B074)
                              : notification.type == 'new_session_request' ||
                                      notification.type ==
                                          'new_group_session_request'
                                  ? const Color(0xFF9747FF)
                                  : const Color(0xFF0066FF),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          l10n.accept,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionDetails(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailTag('Type: ${data['sessionType'] != '' ? data['sessionType'].toString().capitalize() : 'N/A'}'),
        const SizedBox(height: 4),
        _buildDetailTag('Mode: ${data['mode'] != '' ? data['mode'].toString().capitalize() : 'N/A'}'),
        const SizedBox(height: 4),
        _buildDetailTag('Duration: ${data['duration'] != '' ? data['duration'] : 'N/A'} minutes'),
        if (data['sessionCategory'] != null) ...[
          const SizedBox(height: 4),
          _buildDetailTag('Category: ${data['sessionCategory'] != '' ? data['sessionCategory'] : 'N/A'}'),
        ],
        if (data['isGroupSession'] == true && data['totalClients'] != null) ...[
          const SizedBox(height: 4),
          _buildDetailTag('Group Size: ${data['totalClients'] != '' ? data['totalClients'] : 'N/A'} participants'),
        ],
      ],
    );
  }

  Future<void> _handleGroupSessionResponse(
    BuildContext context,
    NotificationModel notification,
    String userId,
    bool accepted,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      if (notification.data == null) {
        throw 'Missing notification data';
      }

      final senderId = notification.data!['senderId'];
      final sessionId =
          notification.relatedDocId ?? notification.data!['sessionId'];

      if (senderId == null) throw 'Missing sender ID';
      if (sessionId == null) throw 'Missing session ID';

      final batch = FirebaseFirestore.instance.batch();

      // Update notification
      final notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('allNotifications')
          .doc(notification.id);

      batch.update(notificationRef, {
        'read': true,
        'status': accepted ? fbClientConfirmedStatus : fbClientRejectedStatus,
        'responseDate': FieldValue.serverTimestamp(),
      });

      // Get current session data
      final sessionRef = FirebaseFirestore.instance
          .collection('trainer_sessions')
          .doc(senderId)
          .collection('allTrainerSessions')
          .doc(sessionId);

      final sessionDoc = await sessionRef.get();
      if (!sessionDoc.exists) {
        throw 'Session not found';
      }

      final sessionData = sessionDoc.data() as Map<String, dynamic>;
      final List<Map<String, dynamic>> clients =
          List<Map<String, dynamic>>.from(sessionData['clients'] ?? []);

      // Update this client's status without using serverTimestamp
      final now = Timestamp.now();
      for (var i = 0; i < clients.length; i++) {
        if (clients[i]['clientId'] == userId) {
          clients[i] = {
            ...clients[i],
            'status':
                accepted ? fbClientConfirmedStatus : fbClientRejectedStatus,
            'responseDate':
                now, // Use regular Timestamp instead of serverTimestamp
          };
          break;
        }
      }

      // Update the session
      batch.update(sessionRef, {
        'clients': clients,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also update client's session copy
      final clientSessionRef = FirebaseFirestore.instance
          .collection('client_sessions')
          .doc(userId)
          .collection('allClientSessions')
          .doc(sessionId);

      batch.update(clientSessionRef, {
        'clients': clients,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        accepted
            ? CustomSnackBar.show(
                                    title: l10n.group_session,
                                    message: l10n.group_session_accepted,
                                    type: SnackBarType.success,
                                  )
            : CustomSnackBar.show(
                                    title: l10n.group_session,
                                    message: l10n.group_session_rejected,
                                    type: SnackBarType.error,
                                  ),
        );
              
      }
    } catch (e) {
      debugPrint('Error in _handleGroupSessionResponse: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
                                    title: l10n.group_session,
                                    message: l10n.unable_to_process_your_request(e.toString()),
                                    type: SnackBarType.error,
                                  ),
        );
      }
    }
  }

  Future<void> _handleSessionResponse(
    BuildContext context,
    NotificationModel notification,
    String userId,
    bool accepted,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      if (notification.data == null) {
        throw 'Missing notification data';
      }

      final senderId = notification.data!['senderId'];
      if (senderId == null) throw 'Missing sender ID';

      final sessionId = notification.relatedDocId;
      if (sessionId == null) throw 'Missing session ID';

      final batch = FirebaseFirestore.instance.batch();

      // Update notification
      final notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('allNotifications')
          .doc(notification.id);

      batch.update(notificationRef, {
        'read': true,
        'status': accepted ? fbClientConfirmedStatus : fbClientRejectedStatus,
        'responseDate': FieldValue.serverTimestamp(),
      });

      // Update session status
      final isGroupSession = notification.type.contains('group');
      final isRecurring = notification.type.contains('recurring');

      // Update session in trainer's collection with correct path
      final sessionRef = FirebaseFirestore.instance
          .collection('trainer_sessions')
          .doc(senderId) // trainer's ID
          .collection('allTrainerSessions')
          .doc(sessionId);

      batch.update(sessionRef, {
        'status': accepted ? fbClientConfirmedStatus : fbClientRejectedStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also update client's session copy
      final clientSessionRef = FirebaseFirestore.instance
          .collection('client_sessions')
          .doc(userId)
          .collection('allClientSessions')
          .doc(sessionId);

      batch.update(clientSessionRef, {
        'status': accepted ? fbClientConfirmedStatus : fbClientRejectedStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (context.mounted) {
        final message = isRecurring
            ? '${notification.data!['totalRecurringWeeks']} recurring sessions ${accepted ? fbClientConfirmedStatus : fbClientRejectedStatus}'
            : 'Session ${accepted ? fbClientConfirmedStatus : fbClientRejectedStatus}';

        ScaffoldMessenger.of(context).showSnackBar(
        accepted ? CustomSnackBar.show(
                                    title: l10n.session,
                                    message: message,
                                    type: SnackBarType.success,
                                  )
        : CustomSnackBar.show(
                                    title: l10n.session,
                                    message: message,
                                    type: SnackBarType.error,
                                  ),
        );
        
      }
    } catch (e) {
      debugPrint('Error in _handleSessionResponse: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
                                    title: l10n.session,
                                    message: l10n.unable_to_process_your_request(e.toString()),
                                    type: SnackBarType.error,
                                  ),
        );
      }
    }
  }

  Widget _buildMealPlanDetails(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailTag('Plan: ${data['planName'] != '' ? data['planName'] : 'N/A'}'),
        const SizedBox(height: 4),
        _buildDetailTag('Duration: ${data['duration'] != '' ? data['duration'] : 'N/A'}'),
        if (data['dietType'] != null) ...[
          const SizedBox(height: 4),
          _buildDetailTag('Diet: ${data['dietType'] != '' ? data['dietType'] : 'N/A'}'),
        ],
        if (data['calories'] != null) ...[
          const SizedBox(height: 4),
          _buildDetailTag('Target: ${data['calories'] != '' ? data['calories'] : 'N/A'} kcal'),
        ],
      ],
    );
  }

  Widget _buildWorkoutPlanDetails(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        _buildDetailTag('Plan: ${data['planName'] != '' ? data['planName'] : 'N/A'}'),
        const SizedBox(height: 4),
        _buildDetailTag('Duration: ${data['duration'] != '' ? data['duration'] : 'N/A'}'),
        if (data['workoutType'] != null) ...[
          const SizedBox(height: 4),
          _buildDetailTag('Type: ${data['workoutType'] != '' ? data['workoutType'] : 'N/A'}'),
        ],
      ],
    );
  }

  Widget _buildAssessmentDetails(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailTag('Trainer: ${data['trainerName'] ?? 'N/A'}'),
        const SizedBox(height: 4),
        _buildDetailTag('Status: ${data['status']?.toString().capitalize() ?? 'Pending'}'),
        if (data['requestedDate'] != null) ...[
          const SizedBox(height: 4),
          _buildDetailTag('Requested: ${_formatDate(data['requestedDate'])}'),
        ],
      ],
    );
  }

  Widget _buildDetailTag(String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light ? myBlue20 : myGrey70,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: theme.brightness == Brightness.light ? myBlue60 : Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _handleMealPlanResponse(
    BuildContext context,
    NotificationModel notification,
    String userId,
    bool accepted,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      if (notification.data == null) {
        throw 'Missing notification data';
      }

      final senderId = notification.data!['senderId'];
      if (senderId == null) {
        throw 'Missing sender ID';
      }

      final planId = notification.relatedDocId;
      if (planId == null || planId.isEmpty) {
        throw 'Missing plan ID';
      }

      // Check for current plan if accepting
      final String newStatus;
      if (accepted) {
        final hasCurrentPlan = await _hasCurrentMealPlan(userId);
        newStatus =
            hasCurrentPlan ? fbClientConfirmedStatus : fbCurrentPlanStatus;
      } else {
        newStatus = fbClientRejectedStatus;
      }

      final batch = FirebaseFirestore.instance.batch();

      // Update notification
      final notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('allNotifications')
          .doc(notification.id);

      batch.update(notificationRef, {
        'read': true,
        'status': accepted ? fbClientConfirmedStatus : fbClientRejectedStatus,
        'responseDate': FieldValue.serverTimestamp(),
      });

      // Get the sender's role (trainer or dietitian)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();
      final senderRole = userDoc.data()?['role'] as String?;

      if (senderRole != 'trainer' && senderRole != 'dietitian') {
        throw 'Invalid sender role';
      }

      // Update client's meal plan
      final clientMealRef = FirebaseFirestore.instance
          .collection('meals')
          .doc('clients')
          .collection(userId)
          .doc(planId);

      // Update professional's meal plan
      final professionalMealRef = FirebaseFirestore.instance
          .collection('meals')
          .doc(senderRole == 'trainer' ? 'trainers' : 'dietitians')
          .collection(senderId)
          .doc(planId);

      final mealUpdate = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'responseDate': FieldValue.serverTimestamp(),
      };

      batch.update(clientMealRef, mealUpdate);
      batch.update(professionalMealRef, mealUpdate);

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        accepted ? CustomSnackBar.show(
                                    title: l10n.meal_plan,
                                    message: l10n.meal_plan_accepted,
                                    type: SnackBarType.success,
                                  )
        : CustomSnackBar.show(
                                    title: l10n.meal_plan,
                                    message: l10n.meal_plan_declined,
                                    type: SnackBarType.error,
                                  ),
        );
      }
    } catch (e) {
      debugPrint('Error in _handleMealPlanResponse: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
                                    title: l10n.meal_plan,
                                    message: l10n.unable_to_process_your_request(e.toString()),
                                    type: SnackBarType.error,
                                  ),
        );
      }
    }
  }

  Future<bool> _hasCurrentMealPlan(String clientId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('meals')
          .doc('clients')
          .collection(clientId)
          .where('status', isEqualTo: 'current')
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking current meal plan: $e');
      return false;
    }
  }

  Future<void> _handleWorkoutPlanResponse(
    BuildContext context,
    NotificationModel notification,
    String userId,
    bool accepted,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      if (notification.data == null) {
        throw 'Missing notification data';
      }

      final senderId = notification.data!['senderId'];
      if (senderId == null) {
        throw 'Missing sender ID';
      }

      final planId = notification.relatedDocId;
      if (planId == null || planId.isEmpty) {
        throw 'Missing plan ID';
      }

      // Check for current plan if accepting
      final String newStatus;
      if (accepted) {
        final hasCurrentPlan = await _hasCurrentWorkoutPlan(userId);
        newStatus =
            hasCurrentPlan ? fbClientConfirmedStatus : fbCurrentPlanStatus;
      } else {
        newStatus = fbClientRejectedStatus;
      }

      final batch = FirebaseFirestore.instance.batch();

      // Update notification
      final notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('allNotifications')
          .doc(notification.id);

      batch.update(notificationRef, {
        'read': true,
        'status': accepted ? fbClientConfirmedStatus : fbClientRejectedStatus,
        'responseDate': FieldValue.serverTimestamp(),
      });

      // Update client's workout plan
      final clientWorkoutRef = FirebaseFirestore.instance
          .collection('workouts')
          .doc('clients')
          .collection(userId)
          .doc(planId);

      // Update trainer's workout plan
      final trainerWorkoutRef = FirebaseFirestore.instance
          .collection('workouts')
          .doc('trainers')
          .collection(senderId)
          .doc(planId);

      final workoutUpdate = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'responseDate': FieldValue.serverTimestamp(),
      };

      batch.update(clientWorkoutRef, workoutUpdate);
      batch.update(trainerWorkoutRef, workoutUpdate);

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          accepted ? CustomSnackBar.show(
                                    title: l10n.workout_plan,
                                    message: l10n.workout_plan_accepted,
                                    type: SnackBarType.success,
                                  )
        : CustomSnackBar.show(
                                    title: l10n.workout_plan,
                                    message: l10n.workout_plan_declined,
                                    type: SnackBarType.error,
                                  ),
        );
      }
    } catch (e) {
      debugPrint('Error in _handleWorkoutPlanResponse: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
                                    title: l10n.workout_plan,
                                    message: l10n.unable_to_process_your_request(e.toString()),
                                    type: SnackBarType.error,
                                  ),
        );
      }
    }
  }

  Future<bool> _hasCurrentWorkoutPlan(String clientId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('workouts')
          .doc('clients')
          .collection(clientId)
          .where('status', isEqualTo: 'current')
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking current workout plan: $e');
      return false;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      final DateTime dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    return 'N/A';
  }
}
