import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/views/shared_side/direct_message_page.dart';
import 'package:naturafit/views/shared_side/group_message_page.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:naturafit/widgets/custom_user_profile_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:naturafit/views/trainer_side/schedule_session_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:naturafit/services/notification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:typed_data';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

// Events
abstract class SessionDetailsEvent {}

class FetchSessionDetails extends SessionDetailsEvent {
  final String sessionId;
  final String trainerId;
  FetchSessionDetails(this.sessionId, this.trainerId);
}

// States
abstract class SessionDetailsState {}

class SessionDetailsInitial extends SessionDetailsState {}

class SessionDetailsLoading extends SessionDetailsState {}

class SessionDetailsLoaded extends SessionDetailsState {
  final Map<String, dynamic> sessionData;
  SessionDetailsLoaded(this.sessionData);
}

class SessionDetailsError extends SessionDetailsState {
  final String message;
  SessionDetailsError(this.message);
}

// BLoC
class SessionDetailsBloc
    extends Bloc<SessionDetailsEvent, SessionDetailsState> {
  final _firestore = FirebaseFirestore.instance;

  SessionDetailsBloc() : super(SessionDetailsInitial()) {
    on<FetchSessionDetails>(_fetchSessionDetails);
  }

  Future<void> _fetchSessionDetails(
    FetchSessionDetails event,
    Emitter<SessionDetailsState> emit,
  ) async {
    try {
      emit(SessionDetailsLoading());

      final snapshot = await _firestore
          .collection('trainer_sessions')
          .doc(event.trainerId)
          .collection('allTrainerSessions')
          .doc(event.sessionId)
          .get();

      if (!snapshot.exists) {
        emit(SessionDetailsError('Session not found'));
        return;
      }

      final sessionData = snapshot.data()!;
      emit(SessionDetailsLoaded(sessionData));
    } catch (e) {
      debugPrint('Error fetching session details: $e');
      emit(SessionDetailsError(e.toString()));
    }
  }
}

class SessionDetailsPage extends StatelessWidget {
  final String sessionId;
  final String trainerId;

  const SessionDetailsPage({
    Key? key,
    required this.sessionId,
    required this.trainerId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SessionDetailsBloc()..add(FetchSessionDetails(sessionId, trainerId)),
      child: _SessionDetailsContent(sessionId: sessionId),
    );
  }
}

class _SessionDetailsContent extends StatelessWidget {
  final String sessionId;
  List<Map<String, dynamic>> appTypeParticipants = [];
  bool _hasBeenEdited = false;

  _SessionDetailsContent({
    Key? key,
    required this.sessionId,
  }) : super(key: key);

