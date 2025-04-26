import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_select_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:naturafit/widgets/multiple_client_selection_sheet.dart';
import 'package:naturafit/widgets/custom_toggle_switch.dart';
import 'package:naturafit/widgets/horizontal_number_slider.dart';
import 'package:naturafit/widgets/custom_single_spinner.dart';
import 'package:naturafit/widgets/client_selection_sheet.dart';
import 'package:naturafit/widgets/custom_date_picker.dart';
import 'package:naturafit/widgets/custom_time_picker.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:naturafit/services/notification_service.dart';

// Events
abstract class ScheduleSessionEvent {}

class CreateSession extends ScheduleSessionEvent {
  final Map<String, dynamic> data;
  CreateSession({required this.data});
}

class CreateRecurringSessions extends ScheduleSessionEvent {
  final List<Map<String, dynamic>> data;
  CreateRecurringSessions({required this.data});
}

class UpdateSession extends ScheduleSessionEvent {
  final Map<String, dynamic> data;
  UpdateSession({required this.data});
}

// States
abstract class ScheduleSessionState {}

class ScheduleSessionInitial extends ScheduleSessionState {}

class ScheduleSessionLoading extends ScheduleSessionState {}

class ScheduleSessionSuccess extends ScheduleSessionState {
  final Map<String, dynamic>? sessionData;
  ScheduleSessionSuccess({this.sessionData});
}

class ScheduleSessionError extends ScheduleSessionState {
  final String message;
  ScheduleSessionError(this.message);
}

