import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/views/shared_side/group_message_page.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:naturafit/widgets/custom_user_profile_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:naturafit/views/shared_side/direct_message_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:naturafit/services/notification_service.dart';

// Events
abstract class ClientSessionDetailsEvent {}

class FetchSessionDetails extends ClientSessionDetailsEvent {
  final String sessionId;
  final String clientId;
  final bool isProfessionalAvailableSlot;
  final bool isGroupSession;
  final String? passedTrainerId;
  FetchSessionDetails(
      this.sessionId,
      this.clientId,
      this.isProfessionalAvailableSlot,
      this.isGroupSession,
      this.passedTrainerId);
}

// States
abstract class ClientSessionDetailsState {}

class SessionDetailsInitial extends ClientSessionDetailsState {}

class SessionDetailsLoading extends ClientSessionDetailsState {}

class SessionDetailsLoaded extends ClientSessionDetailsState {
  final Map<String, dynamic> sessionData;
  SessionDetailsLoaded(this.sessionData);
}

class SessionDetailsError extends ClientSessionDetailsState {
  final String message;
  SessionDetailsError(this.message);
}

// BLoC
class ClientSessionDetailsBloc
    extends Bloc<ClientSessionDetailsEvent, ClientSessionDetailsState> {
  final _firestore = FirebaseFirestore.instance;

  ClientSessionDetailsBloc() : super(SessionDetailsInitial()) {
    on<FetchSessionDetails>(_fetchSessionDetails);
  }

  Future<void> _fetchSessionDetails(
    FetchSessionDetails event,
    Emitter<ClientSessionDetailsState> emit,
  ) async {
    try {
      emit(SessionDetailsLoading());

      if (event.isProfessionalAvailableSlot || event.isGroupSession) {
        debugPrint('Fetching trainer session details');
        final trainerId =
            event.isGroupSession ? event.passedTrainerId : event.clientId;
        final snapshot = await _firestore
            .collection('trainer_sessions')
            .doc(trainerId)
            .collection('allTrainerSessions')
            .doc(event.sessionId)
            .get();

        if (!snapshot.exists) {
          emit(SessionDetailsError('Session not found'));
          return;
        }

        final sessionData = snapshot.data()!;
        emit(SessionDetailsLoaded(sessionData));
      } else {
        debugPrint('Fetching client session details');
        final snapshot = await _firestore
            .collection('client_sessions')
            .doc(event.clientId)
            .collection('allClientSessions')
            .doc(event.sessionId)
            .get();

        if (!snapshot.exists) {
          emit(SessionDetailsError('Session not found'));
          return;
        }

        final sessionData = snapshot.data()!;
        emit(SessionDetailsLoaded(sessionData));
      }
    } catch (e) {
      debugPrint('Error fetching session details: $e');
      emit(SessionDetailsError(e.toString()));
    }
  }
}

class ClientSessionDetailsPage extends StatelessWidget {
  final String sessionId;
  final String clientId;
  final bool isProfessionalAvailableSlot;
  final bool isGroupSession;
  final String? passedTrainerId;
  const ClientSessionDetailsPage({
    Key? key,
    required this.sessionId,
    required this.clientId,
    this.isProfessionalAvailableSlot = false,
    this.isGroupSession = false,
    this.passedTrainerId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ClientSessionDetailsBloc()
        ..add(FetchSessionDetails(sessionId, clientId,
            isProfessionalAvailableSlot, isGroupSession, passedTrainerId)),
      child: _ClientSessionDetailsContent(
          sessionId: sessionId,
          isProfessionalAvailableSlot: isProfessionalAvailableSlot,
          isGroupSession: isGroupSession,
          passedTrainerId: passedTrainerId),
    );
  }
}

class _ClientSessionDetailsContent extends StatelessWidget {
  final String sessionId;
  final bool isProfessionalAvailableSlot;
  final bool isGroupSession;
  final String? passedTrainerId;
  List<Map<String, dynamic>> appTypeParticipants = [];
  _ClientSessionDetailsContent({
    Key? key,
    required this.sessionId,
    required this.isProfessionalAvailableSlot,
    required this.isGroupSession,
    this.passedTrainerId,
  }) : super(key: key);