  Future<void> _loadAppTypeParticipants(
      BuildContext context, Map<String, dynamic> sessionData) async {
    debugPrint('=================== LOADING PARTICIPANTS ===================');

    // Reset participants list
    appTypeParticipants = [];

    // Check if it's a group session and has clients data
    if (sessionData['isGroupSession'] != true ||
        sessionData['clients'] == null) {
      debugPrint('Not a group session or no clients found');
      return;
    }

    final userData = Provider.of<UserProvider>(context, listen: false);
    final trainerClientId = userData.userData?['trainerClientId'];

    try {
      final clients = sessionData['clients'] as List<dynamic>;
      debugPrint('Total clients found: ${clients.length}');

      for (var client in clients) {
        if (client != null && client['connectionType'] == 'app') {
          if (client['clientId'] != trainerClientId) {
            appTypeParticipants.add({
              'userId': client['clientId'] ?? '',
              'name': client['clientUsername'] ?? 'Unknown Client',
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading participants: $e');
    }

    debugPrint(
        'Final app type participants count: ${appTypeParticipants.length}');
    debugPrint('=================== END LOADING ===================');
  }

  Widget _buildStatusBadge(
      BuildContext context, Map<String, dynamic> sessionData) {
    final l10n = AppLocalizations.of(context)!;
    // Check if it's a group session
    if (sessionData['isGroupSession'] == true) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: myPurple60, // Use purple for group sessions
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          l10n.group,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    // For non-group sessions, show the status
    Color backgroundColor;
    String displayText;

    final now = DateTime.now();
    final isPast =
        (sessionData['sessionDate'] as Timestamp).toDate().isBefore(now);

    switch (sessionData['status'].toString().toLowerCase()) {
      case fbClientConfirmedStatus:
        backgroundColor = isPast ? myGrey30 : myBlue50;
        displayText = l10n.status_confirmed;
        break;
      case 'booked':
        backgroundColor = isPast ? myGrey30 : myBlue50;
        displayText = l10n.status_booked;
        break;
      case fbCreatedStatusForNotAppUser:
        backgroundColor = isPast ? myGrey30 : myGreen50;
        displayText = l10n.status_active;
        break;
      case fbCreatedStatusForAppUser:
        backgroundColor = isPast ? myGrey30 : myYellow50;
        displayText = l10n.status_pending;
        break;
      case fbCreatedStatusForAvailableSlot:
        backgroundColor = isPast ? myGrey30 : myGreen50;
        displayText = l10n.status_available;
        break;
      default:
        backgroundColor = isPast ? myGrey30 : myGrey40;
        displayText = sessionData['status'].toString().toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayText,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSessionInfoCard(
      BuildContext context, Map<String, dynamic> sessionData) {
    final theme = Theme.of(context);
    final sessionDate = (sessionData['sessionDate'] as Timestamp).toDate();
    final isGroup = sessionData['scheduleType'] == 'group';
    final userData = Provider.of<UserProvider>(context, listen: false);
    final userId = userData.userData?['userId'];
    final isTrainer = sessionData['professionalId'] == userId;
    final l10n = AppLocalizations.of(context)!;

    // Get user's time format preference
    final is24Hour = userData.userData?['timeFormat'] == '24-hour';

    // Format time based on preference
    final timeFormat = is24Hour ? 'HH:mm' : 'h:mm a';
    final formattedTime = DateFormat(timeFormat).format(sessionDate);

    return Column(
      children: [
        // Main Session Info Card
        Container(
          padding: const EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sessionData['sessionCategory'] ?? '',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${sessionData['duration']} ${l10n.minutes_session_details}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: getStatusColor(
                          isGroup, sessionData['status'])['backgroundColor'],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isGroup && sessionData['status'] != 'cancelled'
                          ? l10n.group
                          : getLocalizedStatus(context, sessionData['status'])
                              .toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: getStatusColor(
                            isGroup, sessionData['status'])['textColor'],
                        fontWeight: FontWeight.w500,
                        //letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              _buildInfoRow(
                  l10n.date,
                  '${_getLocalizedMonthName(context, sessionDate.month)} ${sessionDate.day}, ${sessionDate.year}',
                  Icons.calendar_today),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: myBlue60.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.access_time,
                        color: myBlue60, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.time,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        formattedTime,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                  l10n.mode,
                  sessionData['mode']?.toUpperCase() ?? '',
                  sessionData['mode'] == 'virtual'
                      ? Icons.videocam
                      : Icons.person),
              if (sessionData['notes']?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                _buildInfoRow(l10n.notes, sessionData['notes'], Icons.note),
              ],
            ],
          ),
        ),

        // Client Info Card for Individual Sessions
        if (!isGroup && sessionData['clientId'] != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.client,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CustomUserProfileImage(
                      imageUrl: sessionData['clientProfileImageUrl'],
                      name: sessionData['clientFullName'] ??
                          sessionData['clientUsername'],
                      size: 48,
                      borderRadius: 12,
                      backgroundColor: theme.brightness == Brightness.light
                          ? myGrey30
                          : myGrey80,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      sessionData['clientFullname'] ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (sessionData['connectionType'] == 'app' &&
                        sessionData['clientId'] !=
                            userData.userData?['trainerClientId'])
                      IconButton(
                        onPressed: () async {
                          // Check if direct message exists
                          final currentUserId =
                              FirebaseAuth.instance.currentUser!.uid;
                          final clientId = sessionData['clientId'];

                          // Try to find existing chat
                          final existingChat = await FirebaseFirestore.instance
                              .collection('messages')
                              .doc(currentUserId)
                              .collection('last_messages')
                              .where('otherUserId', isEqualTo: clientId)
                              .where('isGroup', isEqualTo: false)
                              .get();

                          if (existingChat.docs.isNotEmpty) {
                            // Chat exists, navigate to it
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DirectMessagePage(
                                  otherUserId: clientId,
                                  otherUserName:
                                      sessionData['clientFullname'] ??
                                          'Unknown',
                                  chatType: 'client',
                                  otherUserProfileImageUrl:
                                      sessionData['clientProfileImageUrl'],
                                ),
                              ),
                            );
                          } else {
                            // Create new chat and navigate
                            await FirebaseFirestore.instance
                                .collection('messages')
                                .doc(currentUserId)
                                .collection('last_messages')
                                .doc(clientId)
                                .set({
                              'otherUserId': clientId,
                              'otherUserName': sessionData['clientFullname'],
                              'lastMessage': '',
                              'timestamp': FieldValue.serverTimestamp(),
                              'isGroup': false,
                              'read': true,
                            });

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DirectMessagePage(
                                  otherUserId: clientId,
                                  otherUserName:
                                      sessionData['clientFullname'] ??
                                          'Unknown',
                                  chatType: 'client',
                                  otherUserProfileImageUrl:
                                      sessionData['clientProfileImageUrl'],
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.message_rounded,
                          color: myBlue60,
                          size: 20,
                        ),
                      ),
                    const Spacer(),
                    _buildStatusBadge(context, sessionData),
                  ],
                ),
              ],
            ),
          ),
        ],

        if (isGroup &&
            sessionData['clientId'] == null &&
            sessionData['requestedByClients'] != null &&
            sessionData['requestedByClients'].isNotEmpty &&
            isTrainer) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.requests_to_join,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ...((sessionData['requestedByClients'] as List<dynamic>?) ?? [])
                    .map((client) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      //border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CustomUserProfileImage(
                          imageUrl: client['clientProfileImageUrl'],
                          name: client['clientFullName'] ??
                              client['clientUsername'] ??
                              'Unknown',
                          size: 48,
                          borderRadius: 12,
                          backgroundColor: theme.brightness == Brightness.light
                              ? myGrey30
                              : myGrey80,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                client['clientFullName'] ??
                                    client['clientUsername'] ??
                                    'Unknown',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (client['requestNote']?.isNotEmpty == true)
                                Text(
                                  client['requestNote'],
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 36,
                              width: 36,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                style: IconButton.styleFrom(
                                  backgroundColor: myGreen50.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  _handleGroupRequestAccept(
                                      context, sessionData, client);
                                },
                                icon: const Icon(
                                  Icons.check,
                                  color: myGreen50,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 36,
                              width: 36,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                style: IconButton.styleFrom(
                                  backgroundColor: myRed50.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  _handleGroupRequestDecline(
                                      context, sessionData, client);
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: myRed50,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],

        // Group Participants Card
        if (isGroup) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.group_participants} (${(sessionData['clients'] as List?)?.length ?? 0})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildParticipantsList(context, sessionData),
              ],
            ),
          ),
        ],

