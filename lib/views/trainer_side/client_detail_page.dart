import 'package:naturafit/services/auth/bloc/data_fetch_service.dart';
import 'package:naturafit/services/unit_preferences.dart';
import 'package:naturafit/views/client_side/client_profile_page.dart';
import 'package:naturafit/views/client_side/client_progress_page.dart';
import 'package:naturafit/views/shared_side/direct_message_page.dart';
import 'package:naturafit/views/trainer_side/session_details_page.dart';
import 'package:naturafit/widgets/custom_top_selector.dart';
import 'package:naturafit/widgets/custom_user_profile_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:naturafit/services/invitation/invitation_bloc.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/views/trainer_side/edit_client_page.dart';
import 'package:naturafit/views/trainer_side/client_all_sessions_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:naturafit/views/trainer_side/assessment_form_page.dart';

class ClientDetailPage extends StatefulWidget {
  final Map<String, dynamic> client;

  ClientDetailPage({
    Key? key,
    required this.client,
  }) : super(key: key);

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  Map<String, dynamic>? _fetchedUserData;
  bool _isLoading = true;
  List<Map<String, dynamic>> _bookmarkedExercises = [];

  final List<TopSelectorOption> _options = [
    TopSelectorOption(title: 'by Client'),
    TopSelectorOption(title: 'by Trainer'),
  ];

  int _selectedSectionIndex = 0;