// BLoC
// In ScheduleSessionBloc
class ScheduleSessionBloc
    extends Bloc<ScheduleSessionEvent, ScheduleSessionState> {
  final _firestore = FirebaseFirestore.instance;
  final BuildContext context;
  final _notificationService = NotificationService();
  bool _isProcessing = false;

  ScheduleSessionBloc(this.context) : super(ScheduleSessionInitial()) {
    on<CreateSession>(_createSession);
    on<CreateRecurringSessions>(_createRecurringSessions);
    on<UpdateSession>(_updateSession);
  }

  Future<void> _createSession(
    CreateSession event,
    Emitter<ScheduleSessionState> emit,
  ) async {
    try {
      emit(ScheduleSessionLoading());

      final userProvider = context.read<UserProvider>();
      final userData = userProvider.userData;

      final data = event.data;
      // Validate required fields
      if (data['professionalId'] == null ||
          data['sessionDate'] == null ||
          data['time'] == null ||
          data['sessionCategory'] == null ||
          data['duration'] == null) {
        throw Exception(
            'Required fields are missing: Please fill all required fields');
      }

      // Generate session ID
      final String sessionId = _firestore
          .collection('trainer_sessions')
          .doc(data['professionalId'])
          .collection('allTrainerSessions')
          .doc()
          .id;

      final sessionData = {
        ...data,
        'sessionId': sessionId,
        'senderId': data['professionalId'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Create batch for atomic operations
      final batch = _firestore.batch();

      // Always create trainer session
      final trainerSessionRef = _firestore
          .collection('trainer_sessions')
          .doc(data['professionalId'])
          .collection('allTrainerSessions')
          .doc(sessionId);

      batch.set(trainerSessionRef, sessionData);

      // Handle different schedule types
      switch (data['scheduleType']) {
        case 'existing_client':
          if (data['connectionType'] == fbAppConnectionType) {
            final clientSessionRef = _firestore
                .collection('client_sessions')
                .doc(data['clientId'])
                .collection('allClientSessions')
                .doc(sessionId);

            batch.set(clientSessionRef, sessionData);
            
            if (data['clientId'] != userData?['trainerClientId']) {
              await _notificationService.createSessionNotification(
                clientId: data['clientId'],
                senderId: data['professionalId'],
                sessionId: sessionId,
                sessionData: sessionData,
                connectionType: data['connectionType'],
                isRecurring: false,
              );
            }
          }
          break;

        case 'manual_client':
          // Generate client ID for manual client
          final String clientId =
              'TYPED_${DateTime.now().millisecondsSinceEpoch}_${data['clientName'].toString().replaceAll(' ', '_')}';

          // Create manual client document
          final manualClientRef = _firestore
              .collection('clients')
              .doc(data['professionalId'])
              .collection('manualClients')
              .doc(clientId);

          batch.set(manualClientRef, {
            'clientId': clientId,
            'clientName': data['clientName'],
            'connectionType': fbTypedConnectionType,
            'createdAt': FieldValue.serverTimestamp(),
            'professionalId': data['professionalId'],
          });

          // Update session data with generated client ID
          sessionData['clientId'] = clientId;
          batch.set(trainerSessionRef, sessionData);
          break;

        case 'available_slot':
          // No additional operations needed for available slots
          break;

        case 'group':
          final clients = data['clients'] as List<dynamic>;
          for (final client in clients) {
            if (client['connectionType'] == fbTypedConnectionType &&
                client['isNewClient'] == true) {
              // Generate ID for new manual client
              final String newClientId =
                  'TYPED_${DateTime.now().millisecondsSinceEpoch}_${client['clientName'].toString().replaceAll(' ', '_')}';

              // Create manual client document
              final manualClientRef = _firestore
                  .collection('clients')
                  .doc(data['professionalId'])
                  .collection('manualClients')
                  .doc(newClientId);

              batch.set(manualClientRef, {
                'clientId': newClientId,
                'clientName': client['clientName'],
                'connectionType': fbTypedConnectionType,
                'createdAt': FieldValue.serverTimestamp(),
                'professionalId': data['professionalId'],
              });

              // Update client ID in the session data
              client['clientId'] = newClientId;
            }

            if (client['connectionType'] == fbAppConnectionType) {
              final clientSessionRef = _firestore
                  .collection('client_sessions')
                  .doc(client['clientId'])
                  .collection('allClientSessions')
                  .doc(sessionId);

              batch.set(clientSessionRef, sessionData);

              if (client['clientId'] != userData?['trainerClientId']) {
                await _notificationService.createSessionNotification(
                  clientId: client['clientId'],
                  senderId: data['professionalId'],
                  sessionId: sessionId,
                  sessionData: sessionData,
                  connectionType: client['connectionType'],
                  isGroupSession: true,
                  isRecurring: false,
                );
              }
            }
          }
          break;
      }

      if (data['scheduleType'] != 'available_slot') {
        userProvider.addThreeUpcomingSessions(sessionData);
      }

      if (data['scheduleType'] == 'available_slot' ||
          data['scheduleType'] == 'group') {
        userProvider.addAvailableFutureSlots(sessionData);
      }

      await batch.commit();
      emit(ScheduleSessionSuccess(sessionData: sessionData));
      
    } catch (e) {
      debugPrint('Error creating session: $e');
      emit(ScheduleSessionError(e.toString()));
    }
  }

  Future<void> _createRecurringSessions(
    CreateRecurringSessions event,
    Emitter<ScheduleSessionState> emit,
  ) async {
    try {
      emit(ScheduleSessionLoading());

      final batch = _firestore.batch();

      for (final sessionData in event.data) {
        final String sessionId = _firestore
            .collection('trainer_sessions')
            .doc(sessionData['professionalId'])
            .collection('allTrainerSessions')
            .doc()
            .id;

        final finalSessionData = {
          ...sessionData,
          'sessionId': sessionId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Create trainer session
        final trainerSessionRef = _firestore
            .collection('trainer_sessions')
            .doc(sessionData['professionalId'])
            .collection('allTrainerSessions')
            .doc(sessionId);

        batch.set(trainerSessionRef, finalSessionData);

        // Handle client sessions and notifications based on schedule type
        switch (sessionData['scheduleType']) {
          case 'existing_client':
            if (sessionData['connectionType'] == fbAppConnectionType) {
              _handleAppClientSession(batch, sessionId, finalSessionData);
            }
            break;
          case 'group':
            _handleGroupSession(batch, sessionId, finalSessionData);
            break;
          // Add other cases as needed
        }
      }

      await batch.commit();
      emit(ScheduleSessionSuccess());
    } catch (e) {
      debugPrint('Error creating recurring sessions: $e');
      emit(ScheduleSessionError(e.toString()));
    }
  }

  void _handleAppClientSession(
      WriteBatch batch, String sessionId, Map<String, dynamic> sessionData) {
    // Create client session document
    final clientSessionRef = _firestore
        .collection('client_sessions')
        .doc(sessionData['clientId'])
        .collection('allClientSessions')
        .doc(sessionId);

    batch.set(clientSessionRef, sessionData);

    // Only send notification for the first session in a recurring series
    if (!sessionData['isRecurring'] || sessionData['recurringWeek'] == 1) {
      _notificationService.createSessionNotification(
        clientId: sessionData['clientId'],
        senderId: sessionData['professionalId'],
        sessionId: sessionId,
        sessionData: sessionData,
        connectionType: sessionData['connectionType'],
        isRecurring: sessionData['isRecurring'] ?? false,
      );
    }
  }

  void _handleGroupSession(
      WriteBatch batch, String sessionId, Map<String, dynamic> sessionData) {
    final clients = sessionData['clients'] as List<dynamic>;
    for (final client in clients) {
      if (client['connectionType'] == fbAppConnectionType) {
        _handleAppClientSession(batch, sessionId, sessionData);
      }
    }
  }

  Future<void> _updateSession(
    UpdateSession event,
    Emitter<ScheduleSessionState> emit,
  ) async {
    try {
      emit(ScheduleSessionLoading());

      final data = event.data;
      final sessionId = data['sessionId'];
      final professionalId = data['professionalId'];

      // Update the session document
      await _firestore
          .collection('trainer_sessions')
          .doc(professionalId)
          .collection('allTrainerSessions')
          .doc(sessionId)
          .update(data);

      // If it's an app client, update their session document too
      if (data['connectionType'] == 'app') {
        await _firestore
            .collection('client_sessions')
            .doc(data['clientId'])
            .collection('allClientSessions')
            .doc(sessionId)
            .update(data);
      }

      emit(ScheduleSessionSuccess());
    } catch (e) {
      debugPrint('Error updating session: $e');
      emit(ScheduleSessionError(e.toString()));
    }
  }
}

// Main Page Widget
class ScheduleSessionPage extends StatefulWidget {
  final String initialScheduleType;
  final bool isEditing;
  final bool isPast;
  final String? sessionId;
  final Map<String, dynamic>? initialSessionData;
  final String? preSelectedClientId;
  final String initialSessionCategory;
  const ScheduleSessionPage({
    Key? key,
    this.initialScheduleType = 'existing_client',
    this.isEditing = false,
    this.isPast = false,
    this.sessionId,
    this.initialSessionData,
    this.preSelectedClientId,
    required this.initialSessionCategory,
  }) : super(key: key);

  @override
  State<ScheduleSessionPage> createState() => _ScheduleSessionPageState();
}

class _ScheduleSessionPageState extends State<ScheduleSessionPage> {
  String? selectedClientFullname;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScheduleSessionBloc(context),
      child: _ScheduleSessionContent(
        initialScheduleType: widget.initialScheduleType,
        isEditing: widget.isEditing,
        isPast: widget.isPast,
        sessionId: widget.sessionId,
        initialSessionData: widget.initialSessionData,
        preSelectedClientId: widget.preSelectedClientId,
        initialSessionCategory: widget.initialSessionCategory,
      ),
    );
  }
}

class _ScheduleSessionContent extends StatefulWidget {
  final String initialScheduleType;
  final bool isEditing;
  final bool isPast;
  final String? sessionId;
  final Map<String, dynamic>? initialSessionData;
  final String? preSelectedClientId;
  String? initialSessionCategory;
  _ScheduleSessionContent({
    required this.initialScheduleType,
    this.isEditing = false,
    this.isPast = false,
    this.sessionId,
    this.initialSessionData,
    this.preSelectedClientId,
    this.initialSessionCategory,
  });

  @override
  State<_ScheduleSessionContent> createState() =>
      _ScheduleSessionContentState();
}

class _ScheduleSessionContentState extends State<_ScheduleSessionContent>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;

  bool isRecurring = false;
  int recurringWeeks = 1;

  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _recurringWeeksController =
      TextEditingController();

  String? selectedClientId;
  String? selectedClientName;
  String? selectedClientFullname;
  String? selectedClientProfileImageURL;
  String? selectedClientConnectionType;
  String manualClientName = '';
  DateTime selectedDate = DateTime.now();
  TimeOfDay? selectedTime;
  String selectedSessionType = 'initial';
  String selectedMode = 'virtual';
  //String selectedSessionCategory = 'Assessment';
  int selectedDuration = 60;
  late String selectedScheduleType;

  List<SessionClient> selectedGroupClients = [];
  List<String> manualGroupClients = [];
  final TextEditingController _manualGroupClientController =
      TextEditingController();

  final _manualClientController = TextEditingController();

  

  final List<int> durations = [
    15,
    30,
    45,
    60,
    75,
    90,
    105,
    120,
    135,
    150,
    165,
    180
  ];

  // Add this field
  late final TextEditingController _sessionCategoryController;

  @override
  void initState() {
    super.initState();

    selectedScheduleType = widget.initialScheduleType;
    selectedDate = DateTime.now();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    if (!durations.contains(selectedDuration)) {
      selectedDuration = durations[2]; // Default to 60 minutes (index 2)
    }

    if (widget.isEditing && widget.initialSessionData != null) {
      _initializeEditData(widget.initialSessionData!);
    }

    // Add this section to handle pre-selected client
    if (widget.preSelectedClientId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializePreSelectedClient();
      });
    }

    // Initialize the controller
    _sessionCategoryController =
        TextEditingController(text: widget.initialSessionCategory);
  }

  void _initializeEditData(Map<String, dynamic> data) {
    // Initialize all form fields with existing data
    setState(() {
      selectedDate = (data['sessionDate'] as Timestamp).toDate();
      selectedTime =
          TimeOfDay.fromDateTime((data['sessionDate'] as Timestamp).toDate());
      widget.initialSessionCategory = data['sessionCategory'];
      selectedDuration = data['duration'];
      selectedSessionType = data['sessionType'] ?? 'initial';
      selectedMode = data['mode'] ?? 'virtual';
      _notesController.text = data['notes'] ?? '';

      // Handle client data based on schedule type
      if (data['scheduleType'] == 'group') {
        selectedGroupClients = (data['clients'] as List)
            .map((client) => SessionClient(
                  clientId: client['clientId'],
                  clientName: client['clientUsername'] ?? client['clientName'],
                  fullName: client['clientFullname'],
                  profileImageUrl: client['clientProfileImageUrl'],
                  connectionType: client['connectionType'],
                  status: client['status'],
                ))
            .toList();
      } else if (data['scheduleType'] == 'existing_client') {
        selectedClientId = data['clientId'];
        selectedClientName = data['clientUsername'];
        selectedClientFullname = data['clientFullname'];
        selectedClientProfileImageURL = data['clientProfileImageUrl'];
        selectedClientConnectionType = data['connectionType'];
      } else if (data['scheduleType'] == 'manual_client') {
        _manualClientController.text =
            data['clientUsername'] ?? data['clientName'];
      }

      // Handle recurring session data
      isRecurring = data['isRecurring'] ?? false;
      recurringWeeks = data['recurringWeeks'] ?? 1;
    });
  }

  // Add this method to handle pre-selected client
  Future<void> _initializePreSelectedClient() async {
    final userProvider = context.read<UserProvider>();
    final clients = userProvider.partiallyTotalClients ?? [];

    final selectedClient = clients.firstWhere(
      (client) => client['clientId'] == widget.preSelectedClientId,
      orElse: () => <String, dynamic>{}, // Return empty map instead of null
    );

    if (selectedClient.isNotEmpty) {
      // Check if map is not empty instead of null check
      setState(() {
        selectedClientId = selectedClient['clientId'];
        selectedClientName = selectedClient['clientName'];
        selectedClientFullname = selectedClient['clientFullName'];
        selectedClientProfileImageURL = selectedClient['clientProfileImageUrl'];
        selectedClientConnectionType = selectedClient['connectionType'];
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _notesController.dispose();
    _recurringWeeksController.dispose();
    _manualClientController.dispose();
    _manualGroupClientController.dispose();
    _sessionCategoryController.dispose();
    super.dispose();
  }

  Widget _buildScheduleTypeSelection() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Center(
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildScheduleTypeButton(
                    'existing_client',
                    l10n.existing_client,
                    Icons.person_outline,
                  ),
                  const SizedBox(width: 6),
                  _buildScheduleTypeButton(
                    'manual_client',
                    l10n.manual_client,
                    Icons.person_add_outlined,
                  ),
                  const SizedBox(width: 6),
                  _buildScheduleTypeButton(
                    'available_slot',
                    l10n.available_slot,
                    Icons.access_time_outlined,
                  ),
                  const SizedBox(width: 6),
                  _buildScheduleTypeButton(
                    'group',
                    l10n.group_schedule_session_type,
                    Icons.group_outlined,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Add info box when 'available_slot' is selected
        if (selectedScheduleType == 'available_slot')
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: myGrey80.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: myGrey60.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 20,
                    color: theme.brightness == Brightness.light
                        ? myGrey60
                        : myGrey40),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.create_available_time_slots_description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.brightness == Brightness.light
                          ? myGrey80
                          : myGrey20,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildGroupClientSelection() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (selectedScheduleType != 'group') return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing clients selection
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => _showGroupClientSelectionModal(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: theme.brightness == Brightness.light ? myGrey30 : myGrey60),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.group_outlined, color: theme.brightness == Brightness.light ? myGrey60 : myGrey40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.select_clients} *',
                          style: GoogleFonts.plusJakartaSans(
                            color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          selectedGroupClients.isEmpty
                              ? l10n.select_clients_for_group_session
                              : '${selectedGroupClients.length} ${l10n.clients_selected}',
                          style: GoogleFonts.plusJakartaSans(
                            color: selectedGroupClients.isNotEmpty
                                ? theme.brightness == Brightness.light ? Colors.black : Colors.white
                                : theme.brightness == Brightness.light ? myGrey40 : myGrey60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down, color: theme.brightness == Brightness.light ? myGrey60 : myGrey40),
                ],
              ),
            ),
          ),
        ),

        // Manual client addition
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.or_add_client_manually,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color:
                    theme.brightness == Brightness.light ? myGrey90 : myGrey20,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: CustomFocusTextField(
                    label: '',
                    hintText: l10n.enter_client_name,
                    controller: _manualGroupClientController,
                    prefixIcon: Icons.person_outline,
                    shouldShowBorder: true,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_manualGroupClientController.text.trim().isNotEmpty) {
                      setState(() {
                        selectedGroupClients.add(SessionClient(
                          clientName: _manualGroupClientController.text.trim(),
                          connectionType: fbTypedConnectionType,
                        ));
                        _manualGroupClientController.clear();
                      });
                    }
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: myBlue30,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: myBlue60,
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.add, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Display selected clients
        if (selectedGroupClients.isNotEmpty) ...[
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.selected,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.brightness == Brightness.light ? myGrey90 : myGrey20,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedGroupClients.map((client) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: myGrey20,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          client.clientName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: myGrey70,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedGroupClients.remove(client);
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: myGrey60,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _showGroupClientSelectionModal(BuildContext context) {
    MultipleClientSelectionSheet.show(
      context,
      selectedGroupClients,
      (List<SessionClient> clients) {
        setState(() {
          selectedGroupClients = clients;
        });
        return;
      },
    );
  }

  Widget _buildScheduleTypeButton(String type, String label, IconData icon) {
    bool isSelected = selectedScheduleType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedScheduleType = type;
          // Reset client-related fields
          selectedClientId = null;
          selectedClientName = null;
          selectedClientFullname = null;
          selectedClientProfileImageURL = null;
          selectedClientConnectionType = null;
          manualClientName = '';

          // Update session category for group sessions
          if (type == 'group' &&
              widget.initialSessionCategory == '1:1 Training') {
            widget.initialSessionCategory = '1:X Training';
          } else if (type != 'group' &&
              widget.initialSessionCategory == '1:X Training') {
            widget.initialSessionCategory = '1:1 Training';
          }
        });
        _animationController.forward(from: 0);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 8, // Reduced padding
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? myBlue60.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32, // Reduced size
              height: 32, // Reduced size
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? myBlue60 : Colors.transparent,
                border: Border.all(
                  color: isSelected ? myBlue60 : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 16, // Reduced size
                color: isSelected ? Colors.white : Colors.grey[400],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: SizedBox(width: isSelected ? 6 : 0), // Reduced spacing
            ),
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  width: isSelected ? null : 0,
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      color: myBlue60,
                      fontWeight: FontWeight.w500,
                      fontSize: 12, // Reduced font size
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientField() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (selectedScheduleType == 'existing_client') {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          onTap: () => _showClientSelectionModal(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: theme.brightness == Brightness.light ? myGrey30 : myGrey80),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline, color: theme.brightness == Brightness.light ? myGrey60 : myGrey40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.client} *',
                        style: GoogleFonts.plusJakartaSans(
                          color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        selectedClientFullname ??
                            selectedClientName ??
                            l10n.select_client,
                        style: GoogleFonts.plusJakartaSans(
                          color: selectedClientName != null
                              ? theme.brightness == Brightness.light ? Colors.black : Colors.white
                              : theme.brightness == Brightness.light ? myGrey40 : myGrey60,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: theme.brightness == Brightness.light ? myGrey60 : myGrey40),
              ],
            ),
          ),
        ),
      );
    } else if (selectedScheduleType == 'manual_client') {
      return CustomFocusTextField(
        label: l10n.client_name,
        hintText: l10n.type_client_name,
        controller: _manualClientController,
        isRequired: true,
        shouldShowBorder: true,
        onChanged: (value) {
          setState(() {
            manualClientName = value;
          });
        },
        validator: (value) {
          /*
          if (value == null || value.trim().isEmpty) {
            return 'Please enter client name';
          }
          */
          return null;
        },
      );
    }
    // Add other cases if needed
    return const SizedBox.shrink();
  }

  void _showClientSelectionModal(BuildContext context) {
    ClientSelectionSheet.show(
      context,
      (String clientId, String clientUsername, String clientFullName,
          String connectionType, String clientProfileImageURL) {
        setState(() {
          selectedClientId = clientId;
          selectedClientName = clientUsername;
          selectedClientFullname = clientFullName;
          selectedClientProfileImageURL = clientProfileImageURL;
          selectedClientConnectionType = connectionType;
        });
      },
    );
  }

  Future<void> _saveChanges() async {
    final l10n = AppLocalizations.of(context)!;
    final _notificationService = NotificationService();
    
    if (!_formKey.currentState!.validate()) return;

    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
          title: l10n.missing_information,
          message: l10n.please_select_date_and_time,
          type: SnackBarType.warning,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: myBlue60)),
      );

      final userData = context.read<UserProvider>().userData;
      if (userData == null) return;

      // Prepare basic update data
      final DateTime sessionDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      Map<String, dynamic> updateData = {
        'sessionDate': Timestamp.fromDate(sessionDateTime),
        'time': _formatTimeIn24Hours(selectedTime!),
        'sessionCategory': widget.initialSessionCategory,
        'duration': selectedDuration,
        'sessionType': selectedSessionType,
        'mode': selectedMode,
        'notes': _notesController.text,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Update trainer's document
      await FirebaseFirestore.instance
          .collection('trainer_sessions')
          .doc(userData['userId'])
          .collection('allTrainerSessions')
          .doc(widget.sessionId)
          .update(updateData);

      // Handle different session types and notifications
      switch (widget.initialScheduleType) {
        case 'group':
          if (widget.initialSessionData?['clients'] != null) {
            final batch = FirebaseFirestore.instance.batch();
            
            for (var client in widget.initialSessionData!['clients']) {
              if (client['connectionType'] != 'typed') {
                // Update client's session document
                final clientRef = FirebaseFirestore.instance
                    .collection('client_sessions')
                    .doc(client['clientId'])
                    .collection('allClientSessions')
                    .doc(widget.sessionId);
                
                batch.update(clientRef, updateData);

                // Send notification to app users
                if (client['connectionType'] == 'app') {
                  await _notificationService.createSessionUpdatedNotification(
                    clientId: client['clientId'],
                    trainerId: userData['userId'],
                    sessionId: widget.sessionId!,
                    sessionData: {...widget.initialSessionData!, ...updateData},
                    trainerData: userData,
                    isGroupSession: true,
                  );
                }
              }
            }
            
            await batch.commit();
          }
          break;

        case 'existing_client':
        case 'manual_client':
          // Update client's session document
          await FirebaseFirestore.instance
              .collection('client_sessions')
              .doc(widget.initialSessionData!['clientId'])
              .collection('allClientSessions')
              .doc(widget.sessionId)
              .update(updateData);

          // Send notification if client is an app user
          if (widget.initialSessionData?['connectionType'] == 'app') {
          await _notificationService.createSessionUpdatedNotification(
            clientId: widget.initialSessionData!['clientId'],
            trainerId: userData['userId'],
            sessionId: widget.sessionId!,
            sessionData: {...widget.initialSessionData!, ...updateData},
            trainerData: userData,
            isGroupSession: false,
          );
          }
          break;

        case 'available_slot':
          // No notifications needed for available slots
          break;
      }

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pop(context, updateData); // Return to previous screen with updated data
        
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.session,
            message: l10n.session_updated_successfully,
            type: SnackBarType.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating session: $e');
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.error,
            message: l10n.failed_to_update_session,
            type: SnackBarType.error,
          ),
        );
      }
    }
  }

  void _submitForm() {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    if (selectedScheduleType == 'manual_client') {
      manualClientName = _manualClientController.text.trim();
    }

    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
          title: l10n.missing_information,
          message: l10n.please_select_date_and_time,
          type: SnackBarType.warning,
        ),
      );
      return;
    }

    // Add validation for past date/time
    final DateTime sessionDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    if (sessionDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
          title: l10n.invalid_date_time,
          message: l10n.cannot_schedule_session_in_past,
          type: SnackBarType.warning,
        ),
      );
      return;
    }

    final userData = context.read<UserProvider>().userData;
    if (userData == null || userData['userId'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
          title: l10n.error,
          message: l10n.user_data_is_not_complete,
          type: SnackBarType.error,
        ),
      );
      return;
    }

    Map<String, dynamic> sessionData = {
      'professionalId': userData['userId'].toString(),
      'professionalUsername': userData[fbRandomName].toString(),
      'professionalFullname':
          userData[fbFullName]?.toString() ?? userData[fbRandomName].toString(),
      'professionalRole': userData['role'].toString(),
      'professionalProfileImageUrl': userData[fbProfileImageURL]?.toString(),
    };

    // Add the session ID if we're editing
    if (widget.isEditing && widget.sessionId != null) {
      sessionData['sessionId'] = widget.sessionId;
    }

    // Update the switch case for manual_client
    switch (selectedScheduleType) {
      case 'group':
        debugPrint('selectedGroupClients: ${selectedGroupClients.length}');
        if (selectedGroupClients.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            CustomSnackBar.show(
              title: l10n.missing_information,
              message: l10n.please_add_at_least_one_client_to_the_group,
              type: SnackBarType.warning,
            ),
          );
          return;
        }

        final createdRandomId =
            'TYPED_${DateTime.now().millisecondsSinceEpoch}';

        final allClients = selectedGroupClients
            .map((client) => {
                  'clientId': client.clientId ?? createdRandomId,
                  'clientUsername': client.clientName,
                  'clientFullname': client.fullName ?? client.clientName,
                  'clientProfileImageUrl': client.profileImageUrl ?? '',
                  'connectionType': client.connectionType,
                  'status': client.connectionType == fbAppConnectionType
                      ? (client.clientId == userData['trainerClientId']
                          ? fbClientConfirmedStatus
                          : fbCreatedStatusForAppUser)
                      : fbCreatedStatusForNotAppUser,
                })
            .toList();

        sessionData['isGroupSession'] = true;
        sessionData['clients'] = allClients;
        sessionData['status'] = fbCreatedStatusForGroup;
        break;

      case 'existing_client':
        if (selectedClientId == null || selectedClientName == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            CustomSnackBar.show(
              title: l10n.missing_information,
              message: l10n.please_select_a_client,
              type: SnackBarType.warning,
            ),
          );
          return;
        }
        final client =
            (context.read<UserProvider>().partiallyTotalClients ?? [])
                .firstWhere((c) => c['clientId'] == selectedClientId);

        debugPrint('client: $client');

        sessionData['clientId'] = selectedClientId.toString();
        sessionData['clientUsername'] = client['clientName'];
        sessionData['clientFullname'] =
            client['clientFullName'] ?? client['clientName'];
        sessionData['clientProfileImageUrl'] =
            client['clientProfileImageUrl']?.toString();
        sessionData['connectionType'] = client['connectionType'];
        sessionData['status'] = client['connectionType'] == fbAppConnectionType
            ? (client['clientId'] == userData['trainerClientId']
                ? fbClientConfirmedStatus
                : fbCreatedStatusForAppUser)
            : fbCreatedStatusForNotAppUser;
        break;

      case 'manual_client':
        if (_manualClientController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            CustomSnackBar.show(
              title: l10n.missing_information,
              message: l10n.please_enter_client_name,
              type: SnackBarType.warning,
            ),
          );
          return;
        }
        final manualClientId =
            'TYPED_${DateTime.now().millisecondsSinceEpoch}_${_manualClientController.text.trim().replaceAll(' ', '_')}';
        sessionData['clientId'] = manualClientId;
        sessionData['clientUsername'] = _manualClientController.text.trim();
        sessionData['clientFullname'] = _manualClientController.text.trim();
        sessionData['connectionType'] = fbTypedConnectionType;
        sessionData['status'] = fbCreatedStatusForNotAppUser;
        break;

      case 'available_slot':
        sessionData['status'] = fbCreatedStatusForAvailableSlot;
        break;
    }


    sessionData.addAll({
      'sessionDate': Timestamp.fromDate(sessionDateTime),
      'time': selectedTime != null ? _formatTimeIn24Hours(selectedTime!) : '',
      'sessionCategory': widget.initialSessionCategory,
      'duration': selectedDuration,
      'sessionType': selectedSessionType,
      'mode': selectedMode,
      'notes': _notesController.text,
      'scheduleType': selectedScheduleType,
      'isRecurring': isRecurring,
      'recurringWeeks': isRecurring ? recurringWeeks : 0,
    });

    // Handle recurring sessions
    if (isRecurring) {
      final weeks = recurringWeeks;
      if (weeks < 1 || weeks > 24) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.error,
            message: l10n.number_of_weeks_must_be_between_1_and_24,
            type: SnackBarType.error,
          ),
        );
        return;
      }

      // Generate a single recurringId for all sessions in the series
      final String recurringId = _firestore
          .collection('trainer_sessions')
          .doc(userData['userId'])
          .collection('allTrainerSessions')
          .doc()
          .id;

      // Create a list of all recurring session data
      List<Map<String, dynamic>> recurringSessionsData = [];

      for (int i = 0; i < weeks; i++) {
        final recurringDateTime = sessionDateTime.add(Duration(days: 7 * i));
        final recurringData = {
          ...sessionData,
          'sessionDate': Timestamp.fromDate(recurringDateTime),
          'isRecurring': true,
          'recurringWeek': i + 1,
          'totalRecurringWeeks': weeks,
          'firstSessionDate': Timestamp.fromDate(sessionDateTime),
          'recurringId':
              recurringId, // Add the same recurringId to all sessions
        };
        recurringSessionsData.add(recurringData);
      }

      // Create all sessions in a single batch
      context.read<ScheduleSessionBloc>().add(
            CreateRecurringSessions(data: recurringSessionsData),
          );
    } else {
      // Single session doesn't need recurringId
      sessionData['isRecurring'] = false;
      context.read<ScheduleSessionBloc>().add(
            CreateSession(data: sessionData),
          );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await CustomDatePicker.show(
      context: context,
      initialDate: selectedDate,
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await CustomTimePicker.show(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Widget _buildDateTimePicker() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.date} *',
                          style: GoogleFonts.plusJakartaSans(
                            color: theme.brightness == Brightness.light
                                ? myGrey60
                                : myGrey40,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, y').format(selectedDate),
                          style: GoogleFonts.plusJakartaSans(
                            color: theme.brightness == Brightness.light
                                ? myGrey90
                                : myGrey20,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () => _selectTime(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.time} *',
                          style: GoogleFonts.plusJakartaSans(
                            color: theme.brightness == Brightness.light
                                ? myGrey60
                                : myGrey40,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          selectedTime == null
                              ? l10n.select_time
                              : selectedTime!.format(context),
                          style: GoogleFonts.plusJakartaSans(
                            color: selectedTime != null
                                ? theme.brightness == Brightness.light
                                    ? myGrey90
                                    : myGrey20
                                : theme.brightness == Brightness.light
                                    ? myGrey60
                                    : myGrey40,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionTypeSelection() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    // Don't show session type selection for available slots
    if (selectedScheduleType == 'available_slot') {
      return const SizedBox.shrink(); // Returns an empty widget
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.session_type,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.brightness == Brightness.light ? myGrey90 : myGrey20,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSelectionButton(
                l10n.initial,
                selectedSessionType == 'initial',
                () => setState(() => selectedSessionType = 'initial'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSelectionButton(
                l10n.follow_up,
                selectedSessionType == 'follow-up',
                () => setState(() => selectedSessionType = 'follow-up'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeSelection() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.session_mode,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.brightness == Brightness.light ? myGrey90 : myGrey20,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSelectionButton(
                l10n.virtual,
                selectedMode == 'virtual',
                () => setState(() => selectedMode = 'virtual'),
                icon: Icons.videocam,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSelectionButton(
                l10n.in_person,
                selectedMode == 'in-person',
                () => setState(() => selectedMode = 'in-person'),
                icon: Icons.person,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionButton(
    String text,
    bool isSelected,
    VoidCallback onTap, {
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? myBlue30 : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? myBlue60 : theme.cardColor,
            border: Border.all(
              color: isSelected ? myBlue60 : myGrey30,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _getSessionCategories() {
    final l10n = AppLocalizations.of(context)!;
    return selectedScheduleType == 'group'
        ? [
            l10n.one_x_training,
            l10n.assessment,
            l10n.progress_review,
            l10n.consultation,
            l10n.other_category,
          ]
        : [
            l10n.one_one_training,
            l10n.assessment,
            l10n.progress_review,
            l10n.consultation,
            l10n.other_category,
            if (selectedScheduleType == 'available_slot') l10n.any,
          ];
  }

  Widget _buildSessionCategorySelection() {
    final l10n = AppLocalizations.of(context)!;
    return CustomSelectTextField(
      label: l10n.session_category,
      hintText: l10n.select_category,
      controller: _sessionCategoryController,
      options: _getSessionCategories(),
      prefixIcon: Icons.category_outlined,
      isRequired: true,
      onChanged: (value) {
        setState(() {
          widget.initialSessionCategory = value;
        });
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    final l10n = AppLocalizations.of(context)!;
    if (category == l10n.one_one_training) {
      return Icons.fitness_center;
    } else if (category == l10n.one_x_training) {
      return Icons.fitness_center;
    } else if (category == l10n.assessment) {
      return Icons.assessment;
    } else if (category == l10n.progress_review) {
      return Icons.trending_up;
    } else if (category == l10n.consultation) {
      return Icons.chat;
    } else if (category == l10n.any) {
      return Icons.all_inclusive;
    } else if (category == l10n.other_category) {
      return Icons.more_horiz;
    } else {
      return Icons.circle;
    }
  }

  Widget _buildDurationSelection() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          l10n.duration,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.brightness == Brightness.light ? myGrey90 : myGrey20,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120 + 8,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color:
                    theme.brightness == Brightness.light ? myGrey20 : myGrey80),
          ),
          child: CustomSingleSpinner<int>(
            initialValue: selectedDuration,
            values: durations,
            itemWidth: MediaQuery.of(context).size.width - 64,
            itemHeight: 40,
            textMapper: (value) => l10n.minutes(value),
            onValueChanged: (value) {
              setState(() {
                selectedDuration = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSessionNotes() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomFocusTextField(
          controller: _notesController,
          label: l10n.session_notes,
          hintText: l10n.session_notes_hint,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildRecurringOption() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.recurring_session_label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.brightness == Brightness.light ? myGrey90 : myGrey20,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            CustomToggleSwitch(
              value: isRecurring,
              onChanged: (value) => setState(() => isRecurring = value),
            ),
          ],
        ),
        if (isRecurring) ...[
          const SizedBox(height: 16),
          HorizontalNumberSlider(
            title: l10n.recurring_weeks,
            minValue: 1,
            maxValue: 24,
            initialValue: recurringWeeks,
            onValueChanged: (value) {
              setState(() {
                recurringWeeks = value;
                _recurringWeeksController.text = value.toString();
              });
            },
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  String _formatTimeIn24Hours(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          widget.isEditing ? l10n.edit_session : (widget.initialScheduleType == 'available_slot' ? l10n.available_slot : l10n.schedule_session_title),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: BlocConsumer<ScheduleSessionBloc, ScheduleSessionState>(
        listener: (context, state) {
          debugPrint('Current state: $state');
          if (state is ScheduleSessionSuccess) {
            debugPrint('Success state reached');
            ScaffoldMessenger.of(context).showSnackBar(
              CustomSnackBar.show(
                title: l10n.success,
                message: l10n.session_scheduled,
                type: SnackBarType.success,
              ),
            );
            if (context.mounted) {
              if (widget.initialScheduleType == 'available_slot') {
                Navigator.pop(context, state.sessionData);
              } else {
                Navigator.pop(context);
              }
            }
          } else if (state is ScheduleSessionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              CustomSnackBar.show(
                title: l10n.error,
                message: state.message,
                type: SnackBarType.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.isEditing == false && widget.initialScheduleType != 'available_slot') ...[
                                  Center(
                                    child: Container(
                                      constraints: const BoxConstraints(maxWidth: 800),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: theme.cardColor,
                                        border: Border(
                                          bottom: BorderSide(
                                            color: theme.brightness ==
                                                    Brightness.light
                                                ? myGrey20
                                                : myGrey80,
                                            width: 1,
                                          ),
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          _buildScheduleTypeSelection(),
                                          _buildGroupClientSelection(),
                                          if (selectedScheduleType != 'group')
                                            _buildClientField(),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                Center(
                                  child: Container(
                                    constraints: const BoxConstraints(maxWidth: 800),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        if (widget.isPast == false) ...[
                                          _buildSessionCategorySelection(),
                                          const SizedBox(height: 24),
                                          _buildDateTimePicker(),
                                          const SizedBox(height: 24),
                                          if (widget.isEditing == false) ...[
                                            _buildRecurringOption(),
                                            const SizedBox(height: 24),
                                          ],
                                          _buildDurationSelection(),
                                          if (selectedScheduleType !=
                                              'available_slot') ...[
                                            const SizedBox(height: 24),
                                            _buildSessionTypeSelection(),
                                          ],
                                          const SizedBox(height: 24),
                                          _buildModeSelection(),
                                          const SizedBox(height: 24),
                                        ],
                                        if (widget.isPast == true) ...[
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: myGrey80.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color:
                                                      myGrey60.withOpacity(0.2)),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.info_outline,
                                                    size: 20,
                                                    color: theme.brightness ==
                                                            Brightness.light
                                                        ? myGrey60
                                                        : myGrey40),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'The session is in the past. You can still add notes to the session.',
                                                    style: theme
                                                        .textTheme.bodyMedium
                                                        ?.copyWith(
                                                      color: theme.brightness ==
                                                              Brightness.light
                                                          ? myGrey80
                                                          : myGrey20,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                        _buildSessionNotes(),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 16, top: 8),
                      child: ElevatedButton(
                        onPressed:
                            state is! ScheduleSessionLoading ? (widget.isEditing ? _saveChanges : _submitForm) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: myBlue60,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.isEditing
                              ? l10n.save_changes
                              : l10n.schedule_session_title,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (state is ScheduleSessionLoading)
                Container(
                  color: theme.brightness == Brightness.light
                      ? Colors.black12
                      : Colors.white12,
                  child: const Center(
                    child: CircularProgressIndicator(color: myBlue60),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