        if (!isGroup &&
            sessionData['clientId'] == null &&
            sessionData['requestedByClients'] != null &&
            sessionData['requestedByClients'].isNotEmpty &&
            isTrainer) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.session_requests,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ...((sessionData['requestedByClients'] as List<dynamic>?) ?? [])
                    .map((client) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      //border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CustomUserProfileImage(
                          imageUrl: client['clientProfileImageUrl'],
                          name: client['clientFullName'] ??
                              client['clientUsername'],
                          size: 48,
                          borderRadius: 12,
                          backgroundColor: theme.brightness == Brightness.light
                              ? myGrey30
                              : myGrey80,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                client['clientFullName'] ??
                                    client['clientUsername'] ??
                                    'Unknown',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (client['requestNote']?.isNotEmpty == true)
                                Text(
                                  client['requestNote'],
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 36,
                              width: 36,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                style: IconButton.styleFrom(
                                  backgroundColor: myGreen50.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  _handleIndividualRequestAccept(
                                      context, sessionData, client);
                                },
                                icon: const Icon(
                                  Icons.check,
                                  color: myGreen50,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 36,
                              width: 36,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                style: IconButton.styleFrom(
                                  backgroundColor: myRed50.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  _handleIndividualRequestDecline(
                                      context, sessionData, client);
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: myRed50,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String getLocalizedStatus(BuildContext context, String? status) {
    final l10n = AppLocalizations.of(context)!;

    switch (status?.toLowerCase()) {
      case fbClientConfirmedStatus:
      case fbCreatedStatusForNotAppUser:
        return l10n.status_confirmed;
      case fbCreatedStatusForAvailableSlot:
        return l10n.status_available;
      case fbCreatedStatusForAppUser:
        return l10n.status_pending;
      case fbCancelledStatus:
        return l10n.status_cancelled;
      case 'requested':
        return l10n.status_requested;
      case 'booked':
        return l10n.status_booked;
      case 'manual':
        return l10n.status_manual;
      case 'active':
      case 'typed':
        return l10n.status_active;
      default:
        return l10n.status_pending;
    }
  }

  String _getLocalizedMonthName(BuildContext context, int month) {
    final l10n = AppLocalizations.of(context)!;
    switch (month) {
      case 1:
        return l10n.january;
      case 2:
        return l10n.february;
      case 3:
        return l10n.march;
      case 4:
        return l10n.april;
      case 5:
        return l10n.may;
      case 6:
        return l10n.june;
      case 7:
        return l10n.july;
      case 8:
        return l10n.august;
      case 9:
        return l10n.september;
      case 10:
        return l10n.october;
      case 11:
        return l10n.november;
      case 12:
        return l10n.december;
      default:
        return '';
    }
  }

  Map<String, Color> getStatusColor(bool isGroup, String? status) {
    if (isGroup && status != 'cancelled') {
      return {
        'backgroundColor': myPurple60,
        'textColor': Colors.white,
      };
    }

    switch (status?.toLowerCase()) {
      case fbClientConfirmedStatus:
      case fbCreatedStatusForNotAppUser:
        return {
          'backgroundColor': myBlue50,
          'textColor': Colors.white,
        };
      case fbCreatedStatusForAvailableSlot:
        return {
          'backgroundColor': myGreen50,
          'textColor': Colors.white,
        };
      case fbCreatedStatusForAppUser:
        return {
          'backgroundColor': myYellow50,
          'textColor': Colors.white,
        };
      case fbCancelledStatus:
        return {
          'backgroundColor': myRed50,
          'textColor': Colors.white,
        };
      case 'requested':
        return {
          'backgroundColor': myRed40,
          'textColor': Colors.white,
        };
      case 'booked':
        return {
          'backgroundColor': myBlue50,
          'textColor': Colors.white,
        };
      default:
        return {
          'backgroundColor': myYellow50,
          'textColor': Colors.white,
        };
    }
  }

  Widget _buildParticipantsList(
      BuildContext context, Map<String, dynamic> sessionData) {
    final userData = Provider.of<UserProvider>(context, listen: false);
    final trainerClientId = userData.userData?['trainerClientId'];
    final clients = sessionData['clients'] as List?;
    final isPast = (sessionData['sessionDate'] as Timestamp)
        .toDate()
        .isBefore(DateTime.now());
    if (clients == null || clients.isEmpty) {
      return Text(
        'No participants yet',
        style: GoogleFonts.plusJakartaSans(
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      children: clients.map((client) {
        // Use fullname if available, otherwise use username
        final displayName =
            client['clientFullname']?.toString().isNotEmpty == true
                ? client['clientFullname']
                : client['clientUsername'] ?? 'Unknown';

        // Get first letter for avatar
        final firstLetter = displayName[0].toUpperCase();
        final theme = Theme.of(context);
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: CustomUserProfileImage(
            imageUrl: client['clientProfileImageUrl'],
            name: client['clientFullName'] ?? client['clientUsername'],
            size: 48,
            borderRadius: 12,
            backgroundColor:
                theme.brightness == Brightness.light ? myGrey30 : myGrey80,
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    client['connectionType']?.toUpperCase() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              if (client['connectionType'] == 'app' &&
                  client['clientId'] != trainerClientId)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.message_rounded,
                    color: myBlue60,
                    size: 18,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DirectMessagePage(
                          otherUserId: client['clientId'],
                          otherUserName: displayName,
                          otherUserProfileImageUrl:
                              client['clientProfileImageUrl'],
                          chatType: 'client',
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              //const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: sessionData['status'] == 'cancelled'
                      ? myGrey30
                      : _getStatusColor(client['status']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  getLocalizedStatus(context, client['status']),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
      case 'active':
        return myGreen50;
      case 'pending':
        return myYellow40;
      case 'booked':
        return myBlue50;
      default:
        return myGrey40;
    }
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: myBlue60.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: myBlue60, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleGroupMessageTap(BuildContext context) async {
    debugPrint('Handling group message tap');
    final groupChat = await FirebaseFirestore.instance
        .collection('group_chats')
        .where('sessionId', isEqualTo: sessionId)
        .limit(1)
        .get();

    if (groupChat.docs.isEmpty) {
      // Show dialog to create new group
      _showCreateGroupDialog(context);
    } else {
      // Navigate to existing group chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupMessagePage(
            groupId: groupChat.docs.first.id,
            sessionId: sessionId,
          ),
        ),
      );
    }
  }

  void _showCreateGroupDialog(BuildContext context) {
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    String? selectedImagePath;
    String? selectedImageUrl;
    Uint8List? selectedImageBytes;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: theme.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.create_group_chat,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Group Image Picker
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final ImagePicker picker = ImagePicker();
                          try {
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 512,
                              maxHeight: 512,
                            );

                            if (image != null) {
                              if (kIsWeb) {
                                // Handle web platform
                                final reader = html.FileReader();
                                reader.readAsDataUrl(html.File(
                                    [await image.readAsBytes()], image.name));
                                reader.onLoad.listen((event) {
                                  setState(() {
                                    selectedImagePath = reader.result as String;
                                    selectedImageBytes = base64Decode(
                                        selectedImagePath!.split(',').last);
                                  });
                                });
                              } else {
                                // Handle mobile platforms
                                final File imageFile = File(image.path);
                                setState(() => selectedImagePath = imageFile.path);
                              }
                            }
                          } catch (e) {
                            debugPrint('Error picking image: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                CustomSnackBar.show(
                                  title: l10n.error,
                                  message: e.toString(),
                                  type: SnackBarType.error,
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.light
                                ? myGrey30
                                : myGrey80,
                            borderRadius: BorderRadius.circular(20),
                            image: selectedImagePath != null
                                ? DecorationImage(
                                    image: kIsWeb
                                        ? NetworkImage(selectedImagePath!)
                                        : FileImage(File(selectedImagePath!))
                                            as ImageProvider,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                  )
                                : null,
                          ),
                          child: selectedImagePath == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 32,
                                      color: theme.brightness == Brightness.light
                                          ? myGrey60
                                          : myGrey40,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.add_photo,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: theme.brightness == Brightness.light
                                            ? myGrey60
                                            : myGrey40,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Group Name TextField
                    CustomFocusTextField(
                      controller: nameController,
                      label: l10n.group_name,
                      hintText: l10n.group_name,
                      prefixIcon: Icons.group,
                      isRequired: true,
                    ),
                    const SizedBox(height: 24),
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            l10n.cancel,
                            style: GoogleFonts.plusJakartaSans(
                              color: theme.brightness == Brightness.light
                                  ? myGrey60
                                  : myGrey40,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                CustomSnackBar.show(
                                  title: l10n.group_chat,
                                  message: l10n.please_enter_group_name,
                                  type: SnackBarType.warning,
                                ),
                              );
                              return;
                            }

                            // Show loading indicator
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => Center(
                                child: CircularProgressIndicator(
                                  color: theme.primaryColor,
                                ),
                              ),
                            );

                            try {
                              // Upload image if selected
                              if (selectedImagePath != null) {
                                final storageRef = FirebaseStorage.instance
                                    .ref()
                                    .child('group_chat_images')
                                    .child(
                                        '${DateTime.now().millisecondsSinceEpoch}.jpg');

                                if (kIsWeb) {
                                  // For Web: Upload as Uint8List (base64 data)
                                  await storageRef.putData(
                                    selectedImageBytes!,
                                    SettableMetadata(contentType: 'image/jpeg'),
                                  );
                                } else {
                                  // For Mobile: Upload from file
                                  await storageRef
                                      .putFile(File(selectedImagePath!));
                                }

                                selectedImageUrl =
                                    await storageRef.getDownloadURL();
                              }

                              // Create group chat
                              final groupRef = await FirebaseFirestore.instance
                                  .collection('group_chats')
                                  .add({
                                'name': nameController.text,
                                'sessionId': sessionId,
                                'imageUrl': selectedImageUrl,
                                'createdAt': FieldValue.serverTimestamp(),
                                'participants': appTypeParticipants
                                    .map((p) => p['userId'])
                                    .toList(),
                              });

                              if (context.mounted) {
                                Navigator.pop(context); // Close loading dialog
                                Navigator.pop(
                                    context); // Close create group dialog
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GroupMessagePage(
                                      groupId: groupRef.id,
                                      sessionId: sessionId,
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                debugPrint('Error creating group chat: $e');
                                Navigator.pop(context); // Close loading dialog
                                ScaffoldMessenger.of(context).showSnackBar(
                                  CustomSnackBar.show(
                                    title: l10n.group_chat,
                                    message: l10n.failed_to_create_group_chat,
                                    type: SnackBarType.error,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: myBlue60,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            l10n.create,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionTypeInfo(
      BuildContext context, Map<String, dynamic> sessionData) {
    final l10n = AppLocalizations.of(context)!;
    debugPrint('Building session type info');
    return FutureBuilder(
      future: _loadAppTypeParticipants(context, sessionData),
      builder: (context, snapshot) {
        debugPrint('FutureBuilder state: ${snapshot.connectionState}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('Still loading participants...');
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          debugPrint('Error in FutureBuilder: ${snapshot.error}');
          return const SizedBox.shrink();
        }

        debugPrint('Participant count for UI: ${appTypeParticipants.length}');
        return GestureDetector(
          onTap: () => appTypeParticipants.length >= 1 &&
                  appTypeParticipants.length <= 15
              ? _handleGroupMessageTap(context)
              : ScaffoldMessenger.of(context).showSnackBar(
                  CustomSnackBar.show(
                    title: l10n.group_message,
                    message: l10n
                        .at_least_two_participants_are_required_to_start_a_group_chat,
                    type: SnackBarType.warning,
                  ),
                ),
          child: Row(
            children: [
              Text(
                l10n.group_message,
                style: GoogleFonts.plusJakartaSans(
                  color: appTypeParticipants.length >= 2 &&
                          appTypeParticipants.length <= 15
                      ? myBlue60
                      : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.message_rounded,
                color: appTypeParticipants.length >= 2 &&
                        appTypeParticipants.length <= 15
                    ? myBlue60
                    : Colors.grey[600],
                size: 20,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionIndividualMessage(
      BuildContext context, Map<String, dynamic> sessionData) {
    final l10n = AppLocalizations.of(context)!;
    debugPrint('Building session type info');
    return FutureBuilder(
      future: _loadAppTypeParticipants(context, sessionData),
      builder: (context, snapshot) {
        debugPrint('FutureBuilder state: ${snapshot.connectionState}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('Still loading participants...');
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          debugPrint('Error in FutureBuilder: ${snapshot.error}');
          return const SizedBox.shrink();
        }

        debugPrint('Participant count for UI: ${appTypeParticipants.length}');
        final userData = Provider.of<UserProvider>(context, listen: false);
        return GestureDetector(
          onTap: () => (sessionData['connectionType'] == 'app' &&
                  sessionData['clientId'] !=
                      userData.userData?['trainerClientId'])
              ? () async {
                  // Check if direct message exists
                  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
                  final clientId = sessionData['clientId'];

                  // Try to find existing chat
                  final existingChat = await FirebaseFirestore.instance
                      .collection('messages')
                      .doc(currentUserId)
                      .collection('last_messages')
                      .where('otherUserId', isEqualTo: clientId)
                      .where('isGroup', isEqualTo: false)
                      .get();

                  if (existingChat.docs.isNotEmpty) {
                    // Chat exists, navigate to it
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DirectMessagePage(
                          otherUserId: clientId,
                          otherUserName:
                              sessionData['clientFullname'] ?? 'Unknown',
                          otherUserProfileImageUrl:
                              sessionData['clientProfileImageUrl'],
                          chatType: 'client',
                        ),
                      ),
                    );
                  } else {
                    // Create new chat and navigate
                    await FirebaseFirestore.instance
                        .collection('messages')
                        .doc(currentUserId)
                        .collection('last_messages')
                        .doc(clientId)
                        .set({
                      'otherUserId': clientId,
                      'otherUserName': sessionData['clientFullname'],
                      'lastMessage': '',
                      'timestamp': FieldValue.serverTimestamp(),
                      'isGroup': false,
                      'read': true,
                    });

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DirectMessagePage(
                          otherUserId: clientId,
                          otherUserName:
                              sessionData['clientFullname'] ?? 'Unknown',
                          otherUserProfileImageUrl:
                              sessionData['clientProfileImageUrl'],
                          chatType: 'client',
                        ),
                      ),
                    );
                  }
                }
              : ScaffoldMessenger.of(context).showSnackBar(
                  CustomSnackBar.show(
                    title: l10n.individual_message_tap_not_allowed,
                    message: l10n
                        .users_are_not_allowed_to_send_messages_to_themselves,
                    type: SnackBarType.warning,
                  ),
                ),
          child: Row(
            children: [
              Text(
                l10n.message,
                style: GoogleFonts.plusJakartaSans(
                  color: (sessionData['connectionType'] == 'app' &&
                          sessionData['clientId'] !=
                              userData.userData?['trainerClientId'])
                      ? myBlue60
                      : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.message_rounded,
                color: (sessionData['connectionType'] == 'app' &&
                        sessionData['clientId'] !=
                            userData.userData?['trainerClientId'])
                    ? myBlue60
                    : Colors.grey[600],
                size: 20,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _cancelSession(
      BuildContext context, Map<String, dynamic> sessionData) async {
    final l10n = AppLocalizations.of(context)!;
    bool success = false;
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userData = userProvider.userData;
      final trainerId = sessionData['professionalId'];
      final _notificationService = NotificationService();
      final batch = FirebaseFirestore.instance.batch();

      // Update trainer's session document
      final trainerSessionRef = FirebaseFirestore.instance
          .collection('trainer_sessions')
          .doc(trainerId)
          .collection('allTrainerSessions')
          .doc(sessionId);

      batch.update(trainerSessionRef, {
        'status': 'cancelled',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Handle clients who requested to join
      final requestedClients =
          sessionData['requestedByClients'] as List<dynamic>? ?? [];
      debugPrint(
          'Number of requested clients to update: ${requestedClients.length}');

      for (var client in requestedClients) {
        if (client['clientId'] != null && client['connectionType'] == 'app') {
          // Delete existing notifications for this session
          final existingNotifications = await FirebaseFirestore.instance
              .collection('notifications')
              .doc(client['clientId'])
              .collection('userNotifications')
              .where('sessionId', isEqualTo: sessionId)
              .get();

          for (var doc in existingNotifications.docs) {
            await doc.reference.delete();
          }

          final clientSessionRef = FirebaseFirestore.instance
              .collection('client_sessions')
              .doc(client['clientId'])
              .collection('allClientSessions')
              .doc(sessionId);

          batch.update(clientSessionRef, {
            'status': 'cancelled',
            'lastUpdated': FieldValue.serverTimestamp(),
          });

          // Send new cancellation notification
          await _notificationService.createSessionCancelledNotificationByTrainer(
            clientId: client['clientId'],
            trainerId: trainerId,
            sessionId: sessionId,
            sessionData: sessionData,
            trainerData: userData!,
            isGroupSession: sessionData['isGroupSession'] == true,
          );
        }
      }

      // Handle existing clients (for group sessions)
      if (sessionData['isGroupSession'] == true) {
        final clients = sessionData['clients'] as List<dynamic>? ?? [];
        debugPrint('Number of group clients to update: ${clients.length}');

        for (var client in clients) {
          if (client['clientId'] != null && client['connectionType'] == 'app') {
            // Delete existing notifications for this session
            final existingNotifications = await FirebaseFirestore.instance
                .collection('notifications')
                .doc(client['clientId'])
                .collection('userNotifications')
                .where('sessionId', isEqualTo: sessionId)
                .get();

            for (var doc in existingNotifications.docs) {
              await doc.reference.delete();
            }

            final clientSessionRef = FirebaseFirestore.instance
                .collection('client_sessions')
                .doc(client['clientId'])
                .collection('allClientSessions')
                .doc(sessionId);

            final clientSessionDoc = await clientSessionRef.get();
            if (clientSessionDoc.exists) {
              batch.update(clientSessionRef, {
                'status': 'cancelled',
                'lastUpdated': FieldValue.serverTimestamp(),
              });
            }

            // Send new cancellation notification
            await _notificationService.createSessionCancelledNotificationByTrainer(
              clientId: client['clientId'],
              trainerId: trainerId,
              sessionId: sessionId,
              sessionData: sessionData,
              trainerData: userData!,
              isGroupSession: sessionData['isGroupSession'] == true,
            );
          }
        }
      } else {
        debugPrint('Processing individual session cancellation...');
        if (sessionData['clientId'] != null &&
            sessionData['connectionType'] == 'app') {
          final clientId = sessionData['clientId'];
          debugPrint('Client ID: $clientId');

          // Delete existing notifications for this session
          final existingNotifications = await FirebaseFirestore.instance
              .collection('notifications')
              .doc(clientId)
              .collection('userNotifications')
              .where('sessionId', isEqualTo: sessionId)
              .get();

          for (var doc in existingNotifications.docs) {
            await doc.reference.delete();
          }

          final clientSessionRef = FirebaseFirestore.instance
              .collection('client_sessions')
              .doc(clientId)
              .collection('allClientSessions')
              .doc(sessionId);

          final clientSessionDoc = await clientSessionRef.get();
          if (clientSessionDoc.exists) {
            batch.update(clientSessionRef, {
              'status': 'cancelled',
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          }

          // Send new cancellation notification
          await _notificationService.createSessionCancelledNotificationByTrainer(
            clientId: clientId,
            trainerId: trainerId,
            sessionId: sessionId,
            sessionData: sessionData,
            trainerData: userData!,
            isGroupSession: sessionData['isGroupSession'] == true,
          );
        }
      }

      await batch.commit();
      debugPrint('Session cancellation completed successfully');
      success = true;
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.session,
            message: l10n.session_cancelled_successfully,
            type: SnackBarType.success,
          ),
        );

        context.read<SessionDetailsBloc>().add(
              FetchSessionDetails(sessionId, trainerId),
            );
      }

      return success;
    } catch (e) {
      debugPrint('Error cancelling session: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.session,
            message: l10n.failed_to_cancel_session_please_try_again,
            type: SnackBarType.error,
          ),
        );
      }
      return false;
    }
  }

  Future<bool> _deleteSession(
      BuildContext context, Map<String, dynamic> sessionData) async {
    final l10n = AppLocalizations.of(context)!;
    bool success = false;
    
    try {
      debugPrint('Starting session deletion...');
      final trainerId = sessionData['professionalId'];

      // Delete trainer's session document
      await FirebaseFirestore.instance
          .collection('trainer_sessions')
          .doc(trainerId)
          .collection('allTrainerSessions')
          .doc(sessionId)
          .delete();

      debugPrint('Session deleted successfully');
      success = true;

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.session,
            message: l10n.session_deleted_successfully,
            type: SnackBarType.success,
          ),
        );
      }
      
      return success;
    } catch (e) {
      debugPrint('Error deleting session: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.session,
            message: l10n.failed_to_delete_session_please_try_again,
            type: SnackBarType.error,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _handleGroupRequestAccept(BuildContext context,
      Map<String, dynamic> sessionData, Map<String, dynamic> requester) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userData = userProvider.userData;
      final trainerId = sessionData['professionalId'];
      final _notificationService = NotificationService();
      final batch = FirebaseFirestore.instance.batch();

      // Get trainer's session document reference
      final trainerSessionRef = FirebaseFirestore.instance
          .collection('trainer_sessions')
          .doc(trainerId)
          .collection('allTrainerSessions')
          .doc(sessionId);

      // Get current session data to update
      final sessionDoc = await trainerSessionRef.get();
      if (!sessionDoc.exists) {
        throw Exception('Session document not found');
      }

      final currentData = sessionDoc.data()!;

      // Add requester to clients list
      List<Map<String, dynamic>> clients =
          List.from(currentData['clients'] ?? []);
      clients.add({
        'clientId': requester['clientId'],
        'clientUsername': requester['clientUsername'],
        'clientFullname': requester['clientFullname'],
        'clientProfileImageUrl': requester['clientProfileImageUrl'],
        'connectionType': 'app',
        'status': 'booked'
      });

      // Remove requester from requestedByClients
      List<dynamic> requesters =
          List.from(currentData['requestedByClients'] ?? []);
      requesters.removeWhere((r) => r['clientId'] == requester['clientId']);

      // Update trainer's session document
      batch.update(trainerSessionRef, {
        'clients': clients,
        'requestedByClients': requesters,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update client's session document
      final clientSessionRef = FirebaseFirestore.instance
          .collection('client_sessions')
          .doc(requester['clientId'])
          .collection('allClientSessions')
          .doc(sessionId);

      batch.update(clientSessionRef, {
        'status': 'booked',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Send notification to the client
      await _notificationService.createSessionRequestResponseNotification(
        clientId: requester['clientId'],
        trainerId: trainerId,
        sessionId: sessionId,
        sessionData: sessionData,
        trainerData: userData!,
        isAccepted: true,
        isGroupSession: true,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.session,
            message: l10n.request_accepted_successfully,
            type: SnackBarType.success,
          ),
        );

        // Refresh session details
        context.read<SessionDetailsBloc>().add(
              FetchSessionDetails(sessionId, trainerId),
            );
      }
    } catch (e) {
      debugPrint('Error accepting request: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.session,
            message: l10n.failed_to_accept_request_please_try_again,
            type: SnackBarType.error,
          ),
        );
      }
    }
  }

  Future<void> _handleGroupRequestDecline(BuildContext context,
      Map<String, dynamic> sessionData, Map<String, dynamic> requester) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userData = userProvider.userData;
      final trainerId = sessionData['professionalId'];
      final _notificationService = NotificationService();
      final batch = FirebaseFirestore.instance.batch();

      // Get trainer's session document reference
      final trainerSessionRef = FirebaseFirestore.instance
          .collection('trainer_sessions')
          .doc(trainerId)
          .collection('allTrainerSessions')
          .doc(sessionId);

      // Get current session data to update
      final sessionDoc = await trainerSessionRef.get();
      if (!sessionDoc.exists) {
        throw Exception('Session document not found');
      }

      final currentData = sessionDoc.data()!;

      // Remove requester from requestedByClients
      List<dynamic> requesters =
          List.from(currentData['requestedByClients'] ?? []);
      requesters.removeWhere((r) => r['clientId'] == requester['clientId']);

      // Update trainer's session document
      batch.update(trainerSessionRef, {
        'requestedByClients': requesters,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update client's session document
      final clientSessionRef = FirebaseFirestore.instance
          .collection('client_sessions')
          .doc(requester['clientId'])
          .collection('allClientSessions')
          .doc(sessionId);

      batch.update(clientSessionRef, {
        'status': 'rejected',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Send notification to the client
      await _notificationService.createSessionRequestResponseNotification(
        clientId: requester['clientId'],
        trainerId: trainerId,
        sessionId: sessionId,
        sessionData: sessionData,
        trainerData: userData!,
        isAccepted: false,
        isGroupSession: true,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.session,
            message: l10n.request_declined_successfully,
            type: SnackBarType.success,
          ),
        );

        // Refresh session details
        context.read<SessionDetailsBloc>().add(
              FetchSessionDetails(sessionId, trainerId),
            );
      }
    } catch (e) {
      debugPrint('Error declining request: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.session,
            message: l10n.failed_to_decline_request_please_try_again,
            type: SnackBarType.error,
          ),
        );
      }
    }
  }

  Future<void> _handleIndividualRequestAccept(BuildContext context,
      Map<String, dynamic> sessionData, Map<String, dynamic> requester) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final trainerId = sessionData['professionalId'];
      final batch = FirebaseFirestore.instance.batch();

      // Get trainer's session document reference
      final trainerSessionRef = FirebaseFirestore.instance
          .collection('trainer_sessions')
          .doc(trainerId)
          .collection('allTrainerSessions')
          .doc(sessionId);

      // Update trainer's session document
      batch.update(trainerSessionRef, {
        'clientId': requester['clientId'],
        'clientUsername': requester['clientUsername'],
        'clientFullname': requester['clientFullname'],
        'clientProfileImageUrl': requester['clientProfileImageUrl'],
        'connectionType': 'app',
        'status': 'booked',
        'requestedByClients': [], // Clear all requests
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update accepted client's session document
      final acceptedClientSessionRef = FirebaseFirestore.instance
          .collection('client_sessions')
          .doc(requester['clientId'])
          .collection('allClientSessions')
          .doc(sessionId);

      batch.update(acceptedClientSessionRef, {
        'status': 'booked',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update all other requesters' session documents to 'rejected'
      final otherRequesters = (sessionData['requestedByClients']
                  as List<dynamic>? ??
              [])
          .where((r) => r['clientId'] != requester['clientId'])
          .where((r) => r['connectionType'] == 'app') // Only handle app users
          .where((r) => r['connectionType'] == 'manual');

      for (var otherRequester in otherRequesters) {
        final otherClientSessionRef = FirebaseFirestore.instance
            .collection('client_sessions')
            .doc(otherRequester['clientId'])
            .collection('allClientSessions')
            .doc(sessionId);

        batch.update(otherClientSessionRef, {
          'status': 'rejected',
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.session,
            message: l10n.request_accepted_successfully,
            type: SnackBarType.success,
          ),
        );

        context.read<SessionDetailsBloc>().add(
              FetchSessionDetails(sessionId, trainerId),
            );
      }
    } catch (e) {
      debugPrint('Error accepting individual request: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.session,
            message: l10n.failed_to_accept_request_please_try_again,
            type: SnackBarType.error,
          ),
        );
      }
    }
  }

  Future<void> _handleIndividualRequestDecline(BuildContext context,
      Map<String, dynamic> sessionData, Map<String, dynamic> requester) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final trainerId = sessionData['professionalId'];
      final batch = FirebaseFirestore.instance.batch();

      // Get trainer's session document reference
      final trainerSessionRef = FirebaseFirestore.instance
          .collection('trainer_sessions')
          .doc(trainerId)
          .collection('allTrainerSessions')
          .doc(sessionId);

      // Remove requester from requestedByClients
      List<dynamic> requesters =
          List.from(sessionData['requestedByClients'] ?? []);
      requesters.removeWhere((r) => r['clientId'] == requester['clientId']);

      // Update trainer's session document
      batch.update(trainerSessionRef, {
        'requestedByClients': requesters,
        'lastUpdated': FieldValue.serverTimestamp(),
        // If no requesters left, update status to available
        if (requesters.isEmpty) 'status': 'available',
      });

      // Update client's session document status to rejected
      final clientSessionRef = FirebaseFirestore.instance
          .collection('client_sessions')
          .doc(requester['clientId'])
          .collection('allClientSessions')
          .doc(sessionId);

      batch.update(clientSessionRef, {
        'status': 'rejected',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.session,
            message: l10n.request_declined_successfully,
            type: SnackBarType.success,
          ),
        );

        context.read<SessionDetailsBloc>().add(
              FetchSessionDetails(sessionId, trainerId),
            );
      }
    } catch (e) {
      debugPrint('Error declining individual request: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.session,
            message: l10n.failed_to_decline_request_please_try_again,
            type: SnackBarType.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final userId = context.read<UserProvider>().userData?['userId'];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.brightness == Brightness.light
                  ? Colors.black
                  : Colors.white,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.chevron_left,
              color: theme.brightness == Brightness.light
                  ? Colors.black
                  : Colors.white,
            ),
            onPressed: () {
              if (_hasBeenEdited) {
                Navigator.pop(context, {
                  'edited': true,
                  'sessionId': sessionId,
                });
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        title: Text(
          l10n.session_details,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          BlocBuilder<SessionDetailsBloc, SessionDetailsState>(
            builder: (context, state) {
              if (state is SessionDetailsLoaded) {
                final userId = context.read<UserProvider>().userData?['userId'];
                final isProfessional =
                    state.sessionData['professionalId'] == userId;

                if (isProfessional == true &&
                    state.sessionData['status'] != 'cancelled') {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: theme.brightness == Brightness.light
                              ? Colors.black
                              : Colors.white,
                        ),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor:
                                theme.brightness == Brightness.light
                                    ? Colors.white
                                    : myGrey80,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20)),
                            ),
                            builder: (context) => Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (state.sessionData['status'] !=
                                      'available') ...[
                                    ListTile(
                                      leading: const Icon(Icons.cancel_outlined,
                                          color: myRed50),
                                      title: Text(
                                        l10n.cancel_session,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: myRed50,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        showDialog(
                                          context: context,
                                          builder: (context) => Dialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(24),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    l10n.cancel_session,
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    l10n.are_you_sure_you_want_to_cancel_this_session,
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 16,
                                                      color: theme.brightness == Brightness.light 
                                                        ? myGrey60 
                                                        : myGrey40,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 24),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        style: TextButton.styleFrom(
                                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          l10n.no,
                                                          style: GoogleFonts.plusJakartaSans(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w500,
                                                            color: theme.brightness == Brightness.light 
                                                              ? myGrey60 
                                                              : myGrey40,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      ElevatedButton(
                                                        onPressed: () async {
                                                          // Get the navigator before any async operations
                                                          final navigator = Navigator.of(context);
                                                          
                                                          // Close the confirmation dialog
                                                          navigator.pop();
                                                          
                                                          final success = await _cancelSession(context, state.sessionData);
                                                          debugPrint('Success here1: $success');
                                                          
                                                          // Check if cancellation was successful
                                                          if (success) {
                                                            debugPrint('Success here2: $success');
                                                            // Pop back to previous screen with cancellation info
                                                            navigator.pop({
                                                              'cancelled': true,
                                                              'sessionId': sessionId,
                                                            });
                                                          }
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: myRed50,
                                                          foregroundColor: Colors.white,
                                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          l10n.yes,
                                                          style: GoogleFonts.plusJakartaSans(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                  if (state.sessionData['status'] ==
                                      'available') ...[
                                    ListTile(
                                      leading: const Icon(Icons.delete_outline,
                                          color: myRed50),
                                      title: Text(
                                        l10n.delete_session,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: myRed50,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.pop(
                                            context); // Close bottom sheet
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(
                                              l10n.delete_session,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            content: Text(
                                              l10n.delete_session_confirm,
                                              style:
                                                  GoogleFonts.plusJakartaSans(),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () async {
                                                  // Get the navigator before any async operations
                                                  final navigator = Navigator.of(context);
                                                  
                                                  // Close the confirmation dialog
                                                  navigator.pop();
                                                  
                                                  // Delete the session
                                                  final success = await _deleteSession(context, state.sessionData);
                                                  
                                                  debugPrint('Success: $success');
                                                  
                                                  // Check if deletion was successful
                                                  if (success) {
                                                    debugPrint('Deletion successful!!!!');
                                                    // Pop back to previous screen with deletion info
                                                    navigator.pop({
                                                      'deleted': true,
                                                      'sessionId': sessionId,
                                                      'sessionDate': state.sessionData['sessionDate'],
                                                    });
                                                  }
                                                },
                                                child: Text(
                                                  l10n.yes,
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    color: myRed50,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<SessionDetailsBloc, SessionDetailsState>(
        builder: (context, state) {
          if (state is SessionDetailsLoading) {
            return const Center(child: CircularProgressIndicator(color: myBlue60));
          }

          if (state is SessionDetailsError) {
            return Center(
              child: Text(
                l10n.error_loading_session(state.message),
                style: GoogleFonts.plusJakartaSans(color: myRed50),
              ),
            );
          }

          if (state is SessionDetailsLoaded) {
            return Column(
              children: [
                if (state.sessionData['status'] != 'cancelled' &&
                    state.sessionData['professionalId'] == userId)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (state.sessionData['isGroupSession'] == true) ...[
                        //const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child:
                              _buildSessionTypeInfo(context, state.sessionData),
                        ),
                      ],
                      if (state.sessionData['status'] != 'group') ...[
                        //const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: _buildSessionIndividualMessage(
                              context, state.sessionData),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final sessionData = state.sessionData;
                            final now = DateTime.now();
                            final isPast =
                                (sessionData['sessionDate'] as Timestamp)
                                    .toDate()
                                    .isBefore(now);
                            debugPrint(
                                'Session type: ${sessionData['isGroupSession']}');
                            Navigator.push<dynamic>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ScheduleSessionPage(
                                  initialSessionCategory:
                                      sessionData['sessionCategory'],
                                  isPast: isPast,
                                  isEditing: true,
                                  sessionId: sessionId,
                                  initialScheduleType:
                                      sessionData['isGroupSession'] == true
                                          ? 'group'
                                          : sessionData['clientId'] != null
                                              ? (sessionData[
                                                          'connectionType'] ==
                                                      'app'
                                                  ? 'existing_client'
                                                  : 'manual_client')
                                              : 'available_slot',
                                  initialSessionData: {
                                    ...sessionData,
                                    'scheduleType':
                                        sessionData['isGroupSession'] == true
                                            ? 'group'
                                            : sessionData['clientId'] != null
                                                ? (sessionData[
                                                            'connectionType'] ==
                                                        'app'
                                                    ? 'existing_client'
                                                    : 'manual_client')
                                                : 'available_slot',
                                  },
                                ),
                              ),
                            ).then((value) {
                              if (context.mounted) {
                                _hasBeenEdited = true;
                                context.read<SessionDetailsBloc>().add(
                                      FetchSessionDetails(sessionId, state.sessionData['professionalId']),
                                    );
                              }
                            });
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: Text(
                            l10n.edit,
                            style: GoogleFonts.plusJakartaSans(),
                          ),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: myBlue60,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSessionInfoCard(context, state.sessionData),
                    ],
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