  Map<String, dynamic>? _clientInfoEnteredByTrainer;
  Map<String, dynamic>? _nextSession;
  Map<String, dynamic>? _latestAssessmentForm;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchClientInfoEnteredByTrainer();
    //_fetchBookmarkedExercises();
    _fetchNextSession();
    _fetchLatestAssessmentForm();
  }

  Future<void> _fetchClientInfoEnteredByTrainer() async {
    final userData = context.read<UserProvider>().userData;
    if (userData == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('client_info')
        .doc(userData['role'])
        .collection(userData['userId'])
        .doc(widget.client['clientId'])
        .get();

    if (doc.exists) {
      debugPrint('Client info found');
      setState(() {
        _clientInfoEnteredByTrainer = doc.data();
        debugPrint('my Client info: ${_clientInfoEnteredByTrainer}');
      });
    } else {
      debugPrint('Client info not found');
      setState(() {
        _clientInfoEnteredByTrainer = null;
      });
    }
  }

  Future<void> _fetchUserData() async {
    if (widget.client['connectionType'] == 'app' &&
        widget.client['clientId'] != null) {
      debugPrint('Fetching user data for client: ${widget.client['clientId']}');
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.client['clientId'])
            .get();

        if (doc.exists) {
          setState(() {
            _fetchedUserData = doc.data();
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error fetching user data: $e');
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchBookmarkedExercises() async {
    try {
      final workoutsSnapshot = await FirebaseFirestore.instance
          .collection('workouts')
          .doc('clients')
          .collection(widget.client['clientId'])
          .get();

      final uniqueExercises = <String, Map<String, dynamic>>{};

      for (var workoutDoc in workoutsSnapshot.docs) {
        final workoutData = workoutDoc.data();
        final List<dynamic> workoutDays = workoutData['workoutDays'] ?? [];

        for (var day in workoutDays) {
          for (var phase in day['phases'] as List<dynamic>) {
            for (var exercise in phase['exercises'] as List<dynamic>) {
              if (exercise['isBookmarked'] == true) {
                uniqueExercises[exercise['name']] = {
                  ...exercise,
                  'workoutName': workoutData['planName'],
                  'phaseName': phase['name'],
                };
              }
            }
          }
        }
      }

      setState(() {
        _bookmarkedExercises = uniqueExercises.values.toList();
      });
    } catch (e) {
      debugPrint('Error fetching bookmarked exercises: $e');
    }
  }

  Future<void> _fetchNextSession() async {
    try {
      final now = DateTime.now();
      debugPrint(
          'Fetching next session for client: ${widget.client['clientId']}');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('client_sessions')
          .doc(widget.client['clientId'])
          .collection('allClientSessions')
          .where('sessionDate', isGreaterThan: now)
          .orderBy('sessionDate')
          .limit(1)
          .get();

      debugPrint('Query snapshot empty: ${querySnapshot.docs.isEmpty}');
      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _nextSession = querySnapshot.docs.first.data();
          debugPrint('Next session data: $_nextSession');
        });
      }
    } catch (e) {
      debugPrint('Error fetching next session: $e');
    }
  }

  Future<void> _fetchLatestAssessmentForm() async {
    debugPrint('Fetching latest assessment form for client: ${widget.client['clientId']}');
    try {
      final userData = context.read<UserProvider>().userData;
      if (userData == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('assessment_forms')
          .doc(userData['userId'])
          .collection('all_forms')
          .where('clientId', isEqualTo: widget.client['clientId'])
          .orderBy('completedDate', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _latestAssessmentForm = querySnapshot.docs.first.data();
          debugPrint('Latest assessment form found: ${_latestAssessmentForm?['status']}');
        });
      } else {
        debugPrint('No assessment forms found for this client');
      }
    } catch (e) {
      debugPrint('Error fetching latest assessment form: $e');
    }
  }

  Future<void> _handleSessionTap(
      BuildContext context, String? sessionId) async {
    if (sessionId != null) {
      try {
        final userData = context.read<UserProvider>().userData;
        if (userData == null) return;

        final doc = await FirebaseFirestore.instance
            .collection('trainer_sessions')
            .doc(sessionId)
            .get();

        if (doc.exists && context.mounted) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SessionDetailsPage(
                sessionId: sessionId,
                trainerId: userData['userId'],
              ),
            ),
          );

          if (result != null &&
              result is Map<String, dynamic> &&
              (result['deleted'] == true ||
                  result['cancelled'] == true ||
                  result['edited'] == true)) {
            // Add edited check
            // Clear cache and refresh data
            if (context.mounted) {
              debugPrint('Refreshing professional slots');
              await DataFetchService().fetchProfessionalSlots(
                  userData['userId'], 'trainer', context.read<UserProvider>());
            }

            _fetchedUserData = null;
            _fetchUserData();
          }
        }
      } catch (e) {
        debugPrint('Error fetching session: $e');
      }
    }
  }

  String _formatBirthday(String? dateStr) {
    if (dateStr == null || dateStr == '') return 'N/A';

    try {
      // First check if it's a timestamp string
      if (dateStr.contains('Timestamp')) {
        final timestamp = Timestamp.fromMillisecondsSinceEpoch(
            int.parse(dateStr.split('=')[1].replaceAll(')', '')));
        return DateFormat('MMMM d, y').format(timestamp.toDate());
      }

      // Otherwise parse as regular date string
      final parts = dateStr.split('-');
      if (parts.length != 3) return dateStr;

      final year = parts[0];
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      final monthNames = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];

      return '${monthNames[month - 1]} $day, $year';
    } catch (e) {
      return dateStr;
    }
  }

  // Add this helper method to format phone numbers
  String _formatPhoneNumber(String phone) {
    // Handle country code format (XX|+XX|XXXXXXXX)
    if (phone.contains('|')) {
      // Split by pipe character
      List<String> parts = phone.split('|');
      if (parts.length == 3) {
        String countryCode =
            parts[1].substring(1); // Remove the + from second part
        String number = parts[2];

        // Format as (+XX) XXXXXXXXX
        return '(+$countryCode) $number';
      }
    }

    // If no special format, just return as is with spaces every 3 digits
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    List<String> parts = [];
    String temp = cleaned;
    while (temp.length > 3) {
      parts.add(temp.substring(0, 3));
      temp = temp.substring(3);
    }
    if (temp.isNotEmpty) {
      parts.add(temp);
    }

    return parts.join(' ');
  }

  // Modify the _buildInfoRow method to handle phone numbers
  Widget _buildInfoRow(BuildContext context, String label, dynamic value,
      [bool isSession = false]) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (isSession && value is Timestamp) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: theme.brightness == Brightness.light
                    ? Colors.grey[600]
                    : myGrey60,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () =>
                  _handleSessionTap(context, widget.client['sessionId']),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: myBlue60.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: myBlue60.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: myBlue60,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM d, y • HH:mm').format(value.toDate()),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: myBlue60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: myBlue60,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    String displayValue;
    if (value is Timestamp) {
      displayValue = DateFormat('MMM d, y • HH:mm').format(value.toDate());
    } else if (value == null || value == '') {
      displayValue = 'N/A';
    } else if (label == 'Phone') {
      displayValue = _formatPhoneNumber(value.toString());
    } else {
      displayValue = value.toString();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: theme.brightness == Brightness.light
                  ? Colors.grey[600]
                  : myGrey50,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayValue,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: theme.brightness == Brightness.light
                  ? Colors.black87
                  : myGrey10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final userData = context.read<UserProvider>().userData;
    final unitPreferences = context.read<UnitPreferences>();
    final weightUnit = userData?['weightUnit'] ?? 'kg';
    final heightUnit = userData?['heightUnit'] ?? 'cm';

    final convertedWeight = weightUnit == 'kg'
        ? (_fetchedUserData?['weight'] ?? 0)
        : unitPreferences.kgToLbs(_fetchedUserData?['weight'] ?? 0);
    final convertedHeight = heightUnit == 'cm'
        ? (_fetchedUserData?['height'] ?? 0)
        : unitPreferences.cmToft(_fetchedUserData?['height'] ?? 0);

    // Get consent settings
    final consentSettings =
        widget.client['connectionType'] == 'app' && _fetchedUserData != null
            ? _fetchedUserData!['dataConsent'] ??
                {
                  'birthday': false,
                  'email': false,
                  'phone': false,
                  'location': false,
                  'measurements': false,
                  'progressPhotos': false,
                  'socialMedia': false,
                }
            : {
                'birthday': true,
                'email': true,
                'phone': true,
                'location': true,
                'measurements': true,
                'progressPhotos': true,
                'socialMedia': true,
              };

    return Card(
      elevation: 0,
      color: theme.brightness == Brightness.light ? Colors.white : myGrey90,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading) ...[
              const Center(child: CircularProgressIndicator(color: myBlue60)),
            ] else if (title == 'Personal Information') ...[
              if (consentSettings['email'] == true)
                _buildInfoRow(
                    context,
                    l10n.email,
                    widget.client['connectionType'] == 'app' &&
                            _fetchedUserData != null
                        ? _fetchedUserData!['email']
                        : widget.client['email']),
              if (consentSettings['phone'] == true)
                _buildInfoRow(
                    context,
                    l10n.phone,
                    widget.client['connectionType'] == 'app' &&
                            _fetchedUserData != null
                        ? _fetchedUserData!['phone']
                        : widget.client['phone']),
              if (consentSettings['birthday'] == true)
                _buildInfoRow(
                    context,
                    l10n.birthday,
                    widget.client['connectionType'] == 'app' &&
                            _fetchedUserData != null
                        ? (_fetchedUserData!['birthday'] is Timestamp
                            ? _getBirthdayTimestamp(
                                _fetchedUserData!['birthday'])
                            : _formatBirthday(
                                _fetchedUserData!['birthday'].toString()))
                        : _formatBirthday(widget.client['birthday'])),
              _buildInfoRow(
                  context,
                  l10n.gender,
                  widget.client['connectionType'] == 'app' &&
                          _fetchedUserData != null
                      ? _fetchedUserData!['gender']
                      : widget.client['gender']),
              if (consentSettings['location'] == true)
                _buildInfoRow(
                    context,
                    l10n.location,
                    widget.client['connectionType'] == 'app' &&
                            _fetchedUserData != null
                        ? _fetchedUserData!['location']
                        : widget.client['location']),
            ] else if (title == 'Health & Fitness') ...[
              _buildInfoRow(
                  context,
                  l10n.current_fitness,
                  widget.client['connectionType'] == 'app' &&
                          _fetchedUserData != null
                      ? _fetchedUserData!['currentFitnessLevel']
                      : widget.client['fitnessLevel']),
              _buildInfoRow(
                  context,
                  l10n.injuries,
                  widget.client['connectionType'] == 'app' &&
                          _fetchedUserData != null
                      ? _fetchedUserData!['injuries']
                      : widget.client['injuries']),
              _buildInfoRow(
                  context,
                  l10n.dietary_restrictions,
                  widget.client['connectionType'] == 'app' &&
                          _fetchedUserData != null
                      ? _fetchedUserData!['dietaryRestrictions']
                      : widget.client['dietaryRestrictions']),
              _buildInfoRow(
                  context,
                  l10n.primary_goal,
                  widget.client['connectionType'] == 'app' &&
                          _fetchedUserData != null
                      ? _fetchedUserData!['primaryGoal']
                      : widget.client['primaryGoal']),
              _buildInfoRow(
                  context,
                  l10n.secondary_goal,
                  widget.client['connectionType'] == 'app' &&
                          _fetchedUserData != null
                      ? _fetchedUserData!['secondaryGoal']
                      : widget.client['secondaryGoal']),
            ] else if (title == 'Measurements') ...[
              if (consentSettings['measurements'] == true) ...[
                _buildInfoRow(
                    context,
                    l10n.height,
                    widget.client['connectionType'] == 'app' &&
                            _fetchedUserData != null
                        ? '${convertedHeight.toStringAsFixed(1)} $heightUnit'
                        : widget.client['height']),
                _buildInfoRow(
                    context,
                    l10n.weight,
                    widget.client['connectionType'] == 'app' &&
                            _fetchedUserData != null
                        ? '${convertedWeight.toStringAsFixed(1)} $weightUnit'
                        : widget.client['weight']),
              ] else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      l10n.measurements_access_denied,
                      style: GoogleFonts.plusJakartaSans(
                        color: myGrey60,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _getBirthdayTimestamp(Timestamp timestamp) {
    final DateTime date = timestamp.toDate();
    return DateFormat('MMMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final userData = context.read<UserProvider>().userData;
    final unitPreferences = context.read<UnitPreferences>();
    final myHeightUnit = userData?['heightUnit'] ?? 'cm';
    final myWeightUnit = userData?['weightUnit'] ?? 'kg';

    final clientConvertedHeight = widget.client['height'] == null
        ? 0
        : myHeightUnit == 'cm'
            ? widget.client['height']
            : unitPreferences.cmToft(widget.client['height']);
    final clientConvertedWeight = widget.client['weight'] == null
        ? 0
        : myWeightUnit == 'kg'
            ? widget.client['weight']
            : unitPreferences.kgToLbs(widget.client['weight']);

    final convertedHeightEnteredByTrainer =
        _clientInfoEnteredByTrainer?['height'] == null
            ? 0
            : myHeightUnit == 'cm'
                ? (_clientInfoEnteredByTrainer?['height'] ?? 0)
                : unitPreferences
                    .cmToft(_clientInfoEnteredByTrainer?['height'] ?? 0);
    final convertedWeightEnteredByTrainer =
        _clientInfoEnteredByTrainer?['weight'] == null
            ? 0
            : myWeightUnit == 'kg'
                ? (_clientInfoEnteredByTrainer?['weight'] ?? 0)
                : unitPreferences
                    .kgToLbs(_clientInfoEnteredByTrainer?['weight'] ?? 0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
                color: theme.brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
                width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.chevron_left,
                color: theme.brightness == Brightness.light
                    ? Colors.black
                    : Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Client Details',
          style: GoogleFonts.plusJakartaSans(
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (widget.client['connectionType'] == 'app' &&
              widget.client['status'] == 'active')
            IconButton(
              icon: Icon(Icons.message_outlined,
                  color: theme.brightness == Brightness.light
                      ? Colors.black
                      : Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DirectMessagePage(
                      otherUserId: widget.client['clientId'],
                      otherUserName: widget.client['clientName'],
                      otherUserProfileImageUrl:
                          widget.client['clientProfileImageUrl'],
                      chatType: 'client',
                    ),
                  ),
                );
              },
            ),
          IconButton(
            icon: Icon(Icons.edit_outlined,
                color: theme.brightness == Brightness.light
                    ? Colors.black
                    : Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditClientPage(
                    client: widget.client,
                    isAppUser:
                        widget.client['connectionType'] == 'app' ? true : false,
                    clientInfoEnteredByTrainer:
                        widget.client['connectionType'] == 'app'
                            ? _clientInfoEnteredByTrainer
                            : widget.client,
                  ),
                ),
              ).then((_) {
                // Refresh the data when returning from edit page
                _fetchClientInfoEnteredByTrainer();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.client['connectionType'] == 'app') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CustomTopSelector(
                options: _options,
                selectedIndex: _selectedSectionIndex,
                onOptionSelected: (index) {
                  setState(() {
                    _selectedSectionIndex = index;
                  });
                },
              ),
            ),
            Expanded(
              child: _selectedSectionIndex == 0
                  ? ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ClientProfilePage(
                                        passedClient: _fetchedUserData,
                                        isEnteredByTrainer: true,
                                        passedWidgetClient: widget.client,
                                      )),
                            );
                          },
                          child: _buildProfileSection(),
                        ),
                        const SizedBox(height: 16), // Add some top padding
                        _buildNextSessionCard(),
                        const SizedBox(height: 16),
                        _buildTrackProgressCard(),
                        const SizedBox(height: 16),
                        _buildAssessmentFormCard(),
                        const SizedBox(height: 16),
                        _buildInfoSection(context, l10n.personal_info),
                        const SizedBox(height: 16),
                        _buildInfoSection(
                            context, l10n.health_fitness_client_details),
                        const SizedBox(height: 16),
                        _buildInfoSection(context, l10n.measurements),
                        const SizedBox(height: 16),
                        //_buildBookmarkedExercisesSection(),
                      ],
                    )
                  : _clientInfoEnteredByTrainer == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 48,
                                color: myGrey60,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No client information entered by trainer',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  color: myGrey60,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          children: [
                            _buildProfileSectionByTrainer(),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 0,
                              color: theme.brightness == Brightness.light
                                  ? Colors.white
                                  : myGrey90,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.basic_info,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            theme.textTheme.titleMedium?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoRow(
                                        context,
                                        l10n.name,
                                        _clientInfoEnteredByTrainer![
                                            'clientName']),
                                    _buildInfoRow(context, l10n.email,
                                        _clientInfoEnteredByTrainer!['email']),
                                    _buildInfoRow(context, l10n.phone,
                                        _clientInfoEnteredByTrainer!['phone']),
                                    _buildInfoRow(
                                        context,
                                        l10n.birthday,
                                        _formatBirthday(
                                            _clientInfoEnteredByTrainer![
                                                'birthday'])),
                                    _buildInfoRow(context, l10n.gender,
                                        _clientInfoEnteredByTrainer!['gender']),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 0,
                              color: theme.brightness == Brightness.light
                                  ? Colors.white
                                  : myGrey90,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.body,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            theme.textTheme.titleMedium?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoRow(context, l10n.height,
                                        '${convertedHeightEnteredByTrainer.toStringAsFixed(1)} $myHeightUnit'),
                                    _buildInfoRow(context, l10n.weight,
                                        '${convertedWeightEnteredByTrainer.toStringAsFixed(1)} $myWeightUnit'),
                                    _buildInfoRow(
                                        context,
                                        l10n.current_fitness,
                                        _clientInfoEnteredByTrainer![
                                            'currentFitnessLevel']),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 0,
                              color: theme.brightness == Brightness.light
                                  ? Colors.white
                                  : myGrey90,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.health,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            theme.textTheme.titleMedium?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoRow(context, l10n.fitness_goals,
                                        _clientInfoEnteredByTrainer!['goals']),
                                    _buildInfoRow(
                                        context,
                                        l10n.medical_history,
                                        _clientInfoEnteredByTrainer![
                                            'medicalHistory']),
                                    _buildInfoRow(
                                        context,
                                        l10n.injuries,
                                        _clientInfoEnteredByTrainer![
                                            'injuries']),
                                    _buildInfoRow(
                                        context,
                                        l10n.dietary_habits,
                                        _clientInfoEnteredByTrainer![
                                            'dietaryHabits']),
                                    _buildInfoRow(
                                        context,
                                        l10n.exercise_preferences,
                                        _clientInfoEnteredByTrainer![
                                            'exercisePreferences']),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 0,
                              color: theme.brightness == Brightness.light
                                  ? Colors.white
                                  : myGrey90,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time_rounded,
                                            color: myBlue60),
                                        const SizedBox(width: 8),
                                        Text(
                                          l10n.available_hours,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: theme
                                                .textTheme.titleMedium?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _buildAvailableHoursInfo(
                                        _clientInfoEnteredByTrainer![
                                            'availableHours']),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ] else
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildProfileSection(),
                  const SizedBox(height: 16),
                  _buildNextSessionCard(),
                  const SizedBox(height: 16),
                  _buildTrackProgressCard(),
                  const SizedBox(height: 16),
                  //_buildAssessmentFormCard(),
                  //const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    color: theme.brightness == Brightness.light
                        ? Colors.white
                        : myGrey90,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.basic_info,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.titleMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                              context, l10n.name, widget.client['clientName']),
                          _buildInfoRow(
                              context, l10n.email, widget.client['email']),
                          _buildInfoRow(
                              context, l10n.phone, widget.client['phone']),
                          _buildInfoRow(context, l10n.birthday,
                              _formatBirthday(widget.client['birthday'])),
                          _buildInfoRow(
                              context, l10n.gender, widget.client['gender']),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    color: theme.brightness == Brightness.light
                        ? Colors.white
                        : myGrey90,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.body,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.titleMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(context, l10n.height,
                              '${clientConvertedHeight.toStringAsFixed(1)} $myHeightUnit'),
                          _buildInfoRow(context, l10n.weight,
                              '${clientConvertedWeight.toStringAsFixed(1)} $myWeightUnit'),
                          _buildInfoRow(context, l10n.current_fitness,
                              widget.client['currentFitnessLevel']),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    color: theme.brightness == Brightness.light
                        ? Colors.white
                        : myGrey90,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.health,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.titleMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(context, l10n.fitness_goals,
                              widget.client['goals']),
                          _buildInfoRow(context, l10n.medical_history,
                              widget.client['medicalHistory']),
                          _buildInfoRow(context, l10n.injuries,
                              widget.client['injuries']),
                          _buildInfoRow(context, l10n.dietary_habits,
                              widget.client['dietaryHabits']),
                          _buildInfoRow(context, l10n.exercise_preferences,
                              widget.client['exercisePreferences']),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    color: theme.brightness == Brightness.light
                        ? Colors.white
                        : myGrey90,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  color: myBlue60),
                              const SizedBox(width: 8),
                              Text(
                                l10n.available_hours,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.titleMedium?.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildAvailableHoursInfo(
                              widget.client['availableHours']),
                        ],
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

  Widget _buildProfileSection() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      color: theme.brightness == Brightness.light ? Colors.white : myGrey90,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CustomUserProfileImage(
              imageUrl: widget.client['clientProfileImageUrl'],
              name: widget.client['clientFullName'] ??
                  widget.client['clientName'],
              size: 48,
              borderRadius: 12,
              backgroundColor:
                  theme.brightness == Brightness.light ? myGrey30 : myGrey80,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.client['clientFullName'] ??
                        widget.client['clientName'],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.client['connectionType'] == 'app'
                          ? myBlue60.withOpacity(0.1)
                          : myGrey20,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.client['connectionType'] == 'app'
                          ? l10n.app_user
                          : l10n.manual,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: widget.client['connectionType'] == 'app'
                            ? myBlue60
                            : myGrey60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSectionByTrainer() {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.brightness == Brightness.light ? Colors.white : myGrey90,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CustomUserProfileImage(
              imageUrl:
                  _clientInfoEnteredByTrainer?['clientProfileImageUrl'] ?? '',
              name: _clientInfoEnteredByTrainer?['clientName'] ?? '',
              size: 48,
              borderRadius: 12,
              backgroundColor:
                  theme.brightness == Brightness.light ? myGrey30 : myGrey80,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _clientInfoEnteredByTrainer?['clientName'] ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.titleMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkedExercisesSection() {
    final l10n = AppLocalizations.of(context)!;
    if (_bookmarkedExercises.isEmpty) {
      return Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.bookmark_border, size: 48, color: myGrey60),
                const SizedBox(height: 8),
                Text(
                  l10n.no_bookmarked_exercises,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: myGrey60,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.bookmarked_exercises,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.bookmark,
                  color: myBlue60,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _bookmarkedExercises.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final exercise = _bookmarkedExercises[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: myBlue60.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: myBlue60,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    exercise['name'],
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${exercise['workoutName']}\n${exercise['phaseName']}',
                    style: GoogleFonts.plusJakartaSans(
                      color: myGrey60,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextSessionCard() {
    final l10n = AppLocalizations.of(context)!;
    debugPrint('Building next session card. Next session: $_nextSession');
    if (_nextSession == null) {
      debugPrint('Next session is null, showing no session message');
      return Container(
        //margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Card(
          elevation: 0,
          color: myGrey20,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: myGrey60,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.no_upcoming_sessions,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: myGrey60,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final sessionDateTime =
        (_nextSession!['sessionDate'] as Timestamp).toDate();
    var formattedMonth = DateFormat('MMM').format(sessionDateTime);

    switch (formattedMonth) {
      case 'Jan':
        formattedMonth = l10n.january_date;
      case 'Feb':
        formattedMonth = l10n.february_date;
      case 'Mar':
        formattedMonth = l10n.march_date;
      case 'Apr':
        formattedMonth = l10n.april_date;
      case 'May':
        formattedMonth = l10n.may_date;
      case 'Jun':
        formattedMonth = l10n.june_date;
      case 'Jul':
        formattedMonth = l10n.july_date;
      case 'Aug':
        formattedMonth = l10n.august_date;
      case 'Sep':
        formattedMonth = l10n.september_date;
      case 'Oct':
        formattedMonth = l10n.october_date;
      case 'Nov':
        formattedMonth = l10n.november_date;
      case 'Dec':
        formattedMonth = l10n.december_date;
      default:
        formattedMonth = formattedMonth;
    }

    final formattedDate =
        '$formattedMonth ${sessionDateTime.day}, ${sessionDateTime.year}';
    final formattedTime = DateFormat('HH:mm').format(sessionDateTime);
    debugPrint('Formatted date and time: $formattedDate at $formattedTime');

    return Container(
      //margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Card(
        elevation: 0,
        color: myBlue60.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClientAllSessionsPage(
                  clientId: widget.client['clientId'],
                  nextSession: _nextSession,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: myBlue60.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: myBlue60,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.next_session_only_string,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: myBlue60,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$formattedDate  @$formattedTime',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: myBlue60,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: myBlue60,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackProgressCard() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          final consentSettings = widget.client['connectionType'] == 'app' &&
                  _fetchedUserData != null
              ? _fetchedUserData!['dataConsent'] ??
                  {
                    'birthday': false,
                    'email': false,
                    'phone': false,
                    'location': false,
                    'measurements': false,
                    'progressPhotos': false,
                    'socialMedia': false,
                  }
              : {
                  'birthday': true,
                  'email': true,
                  'phone': true,
                  'location': true,
                  'measurements': true,
                  'progressPhotos': true,
                  'socialMedia': true,
                };

          debugPrint(
              'Passed height: ${_toDouble(_fetchedUserData?['height'])}');
          debugPrint(
              'Passed weight: ${_toDouble(_fetchedUserData?['weight'])}');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProgressPage(
                isEnteredByTrainer: true,
                passedClientForTrainer: widget.client,
                passedConsentSettingsForTrainer: consentSettings,
                passedHeight: _toDouble(_fetchedUserData?['height']),
                passedWeight: _toDouble(_fetchedUserData?['weight']),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.light
                      ? myBlue60.withOpacity(0.1)
                      : myGrey80,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: theme.brightness == Brightness.light
                      ? myBlue60
                      : myGrey40,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.track_client_progress,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      l10n.track_progress_subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.brightness == Brightness.light
                            ? myGrey60
                            : myGrey40,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color:
                    theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssessmentFormCard() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _latestAssessmentForm?['status'] == 'completed'
              ? myTeal40
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssessmentFormPage(
                clientId: widget.client['clientId'],
                clientName: widget.client['clientName'],
                isEnteredByTrainer: true,
                existingForm: _latestAssessmentForm,
              ),
            ),
          ).then((_) {
            // Refresh the form data when returning from AssessmentFormPage
            _fetchLatestAssessmentForm();
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _latestAssessmentForm?['status'] == 'completed'
                      ? myTeal40.withOpacity(0.1)
                      : theme.brightness == Brightness.light
                          ? myBlue60.withOpacity(0.1)
                          : myGrey80,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  color: _latestAssessmentForm?['status'] == 'completed'
                      ? myTeal40
                      : theme.brightness == Brightness.light
                          ? myBlue60
                          : myGrey40,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.assessment_form,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      l10n.assessment_form_subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.brightness == Brightness.light
                            ? myGrey60
                            : myGrey40,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: _latestAssessmentForm?['status'] == 'completed'
                    ? myTeal40
                    : theme.brightness == Brightness.light
                        ? myBlue60
                        : myGrey40,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to safely convert to double
  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Add this helper method to format available hours
  Widget _buildAvailableHoursInfo(Map<String, dynamic>? availableHours) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (availableHours == null || availableHours.isEmpty) {
      return Text(
        l10n.no_availability_set,
        style: GoogleFonts.plusJakartaSans(
          color: myGrey60,
        ),
      );
    }

    final orderedDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hoursData = availableHours['availableHours'] as Map<String, dynamic>;

    String formatTimeString(String timeStr) {
      // Split the time string into hours and minutes
      final parts = timeStr.split(':');
      if (parts.length != 2) return timeStr;

      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;

      // Create a DateTime object for today with the given hours and minutes
      final time = DateTime(2024, 1, 1, hours, minutes);

      // Get user's time format preference
      final userData = context.read<UserProvider>().userData;
      final is24Hour = userData?['timeFormat'] == '24-hour';

      // Format the time based on preference
      final timeFormat = is24Hour ? 'HH:mm' : 'h:mm a';
      return DateFormat(timeFormat).format(time);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: orderedDays.map((day) {
        final slots = hoursData[day] as List? ?? [];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  _getDayName(day),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.brightness == Brightness.light
                        ? myGrey90
                        : Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: slots.isEmpty
                    ? Text(
                        l10n.not_available,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.brightness == Brightness.light
                              ? myGrey60
                              : myGrey40,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: slots.map<Widget>((slot) {
                          final timeSlot = slot as Map<String, dynamic>;
                          final startTime =
                              formatTimeString(timeSlot['start'].toString());
                          final endTime =
                              formatTimeString(timeSlot['end'].toString());
                          return Text(
                            '$startTime - $endTime',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.brightness == Brightness.light
                                  ? myGrey60
                                  : Colors.white70,
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getDayName(String shortDay) {
    final l10n = AppLocalizations.of(context)!;
    switch (shortDay) {
      case 'Mon':
        return l10n.monday;
      case 'Tue':
        return l10n.tuesday;
      case 'Wed':
        return l10n.wednesday;
      case 'Thu':
        return l10n.thursday;
      case 'Fri':
        return l10n.friday;
      case 'Sat':
        return l10n.saturday;
      case 'Sun':
        return l10n.sunday;
      default:
        return shortDay;
    }
  }
}