  Future<void> _loadAppTypeParticipants(
      Map<String, dynamic> sessionData) async {
    debugPrint('=================== LOADING PARTICIPANTS ===================');

    // Reset participants list
    appTypeParticipants = [];

    // Check if it's a group session and has clients data
    if (sessionData['isGroupSession'] != true ||
        sessionData['clients'] == null) {
      debugPrint('Not a group session or no clients found');
      return;
    }

    try {
      final clients = sessionData['clients'] as List<dynamic>;
      debugPrint('Total clients found: ${clients.length}');

      for (var client in clients) {
        if (client != null && client['connectionType'] == 'app') {
          appTypeParticipants.add({
            'userId': client['clientId'] ?? '',
            'name': client['clientUsername'] ?? 'Unknown Client',
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading participants: $e');
    }

    debugPrint(
        'Final app type participants count: ${appTypeParticipants.length}');
    debugPrint('=================== END LOADING ===================');
  }

  Future<void> _cancelSession(
      BuildContext context, Map<String, dynamic> sessionData) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      debugPrint('=================== CANCELING SESSION ===================');
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userData = userProvider.userData;
      final clientId = userData?['userId'];
      final isGroup = sessionData['isGroupSession'] == true;
      final clients = isGroup ? sessionData['clients'] : [];
      final isAvailableSlot = sessionData['scheduleType'] == 'available_slot';
      final _notificationService = NotificationService();

      final trainerId = sessionData['professionalId'];

      // Create a batch to ensure both updates happen together
      final batch = FirebaseFirestore.instance.batch();

      // Update client's session
      final clientSessionRef = FirebaseFirestore.instance
          .collection('client_sessions')
          .doc(clientId)
          .collection('allClientSessions')
          .doc(sessionId);

      batch.update(clientSessionRef, {'status': 'cancelled'});

      // Update trainer's session
      final trainerSessionRef = FirebaseFirestore.instance
          .collection('trainer_sessions')
          .doc(trainerId)
          .collection('allTrainerSessions')
          .doc(sessionId);

      if (!isGroup) {
        batch.update(trainerSessionRef, {'status': 'cancelled'});

        
      } else {
        final updatedClients = (clients as List)
            .where((client) => client['clientId'] != clientId)
            .toList();

            

        batch.update(
            trainerSessionRef, {'clients': updatedClients, 'status': 'group'});
      }

      // Send notification to trainer
        await _notificationService.createSessionCancelledNotificationByClient(
          trainerId: trainerId,
          clientId: clientId,
          clientData: userData!,
          sessionId: sessionId,
          sessionData: sessionData,
          isGroupSession: isGroup,
        );

      // Commit the batch
      await batch.commit();

      // Update threeUpcomingSessions if session exists in it
      final currentUpcomingSessions = List<Map<String, dynamic>>.from(
          userProvider.threeUpcomingSessions ?? []);

      final existingUpcomingIndex = currentUpcomingSessions.indexWhere(
          (session) => session['sessionId'] == sessionData['sessionId']);

      if (existingUpcomingIndex != -1) {
        // Only update the status to cancelled
        currentUpcomingSessions[existingUpcomingIndex] = {
          ...currentUpcomingSessions[existingUpcomingIndex],
          'status': 'cancelled',
        };
        userProvider.setThreeUpcomingSessions(currentUpcomingSessions);
      }

      // Update currentWeekSlots if session exists in it
      final currentWeekSlots =
          List<Map<String, dynamic>>.from(userProvider.currentWeekSlots ?? []);

      final existingWeekSlotIndex = currentWeekSlots
          .indexWhere((slot) => slot['sessionId'] == sessionData['sessionId']);

      if (existingWeekSlotIndex != -1) {
        // Only update the status
        currentWeekSlots[existingWeekSlotIndex] = {
          ...currentWeekSlots[existingWeekSlotIndex],
          'status': 'cancelled',
        };
        userProvider.setCurrentWeekSlots(currentWeekSlots);
      }

      // Show success message and refresh the page
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
                                    title: l10n.session,
                                    message: l10n.session_cancelled_successfully,
                                    type: SnackBarType.success,
                                  ),
        );

        // Refresh session details
        /*
        context.read<ClientSessionDetailsBloc>().add(
              FetchSessionDetails(sessionId, clientId,
                  isProfessionalAvailableSlot, isGroupSession, passedTrainerId),
            );
            */

        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error cancelling session: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.session,
            message: l10n.failed_to_cancel_session,
            type: SnackBarType.error,
          ),
        );
      }
    }
  }

  Future<void> _cancelRequest(
      BuildContext context, Map<String, dynamic> sessionData) async {
    final l10n = AppLocalizations.of(context)!;
    if (!context.mounted) return;
    
    try {
      debugPrint('=================== CANCELING REQUEST ===================');
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userData = userProvider.userData;
      final clientId = userData?['userId'];
      final trainerId = sessionData['professionalId'];
      final isGroup = sessionData['isGroupSession'] == true;

      // Create a batch to ensure both updates happen together
      final batch = FirebaseFirestore.instance.batch();

      // Update CLIENT's session
      final clientSessionRef = FirebaseFirestore.instance
          .collection('client_sessions')
          .doc(clientId)
          .collection('allClientSessions')
          .doc(sessionId);

      batch.update(clientSessionRef, {'status': 'withdrawn'});

      // Update TRAINER's session
      final trainerSessionRef = FirebaseFirestore.instance
          .collection('trainer_sessions')
          .doc(trainerId)
          .collection('allTrainerSessions')
          .doc(sessionId);

          final trainerSessionSnapshot = await trainerSessionRef.get();
          final trainerSessionData = trainerSessionSnapshot.data() ?? {};
          final requestedByClients = trainerSessionData['requestedByClients'] ?? [];
      // For group sessions, remove the client from requestedByClients array

        // Find and remove the current client from requestedByClients
        final updatedRequestedByClients = (requestedByClients as List)
            .where((client) => client['clientId'] != clientId)
            .toList();

        batch.update(trainerSessionRef, {
          'requestedByClients': updatedRequestedByClients,
          // Only change status to 'available' if no more requests
          'status': isGroup ? 'group' : updatedRequestedByClients.isEmpty ? 'available' : 'requested'
        });

      // Commit the batch
      await batch.commit();

      // Update threeUpcomingSessions if session exists in it
      final currentUpcomingSessions = List<Map<String, dynamic>>.from(
          userProvider.threeUpcomingSessions ?? []);

      final existingUpcomingIndex = currentUpcomingSessions.indexWhere(
          (session) => session['sessionId'] == sessionData['sessionId']);

      if (existingUpcomingIndex != -1) {
        // Only update the status to cancelled
        currentUpcomingSessions[existingUpcomingIndex] = {
          ...currentUpcomingSessions[existingUpcomingIndex],
          'status': 'withdrawn',
        };
        userProvider.setThreeUpcomingSessions(currentUpcomingSessions);
      }

      // Update currentWeekSlots if session exists in it
      final currentWeekSlots =
          List<Map<String, dynamic>>.from(userProvider.currentWeekSlots ?? []);

      final existingWeekSlotIndex = currentWeekSlots
          .indexWhere((slot) => slot['sessionId'] == sessionData['sessionId']);

      if (existingWeekSlotIndex != -1) {
        // Only update the status
        currentWeekSlots[existingWeekSlotIndex] = {
          ...currentWeekSlots[existingWeekSlotIndex],
          'status': 'withdrawn',
        };
        userProvider.setCurrentWeekSlots(currentWeekSlots);
      }

      // Show success message and refresh the page
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.session,
            message: l10n.request_withdrawn_successfully,
            type: SnackBarType.success,
          ),
        );
            
        Navigator.pop(context);
        // Refresh session details
        /*
        context.read<ClientSessionDetailsBloc>().add(
              FetchSessionDetails(sessionId, clientId,
                  isProfessionalAvailableSlot, isGroupSession, passedTrainerId),
            );
            */
            
      }
    } catch (e) {
      debugPrint('Error cancelling request: $e');
      rethrow; // Let the calling function handle the error
    }
  }

  Future<void> _bookSession(
      BuildContext context, Map<String, dynamic> sessionData) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userData = userProvider.userData;
      final clientId = userData?['userId'];
      final _notificationService = NotificationService();

      if (userData == null) {
        throw Exception('User not authenticated');
      }

      // Create a batch to handle multiple operations
      final batch = FirebaseFirestore.instance.batch();

      // 1. Update trainer's session document to add client to requestedByClients array
      final trainerSessionRef = FirebaseFirestore.instance
          .collection('trainer_sessions')
          .doc(sessionData['professionalId'])
          .collection('allTrainerSessions')
          .doc(sessionData['sessionId']);

      // Add client to requestedByClients array
      batch.update(trainerSessionRef, {
        'requestedByClients': FieldValue.arrayUnion([
          {
            'clientId': userData['userId'],
            'clientUsername': userData['username'],
            'clientFullname': userData['fullName'],
            'clientProfileImageUrl': userData['profileImageUrl'],
            'requestedAt': Timestamp.now(),
            'connectionType': 'app',
            'requestStatus': 'requested',
          }
        ]),
        'status': sessionData['isGroupSession'] == true ? 'group' : 'requested',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      

      // Send notification to trainer
      await _notificationService.createSessionRequestNotification(
        trainerId: sessionData['professionalId'],
        clientId: clientId!,
        sessionId: sessionData['sessionId'],
        sessionData: sessionData,
        clientData: userData,
        isGroupSession: sessionData['isGroupSession'] == true,
      );

      // 2. Create client's session document
      final clientSessionRef = FirebaseFirestore.instance
          .collection('client_sessions')
          .doc(userData['userId'])
          .collection('allClientSessions')
          .doc(sessionData['sessionId']);

      final clientSessionData = {
        'sessionId': sessionData['sessionId'],
        'clientId': userData['userId'],
        'clientUsername': userData['username'],
        'clientFullname': userData['fullName'],
        'clientProfileImageUrl': userData['profileImageUrl'],
        'professionalId': sessionData['professionalId'],
        'professionalUsername': sessionData['professionalUsername'],
        'professionalFullname': sessionData['professionalFullname'],
        'professionalProfileImageUrl':
            sessionData['professionalProfileImageUrl'],
        'professionalRole': sessionData['professionalRole'],
        'sessionDate': sessionData['sessionDate'],
        'time': sessionData['time'],
        'duration': sessionData['duration'],
        'mode': sessionData['mode'],
        'notes': sessionData['notes'],
        'sessionCategory': sessionData['sessionCategory'],
        'sessionType': sessionData['sessionType'],
        'scheduleType': sessionData['scheduleType'],
        'isRecurring': sessionData['isRecurring'],
        'recurringWeeks': sessionData['recurringWeeks'],
        'isGroupSession': sessionData['isGroupSession'] ?? false,
        'status': 'requested',
        'connectionType': 'app',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      batch.set(clientSessionRef, clientSessionData);

      // Commit the batch
      await batch.commit();

      // 1. Update threeUpcomingSessions
      final sessionToAdd = {
        ...clientSessionData,
        'status': 'requested',
        'sessionDate': sessionData['sessionDate'],
      };

      // Handle threeUpcomingSessions update
      final currentUpcomingSessions = List<Map<String, dynamic>>.from(
          userProvider.threeUpcomingSessions ?? []);

      final existingUpcomingIndex = currentUpcomingSessions.indexWhere(
          (session) => session['sessionId'] == sessionData['sessionId']);

      if (existingUpcomingIndex != -1) {
        currentUpcomingSessions[existingUpcomingIndex] = sessionToAdd;
      } else {
        currentUpcomingSessions.add(sessionToAdd);
      }

      // Sort and limit upcoming sessions
      currentUpcomingSessions.sort((a, b) {
        final aDate = (a['sessionDate'] as Timestamp).toDate();
        final bDate = (b['sessionDate'] as Timestamp).toDate();
        return aDate.compareTo(bDate);
      });

      final updatedUpcomingSessions = currentUpcomingSessions.length > 3
          ? currentUpcomingSessions.sublist(0, 3)
          : currentUpcomingSessions;

      // Update UserProvider's threeUpcomingSessions
      userProvider.setThreeUpcomingSessions(updatedUpcomingSessions);

      // 2. Update currentWeekSlots
      final currentWeekSlots =
          List<Map<String, dynamic>>.from(userProvider.currentWeekSlots ?? []);

      final existingWeekSlotIndex = currentWeekSlots
          .indexWhere((slot) => slot['sessionId'] == sessionData['sessionId']);

      if (existingWeekSlotIndex != -1) {
        // Update existing slot
        currentWeekSlots[existingWeekSlotIndex] = {
          ...currentWeekSlots[existingWeekSlotIndex],
          'status': 'requested',
        };
      } else {
        // Add new slot
        currentWeekSlots.add({
          ...sessionData,
          'status':
              sessionData['isGroupSession'] == true ? 'group' : 'requested',
        });
      }

      // Update UserProvider's currentWeekSlots
      userProvider.setCurrentWeekSlots(currentWeekSlots);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.session,
            message: l10n.session_request_sent_successfully,
            type: SnackBarType.success,
          ),
        );
        
        /*
        context.read<ClientSessionDetailsBloc>().add(
              FetchSessionDetails(sessionId, clientId,
                  isProfessionalAvailableSlot, isGroupSession, passedTrainerId),
            );
            */
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error booking session: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.session,
            message: l10n.failed_to_book_session,
            type: SnackBarType.error,
          ),
        );
      }
    }
  }

  Widget _buildStatusBadge(Map<String, dynamic> sessionData) {
    if (sessionData['isGroupSession'] == true) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: myPurple60,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'GROUP',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    Color backgroundColor;
    String displayText;

    switch (sessionData['status'].toString().toLowerCase()) {
      case 'confirmed':
      case 'booked':
        backgroundColor = myGreen50;
        displayText = 'CONFIRMED';
        break;
      case 'pending':
        backgroundColor = myYellow50;
        displayText = 'PENDING';
        break;
      default:
        backgroundColor = myGrey40;
        displayText = sessionData['status'].toString().toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayText,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
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
                color: theme.brightness == Brightness.light ? Colors.grey[600] : Colors.grey[400],
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w500,
                color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  TimeOfDay _parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeByPreference(String time24h, String timeFormat) {
    final timeOfDay = _parseTimeString(time24h);
    if (timeFormat == '24-hour') {
      return time24h; // Already in 24h format
    } else {
      // Convert to 12h format with AM/PM
      final hour = timeOfDay.hourOfPeriod;
      final minute = timeOfDay.minute.toString().padLeft(2, '0');
      final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
      return '${hour == 0 ? 12 : hour}:$minute $period';
    }
  }

  Widget _buildSessionInfoCard(
      BuildContext context, Map<String, dynamic> sessionData) {
    final theme = Theme.of(context);
    final sessionDate = (sessionData['sessionDate'] as Timestamp).toDate();
    final isGroup = sessionData['isGroupSession'] == true;
    final userData = Provider.of<UserProvider>(context, listen: false);
    final dateFormat = userData.userData?['dateFormat'] ?? 'MM/dd/yyyy';
    final timeFormat = userData.userData?['timeFormat'] ?? '12-hour';
    final formattedDate = DateFormat(dateFormat).format(sessionDate);
    final displayTime = _formatTimeByPreference(sessionData['time'], timeFormat);
    final l10n = AppLocalizations.of(context)!;
    debugPrint('userDataUserId: ${userData.userData?['userId']}');
    debugPrint('sessionDataaa: ${sessionData['status']}');

    bool isRequested = sessionData.containsKey('requestedByClients') &&
        ((sessionData['requestedByClients'] as List?)?.any((client) =>
                client['clientId'] == userData.userData?['userId']) ==
            true);


            // Get user's time format preference
    final is24Hour = userData.userData?['timeFormat'] == '24-hour';
    
    // Format time based on preference
    final timeFormatToPass = is24Hour ? 'HH:mm' : 'h:mm a';
    final formattedTime = DateFormat(timeFormatToPass).format(sessionDate);

    return Column(
      children: [
        // Main Session Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                        ),
                      ),
                      Text(
                        '${sessionData['duration']} ${l10n.minutes_session_details}',
                        style: GoogleFonts.plusJakartaSans(
                          color: theme.brightness == Brightness.light ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ),
                      if (isGroup &&
                          sessionData['status'] != 'cancelled' &&
                          sessionData['status'] != 'withdrawn' &&
                          !isRequested) ...[
                        const SizedBox(height: 8),
                        _buildSessionTypeInfo(context, sessionData),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getSessionStatusColor(
                          isGroup, sessionData['status'])['backgroundColor'],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isGroup && sessionData['status'] != 'cancelled'
                          ? l10n.group
                          : sessionData['status'] == 'rejected'
                              ? l10n.declined
                              : (sessionData['status'] ?? 'PENDING')
                                  .toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: _getSessionStatusColor(
                            isGroup, sessionData['status'])['textColor'],
                        fontWeight: FontWeight.w500,
                        //letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              _buildInfoRow(context, l10n.date, '${_getLocalizedMonthName(context, sessionDate.month)} ${sessionDate.day}, ${sessionDate.year}', Icons.calendar_today),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: myBlue60.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.access_time, color: myBlue60, size: 20),
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
                  context,
                  l10n.mode,
                  sessionData['mode']?.toUpperCase() ?? '',
                  sessionData['mode'] == 'virtual'
                      ? Icons.videocam
                      : Icons.person),
              if (sessionData['notes']?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                _buildInfoRow(context, l10n.notes, sessionData['notes'], Icons.note),
              ],
            ],
          ),
        ),

        // Trainer Info Card
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
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
                l10n.trainer,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CustomUserProfileImage(
                    imageUrl: sessionData['professionalProfileImageUrl'],
                    name: sessionData['professionalFullname'] ??
                        sessionData['professionalUsername'],
                    size: 48,
                    borderRadius: 12,
                    backgroundColor: theme.brightness == Brightness.light ? myGrey30 : myGrey70,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sessionData['professionalFullname']
                                      ?.toString()
                                      .isNotEmpty ==
                                  true
                              ? sessionData['professionalFullname']
                              : sessionData['professionalUsername'] ??
                                  'Unknown Trainer',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          l10n.trainer,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: theme.brightness == Brightness.light ? Colors.grey[600] : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (sessionData['professionalId'] !=
                      userData.userData?['linkedTrainerId'])
                    IconButton(
                      onPressed: () async {
                        final currentUserId =
                            FirebaseAuth.instance.currentUser!.uid;
                        final trainerId = sessionData['professionalId'];

                        // Try to find existing chat
                        final existingChat = await FirebaseFirestore.instance
                            .collection('messages')
                            .doc(currentUserId)
                            .collection('last_messages')
                            .where('otherUserId', isEqualTo: trainerId)
                            .where('isGroup', isEqualTo: false)
                            .get();

                        if (existingChat.docs.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DirectMessagePage(
                                otherUserId: trainerId,
                                otherUserName:
                                    sessionData['professionalFullname'] ??
                                        'Unknown',
                                chatType: 'trainer',
                                otherUserProfileImageUrl: sessionData['professionalProfileImageUrl'],
                              ),
                            ),
                          );
                        } else {
                          await FirebaseFirestore.instance
                              .collection('messages')
                              .doc(currentUserId)
                              .collection('last_messages')
                              .doc(trainerId)
                              .set({
                            'otherUserId': trainerId,
                            'otherUserName':
                                sessionData['professionalFullname'],
                            'lastMessage': '',
                            'timestamp': FieldValue.serverTimestamp(),
                            'isGroup': false,
                            'read': true,
                          });

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DirectMessagePage(
                                otherUserId: trainerId,
                                otherUserName:
                                    sessionData['professionalFullname'] ??
                                        'Unknown',
                                chatType: 'trainer',
                                otherUserProfileImageUrl: sessionData['professionalProfileImageUrl'],
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
                ],
              ),
            ],
          ),
        ),

        // Group Participants Card (if group session)
        if (isGroup) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
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
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                if ((sessionData['clients'] as List?)?.any((client) =>
                        client['clientId'] == userData.userData?['userId']) ??
                    false)
                  _buildParticipantsList(context, sessionData)
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'In order to see the participants, you need to participate in the session.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
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

  Widget _buildSessionTypeInfo(
      BuildContext context, Map<String, dynamic> sessionData) {
    final l10n = AppLocalizations.of(context)!;
    final trainerId = sessionData['professionalId'];
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userData?['userId'] ?? '';
    bool amITheTrainer = userId == trainerId;
    int participantsLengthForGroupMessage = amITheTrainer
        ? (appTypeParticipants.length - 1)
        : (appTypeParticipants.length - 1 + 1);

    debugPrint('Building session type info');
    return FutureBuilder(
      future: _loadAppTypeParticipants(sessionData),
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
          onTap: () => participantsLengthForGroupMessage >= 2 &&
                  participantsLengthForGroupMessage <= 15
              ? _handleGroupMessageTap(context)
              : debugPrint('Group message tap not allowed'),
          child: Row(
            children: [
              Text(
                l10n.group_message,
                style: GoogleFonts.plusJakartaSans(
                  color: participantsLengthForGroupMessage >= 2 &&
                          participantsLengthForGroupMessage <= 15
                      ? myBlue60
                      : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.message_rounded,
                color: participantsLengthForGroupMessage >= 2 &&
                        participantsLengthForGroupMessage <= 15
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

  Map<String, Color> _getSessionStatusColor(bool isGroup, String? status) {
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
      case 'rejected':
      case 'withdrawn':
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
    final clients = sessionData['clients'] as List?;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userData?['userId'] ?? '';
    final l10n = AppLocalizations.of(context)!;

    if (clients == null || clients.isEmpty) {
      return Text(
        l10n.no_participants_yet,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      children: clients.map((client) {
        final displayName =
            client['clientFullname']?.toString().isNotEmpty == true
                ? client['clientFullname']
                : client['clientUsername'] ?? 'Unknown';
        final firstLetter = displayName[0].toUpperCase();
        final isCurrentUser = client['clientId'] == userId;
        final theme = Theme.of(context);
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: CustomUserProfileImage(
            imageUrl: client['clientProfileImageUrl'],
            name: client['clientFullName'] ?? client['clientUsername'],
            size: 48,
            borderRadius: 12,
            backgroundColor: theme.brightness == Brightness.light ? myGrey30 : myGrey70,
          ),
          title: Text(
            displayName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            client['connectionType']?.toUpperCase() ?? '',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (client['connectionType'] == 'app' &&
                  client['clientId'] != userId)
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
                          otherUserProfileImageUrl: client['clientProfileImageUrl'],
                          chatType: 'client',
                        ),
                      ),
                    );
                  },
                ),
              if (client['connectionType'] == 'app' && !isCurrentUser)
                const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(client['status']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  getLocalizedStatus(context, client['status']).toUpperCase(),
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

  getLocalizedStatus(BuildContext context, String? status) {
    final l10n = AppLocalizations.of(context)!;
    if (status == 'confirmed') {
      return l10n.status_confirmed;
    } else if (status == 'active') {
      return l10n.status_active;
    } else if (status == 'booked') {
      return l10n.status_booked;
    } else if (status == 'pending') {
      return l10n.status_pending;
    } else if (status == 'cancelled') {
      return l10n.status_cancelled;
    } else if (status == 'rejected') {
      return l10n.status_rejected;
    } else if (status == 'withdrawn') {
      return l10n.status_withdrawn;
    } else if (status == 'requested') {
      return l10n.status_requested;
    } else if (status == 'recurring') {
      return l10n.status_recurring;
    } else {
      return l10n.status_pending;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
      case 'active':
      case 'booked':
        return myGreen50;
      case 'pending':
        return myYellow40;
      default:
        return myGrey40;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
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
        title: Text(
          l10n.session_details,
          style: GoogleFonts.plusJakartaSans(
            color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (isProfessionalAvailableSlot)
            BlocBuilder<ClientSessionDetailsBloc, ClientSessionDetailsState>(
              builder: (context, state) {
                if (state is SessionDetailsLoaded) {
                  final userData =
                      Provider.of<UserProvider>(context, listen: false);
                  bool isGroupSession =
                      state.sessionData['isGroupSession'] == true;

                  // Check if user is already a participant
                  bool isParticipant = isGroupSession
                      ? ((state.sessionData['clients'] as List?)?.any(
                              (client) =>
                                  client['clientId'] ==
                                  userData.userData?['userId']) ??
                          false)
                      : state.sessionData['clientId'] ==
                          userData.userData?['userId'];

                  DateTime myNow = DateTime.now();
                  DateTime mySessionDate =
                      (state.sessionData['sessionDate'] as Timestamp).toDate();
                  bool isPast = myNow.isAfter(mySessionDate);
                  // Don't show button if user is already a participant
                  if (isParticipant || isPast) return const SizedBox.shrink();

                  // Rest of the existing button code...
                  bool isRequested =
                      state.sessionData.containsKey('requestedByClients') &&
                          ((state.sessionData['requestedByClients'] as List?)
                                  ?.any((client) =>
                                      client['clientId'] ==
                                      userData.userData?['userId']) ==
                              true);

                  bool isCancelled = state.sessionData['status'] == 'cancelled';

                  bool isBookingEnabled = !isRequested;

                  if (isRequested && !isCancelled) {
                    return BlocBuilder<ClientSessionDetailsBloc,
                        ClientSessionDetailsState>(
                      builder: (context, state) {
                        if (state is SessionDetailsLoaded) {
                          final sessionData = state.sessionData;
                          final isSessionCancellable = sessionData['status']
                                      ?.toString()
                                      .toLowerCase() !=
                                  'cancelled' &&
                              sessionData['status']?.toString().toLowerCase() !=
                                  'completed' &&
                              sessionData['status']?.toString().toLowerCase() !=
                                  'rejected' &&
                              sessionData['status']?.toString().toLowerCase() !=
                                  'withdrawn';

                          if (!isSessionCancellable)
                            return const SizedBox.shrink();

                          return IconButton(
                            icon: Icon(
                              Icons.more_vert,
                              color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                            ),
                            onPressed: () {
                              myShowDialog(
                                  context,
                                  l10n.cancel_session,
                                  l10n.cancel_session_message,
                                  l10n.cancel,
                                  l10n.confirm,
                                  sessionData,
                                  false);
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    );
                  } else {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isBookingEnabled ? myBlue30 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: InkWell(
                        onTap: isBookingEnabled
                            ? () => _bookSession(context, state.sessionData)
                            : null,
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                isBookingEnabled ? myBlue60 : Colors.grey[400],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isRequested
                                ? l10n.requested
                                : (isGroupSession ? l10n.participate : l10n.book_now),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          if (!isProfessionalAvailableSlot)
            BlocBuilder<ClientSessionDetailsBloc, ClientSessionDetailsState>(
              builder: (context, state) {
                if (state is SessionDetailsLoaded) {
                  final sessionData = state.sessionData;
                  final isSessionCancellable =
                      sessionData['status']?.toString().toLowerCase() !=
                              'cancelled' &&
                          sessionData['status']?.toString().toLowerCase() !=
                              'completed' &&
                          sessionData['status']?.toString().toLowerCase() !=
                              'rejected' &&
                          sessionData['status']?.toString().toLowerCase() !=
                              'withdrawn';

                  final isClientRequested =
                      sessionData['status'] == 'requested';
                  debugPrint('Statusss: ${sessionData['status']}');

                  if (!isSessionCancellable) return const SizedBox.shrink();

                  return IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                    ),
                    onPressed: () {
                      myShowDialog(
                          context,
                          l10n.cancel_session,
                          l10n.cancel_session_message,
                          l10n.cancel,
                          l10n.confirm,
                          sessionData,
                          isClientRequested);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          const SizedBox(width: 8),
        ],
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: BlocBuilder<ClientSessionDetailsBloc, ClientSessionDetailsState>(
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
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSessionInfoCard(context, state.sessionData),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          l10n.create_group_chat,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: nameController,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: l10n.group_name,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final groupRef = await FirebaseFirestore.instance
                    .collection('group_chats')
                    .add({
                  'name': nameController.text,
                  'sessionId': sessionId,
                  'createdAt': FieldValue.serverTimestamp(),
                  'participants':
                      appTypeParticipants.map((p) => p['userId']).toList(),
                });

                Navigator.pop(context);
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
            },
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }

  void myShowDialog(
      BuildContext context,
      String title,
      String content,
      String cancelText,
      String confirmText,
      Map<String, dynamic> sessionData,
      bool isClientRequested) {
    final userData = Provider.of<UserProvider>(context, listen: false);
    bool isRequested = sessionData.containsKey('requestedByClients') &&
        ((sessionData['requestedByClients'] as List?)?.any(
            (client) => client['clientId'] == userData.userData?['userId']) ==
            true);
    bool isGroup = sessionData['isGroupSession'] == true;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.brightness == Brightness.light ? Colors.white : myGrey80,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: myRed50),
              title: Text(
                (isRequested || isClientRequested)
                    ? l10n.cancel_request
                    : isGroup
                        ? l10n.leave_group
                        : l10n.cancel_session,
                style: GoogleFonts.plusJakartaSans(
                  color: myRed50,
                  fontWeight: FontWeight.w500,
                ),
                
              ),
              onTap: () {
                Navigator.pop(bottomSheetContext); // Close bottom sheet
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(
                      (isRequested || isClientRequested)
                          ? l10n.cancel_request
                          : isGroup
                              ? l10n.leave_group
                              : l10n.cancel_session,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    content: Text(
                      content,
                      style: GoogleFonts.plusJakartaSans(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          cancelText,
                          style: GoogleFonts.plusJakartaSans(),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext); // Close dialog first
                          
                          // Perform the cancel operation
                          if (isRequested || isClientRequested) {
                            await _cancelRequest(context, sessionData);
                          } else {
                            await _cancelSession(context, sessionData);
                          }
                          
                          // Show success message using the original context
                          /*
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  (isRequested || isClientRequested)
                                      ? 'Request cancelled successfully'
                                      : 'Session cancelled successfully',
                                  style: GoogleFonts.plusJakartaSans(),
                                ),
                                backgroundColor: myGreen50,
                              ),
                            );
                          }
                          */
                        },
                        child: Text(
                          confirmText,
                          style: GoogleFonts.plusJakartaSans(
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
        ),
      ),
    );
  }
}
