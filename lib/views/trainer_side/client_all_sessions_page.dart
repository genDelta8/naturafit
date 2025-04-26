import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/auth/bloc/data_fetch_service.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/views/trainer_side/schedule_session_page.dart';
import 'package:naturafit/views/trainer_side/session_details_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ClientAllSessionsPage extends StatefulWidget {
  final String clientId;
  final Map<String, dynamic>? nextSession;

  const ClientAllSessionsPage({
    super.key,
    required this.clientId,
    this.nextSession,
  });

  @override
  State<ClientAllSessionsPage> createState() => _ClientAllSessionsPageState();
}

class _ClientAllSessionsPageState extends State<ClientAllSessionsPage> {
  late DateTime _weekStartDate;
  late DateTime _selectedDate;
  late List<DateTime> _weekDates;
  bool _isLoading = false;
  List<Map<String, dynamic>> _currentWeekSessions = [];
  Timer? _countdownTimer;

  // Add a cache map to store fetched data by week
  final Map<String, List<Map<String, dynamic>>> _weeklyDataCache = {};

  // Helper method to get cache key for a week
  String _getWeekCacheKey(DateTime weekStart) {
    return DateFormat('yyyy-MM-dd').format(weekStart);
  }

  @override
  void initState() {
    super.initState();
    _initializeWeek();
    // Start the countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchWeekSessions());
  }

  void _initializeWeek() {
    // Start from today
    final now = DateTime.now();
    _selectedDate = now;

    // Find the start of the week (Monday) at 00:00
    _weekStartDate = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
      0, // hour
      0, // minute
      0, // second
    );
    _generateWeekDates();
  }

  void _generateWeekDates() {
    _weekDates = List.generate(7, (index) {
      return _weekStartDate.add(Duration(days: index));
    });
  }

  Future<void> _fetchWeekSessions() async {
    if (_isLoading) return;

    final weekKey = _getWeekCacheKey(_weekStartDate);

    // Check if we already have data for this week in cache
    if (_weeklyDataCache.containsKey(weekKey)) {
      setState(() {
        _currentWeekSessions = _weeklyDataCache[weekKey]!;
      });
      debugPrint('Using cached data for week: $weekKey');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Calculate end of week (next Monday at 00:00)
      final weekEndDate = _weekStartDate.add(const Duration(days: 7));

      debugPrint(
          'Fetching sessions from: ${_weekStartDate.toString()} to ${weekEndDate.toString()}');

      final snapshot = await FirebaseFirestore.instance
          .collection('client_sessions')
          .doc(widget.clientId)
          .collection('allClientSessions')
          .where('sessionDate', isGreaterThanOrEqualTo: _weekStartDate)
          .where('sessionDate', isLessThan: weekEndDate)
          .orderBy('sessionDate')
          .get();

      final sessions = snapshot.docs.map((doc) => doc.data()).toList();

      // Store in cache
      _weeklyDataCache[weekKey] = sessions;

      setState(() {
        _currentWeekSessions = sessions;
      });
      debugPrint(
          'Fetched and cached ${sessions.length} sessions for week: $weekKey');
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Add method to clear cache when needed
  void _clearCache() {
    _weeklyDataCache.clear();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _clearCache(); // Clear cache when disposing the page
    super.dispose();
  }

  void _navigateWeek(int direction) {
    setState(() {
      _weekStartDate = _weekStartDate.add(Duration(days: 7 * direction));
      _generateWeekDates();
      _selectedDate = _weekDates[0]; // Select first day of new week
    });
    _fetchWeekSessions();
  }

  List<Map<String, dynamic>> _getSessionsForDate(DateTime date) {
    return _currentWeekSessions.where((session) {
      final sessionDate = (session['sessionDate'] as Timestamp).toDate();
      return sessionDate.year == date.year &&
          sessionDate.month == date.month &&
          sessionDate.day == date.day;
    }).toList();
  }

  String _formatCountdown(Duration difference) {
    if (difference.isNegative) {
      return 'Starting soon';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m ${seconds}s';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else {
      return '${minutes}m ${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final weekStats = _getWeekStats();
    final height = MediaQuery.of(context).size.height;
    final isSmallHeight = height < 550;

    if (widget.nextSession == null) {
      return Center(
        child: Text(
          l10n.no_upcoming_sessions,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final session = widget.nextSession;
    final sessionDate = (session?['sessionDate'] as Timestamp).toDate();
    final now = DateTime.now();
    final difference = sessionDate.difference(now);

    String countdownText;
    if (difference.isNegative) {
      countdownText = l10n.starting_soon;
    } else {
      final days = difference.inDays;
      final hours = difference.inHours % 24;
      final minutes = difference.inMinutes % 60;
      final seconds = difference.inSeconds % 60;
      countdownText = l10n.time_remaining(days, hours, minutes, seconds);
    }

    var formattedMonth = DateFormat('MMMM').format(_selectedDate);
    switch (formattedMonth) {
      case 'January':
        formattedMonth = l10n.january;
      case 'February':
        formattedMonth = l10n.february;
      case 'March':
        formattedMonth = l10n.march;
      case 'April':
        formattedMonth = l10n.april;
      case 'May':
        formattedMonth = l10n.may;
      case 'June':
        formattedMonth = l10n.june;
      case 'July':
        formattedMonth = l10n.july;
      case 'August':
        formattedMonth = l10n.august;
      case 'September':
        formattedMonth = l10n.september;
      case 'October':
        formattedMonth = l10n.october;
      case 'November':
        formattedMonth = l10n.november;
      case 'December':
        formattedMonth = l10n.december;
      default:
        formattedMonth = formattedMonth;
    }

    final formattedDate =
        '$formattedMonth ${_selectedDate.day}, ${_selectedDate.year}';

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
          l10n.all_sessions,
          style: GoogleFonts.plusJakartaSans(
            color: theme.brightness == Brightness.light
                ? Colors.black
                : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        height: 120,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.light
                              ? myGrey80
                              : myGrey90,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    l10n.next_available_session,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 0),
                                  Text(
                                    countdownText,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SessionDetailsPage(
                                            sessionId: session?['sessionId'],
                                            trainerId:
                                                session?['professionalId'],
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
                                          debugPrint(
                                              'Refreshing professional slots');
                                          await DataFetchService()
                                              .fetchProfessionalSlots(
                                                  session?['professionalId'],
                                                  'trainer',
                                                  context.read<UserProvider>());
                                        }
                                        _clearCache();
                                        _fetchWeekSessions();
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: myBlue60,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        l10n.learn_more,
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${l10n.confirmed} ',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          color: myBlue50,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '${weekStats['confirmed']}',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '${l10n.pending_plans} ',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          color: myYellow40,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '${weekStats['pending']}',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '${l10n.recurring} ',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          color: myTeal30,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '${weekStats['recurring']}',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '${l10n.availabale_slots_week_stats_requested} ',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          color: myRed40,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '${weekStats['requested']}',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildWeekNavigator(theme),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        formattedDate,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: isSmallHeight ? height - 300 : height - 380,
                  padding: const EdgeInsets.only(bottom: 88),
                  child: ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      ..._getSessionsForDate(_selectedDate)
                          .map((session) => _buildSessionCard(context, session))
                          .toList(),
                      if (_getSessionsForDate(_selectedDate).isEmpty)
                        _buildEmptyState(theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Position FAB at the bottom
          if (!isSmallHeight)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScheduleSessionPage(
                          initialScheduleType: 'existing_client',
                          preSelectedClientId: widget.clientId,
                          initialSessionCategory: l10n.assessment,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: myBlue30,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: myBlue60,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      height: 72,
                      width: 72,
                      child:
                          const Icon(Icons.add, size: 32, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeekNavigator(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    var formattedMonthFirst = DateFormat('MMM').format(_weekDates.first);
    var formattedMonthLast = DateFormat('MMM').format(_weekDates.last);

    switch (formattedMonthFirst) {
      case 'Jan':
        formattedMonthFirst = l10n.january_date;
      case 'Feb':
        formattedMonthFirst = l10n.february_date;
      case 'Mar':
        formattedMonthFirst = l10n.march_date;
      case 'Apr':
        formattedMonthFirst = l10n.april_date;
      case 'May':
        formattedMonthFirst = l10n.may_date;
      case 'Jun':
        formattedMonthFirst = l10n.june_date;
      case 'Jul':
        formattedMonthFirst = l10n.july_date;
      case 'Aug':
        formattedMonthFirst = l10n.august_date;
      case 'Sep':
        formattedMonthFirst = l10n.september_date;
      case 'Oct':
        formattedMonthFirst = l10n.october_date;
      case 'Nov':
        formattedMonthFirst = l10n.november_date;
      case 'Dec':
        formattedMonthFirst = l10n.december_date;
      default:
        formattedMonthFirst = formattedMonthFirst;
    }

    switch (formattedMonthLast) {
      case 'Jan':
        formattedMonthLast = l10n.january_date;
      case 'Feb':
        formattedMonthLast = l10n.february_date;
      case 'Mar':
        formattedMonthLast = l10n.march_date;
      case 'Apr':
        formattedMonthLast = l10n.april_date;
      case 'May':
        formattedMonthLast = l10n.may_date;
      case 'Jun':
        formattedMonthLast = l10n.june_date;
      case 'Jul':
        formattedMonthLast = l10n.july_date;
      case 'Aug':
        formattedMonthLast = l10n.august_date;
      case 'Sep':
        formattedMonthLast = l10n.september_date;
      case 'Oct':
        formattedMonthLast = l10n.october_date;
      case 'Nov':
        formattedMonthLast = l10n.november_date;
      case 'Dec':
        formattedMonthLast = l10n.december_date;
      default:
        formattedMonthLast = formattedMonthLast;
    }
    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 800,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left,
                      color: theme.brightness == Brightness.light
                          ? Colors.black
                          : Colors.white),
                  onPressed: () => _navigateWeek(-1),
                ),
                Text(
                  '$formattedMonthFirst - $formattedMonthLast',
                  style: GoogleFonts.plusJakartaSans(
                    color: theme.brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right,
                      color: theme.brightness == Brightness.light
                          ? Colors.black
                          : Colors.white),
                  onPressed: () => _navigateWeek(1),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildWeekView(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, Map<String, dynamic> session) {
    final isGroup = session['isGroupSession'] ?? false;
    final sessionDate = (session['sessionDate'] as Timestamp).toDate();
    //final formattedDate = DateFormat('E, MMM d').format(sessionDate);
    var formattedThreeLettersDay = DateFormat('E').format(sessionDate);
    var formattedThreeLettersMonth = DateFormat('MMM').format(sessionDate);
    final formattedDayOfMonth = DateFormat('d').format(sessionDate);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    switch (formattedThreeLettersDay) {
      case 'Mon':
        formattedThreeLettersDay = l10n.monday_date;
      case 'Tue':
        formattedThreeLettersDay = l10n.tuesday_date;
      case 'Wed':
        formattedThreeLettersDay = l10n.wednesday_date;
      case 'Thu':
        formattedThreeLettersDay = l10n.thursday_date;
      case 'Fri':
        formattedThreeLettersDay = l10n.friday_date;
      case 'Sat':
        formattedThreeLettersDay = l10n.saturday_date;
      case 'Sun':
        formattedThreeLettersDay = l10n.sunday_date;
      default:
        formattedThreeLettersDay = formattedThreeLettersDay;
    }

    switch (formattedThreeLettersMonth) {
      case 'Jan':
        formattedThreeLettersMonth = l10n.january_date;
      case 'Feb':
        formattedThreeLettersMonth = l10n.february_date;
      case 'Mar':
        formattedThreeLettersMonth = l10n.march_date;
      case 'Apr':
        formattedThreeLettersMonth = l10n.april_date;
      case 'May':
        formattedThreeLettersMonth = l10n.may_date;
      case 'Jun':
        formattedThreeLettersMonth = l10n.june_date;
      case 'Jul':
        formattedThreeLettersMonth = l10n.july_date;
      case 'Aug':
        formattedThreeLettersMonth = l10n.august_date;
      case 'Sep':
        formattedThreeLettersMonth = l10n.september_date;
      case 'Oct':
        formattedThreeLettersMonth = l10n.october_date;
      case 'Nov':
        formattedThreeLettersMonth = l10n.november_date;
      case 'Dec':
        formattedThreeLettersMonth = l10n.december_date;
      default:
        formattedThreeLettersMonth = formattedThreeLettersMonth;
    }

    final formattedDate =
        '$formattedThreeLettersDay, $formattedThreeLettersMonth $formattedDayOfMonth';

    // Get trainer info with proper field names matching the database
    final String trainerName =
        session['professionalFullname']?.toString().isNotEmpty == true
            ? session['professionalFullname']
            : session['professionalUsername'] ?? 'Coach';
    final String? trainerProfileImageUrl =
        session['professionalProfileImageUrl'];

    // Get initial for avatar - safely handle empty strings
    final String trainerInitial =
        trainerName.isNotEmpty ? trainerName[0].toUpperCase() : 'C';

    final now = DateTime.now();
    final isPast = sessionDate.isBefore(now);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.brightness == Brightness.light ? Colors.white : myGrey90,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SessionDetailsPage(
                      sessionId: session['sessionId'],
                      trainerId: session['professionalId'],
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
                        session['professionalId'],
                        'trainer',
                        context.read<UserProvider>());
                  }
                  _clearCache();
                  _fetchWeekSessions();
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    if (isGroup)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.light
                              ? myGrey30
                              : myGrey80,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.groups,
                          color: theme.brightness == Brightness.light
                              ? Colors.white
                              : myGrey60,
                        ),
                      )
                    else if (trainerProfileImageUrl != null &&
                        trainerProfileImageUrl != 'null' &&
                        trainerProfileImageUrl != '')
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: trainerProfileImageUrl
                                  .toString()
                                  .startsWith('assets/')
                              ? myAvatarBackground
                              : theme.brightness == Brightness.light
                                  ? Colors.white
                                  : myGrey80,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: trainerProfileImageUrl
                                  .toString()
                                  .startsWith('assets/')
                              ? Image.asset(
                                  trainerProfileImageUrl,
                                  fit: BoxFit.cover,
                                )
                              : CachedNetworkImage(
                                  imageUrl: trainerProfileImageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: myGrey20,
                                    child: const Center(
                                      child: CircularProgressIndicator(color: myGrey30),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: myGrey20,
                                    child: const Icon(Icons.person_outline, color: myGrey60),
                                  ),
                                ),
                        ),
                      )
                    else
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: myGrey30,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            trainerInitial,
                            style: GoogleFonts.plusJakartaSans(
                              color: theme.brightness == Brightness.light
                                  ? Colors.white
                                  : myGrey60,
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isGroup ? 'Group Session' : trainerName,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              color: theme.brightness == Brightness.light
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: theme.brightness == Brightness.light
                                    ? myGrey60
                                    : myGrey40,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$formattedDate  @${session['time']}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: theme.brightness == Brightness.light
                                      ? myGrey60
                                      : myGrey40,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            session['sessionCategory'] ?? l10n.training_session,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: theme.brightness == Brightness.light
                                  ? myGrey60
                                  : myGrey40,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: getStatusColor(isGroup, session['status'],
                            isPast)['backgroundColor'],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isGroup
                            ? 'GROUP'
                            : (session['status'] ?? 'PENDING').toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: getStatusColor(
                              isGroup, session['status'], isPast)['textColor'],
                          fontWeight: FontWeight.w500,
                          //letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, Color> getStatusColor(bool isGroup, String? status, bool isPast) {
    /*
    if (isGroup) {
      return {
        'backgroundColor': isPast ? myGrey30 : myPurple60,
        'textColor': Colors.white,
      };
    }
    */

    switch (status?.toLowerCase()) {
      case 'group':
        return {
          'backgroundColor': isPast ? myGrey30 : myPurple60,
          'textColor': Colors.white,
        };
      case 'requested':
        return {
          'backgroundColor': isPast ? myGrey30 : myRed40,
          'textColor': Colors.white,
        };
      case fbClientConfirmedStatus:
      case fbCreatedStatusForNotAppUser:
        return {
          'backgroundColor': isPast ? myGrey30 : myGreen50,
          'textColor': Colors.white,
        };
      case fbCreatedStatusForAppUser:
        return {
          'backgroundColor': isPast ? myGrey30 : myYellow50,
          'textColor': Colors.white,
        };
      default:
        return {
          'backgroundColor': isPast ? myGrey30 : myYellow50,
          'textColor': Colors.white,
        };
    }
  }

  Widget _buildWeekView(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _weekDates.map((date) {
        bool isSelected = date.day == _selectedDate.day;
        bool hasSlots = _getSessionsForDate(date).isNotEmpty;

        final l10n = AppLocalizations.of(context)!;
        var formattedDate = DateFormat('E').format(date);
        switch (formattedDate) {
          case 'Mon':
            formattedDate = l10n.monday;
          case 'Tue':
            formattedDate = l10n.tuesday;
          case 'Wed':
            formattedDate = l10n.wednesday;
          case 'Thu':
            formattedDate = l10n.thursday;
          case 'Fri':
            formattedDate = l10n.friday;
          case 'Sat':
            formattedDate = l10n.saturday;
          case 'Sun':
            formattedDate = l10n.sunday;
          default:
            formattedDate = formattedDate;
        }

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? myBlue30 : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              width: 45,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? myBlue60
                    : theme.brightness == Brightness.light
                        ? Colors.white
                        : myGrey80,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: myGrey20, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formattedDate.substring(0, 1),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white
                          : theme.brightness == Brightness.light
                              ? Colors.black
                              : Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : theme.brightness == Brightness.light
                              ? Colors.black
                              : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasSlots
                          ? (isSelected
                              ? Colors.white
                              : theme.brightness == Brightness.light
                                  ? myGrey30
                                  : myGrey70)
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.brightness == Brightness.light
              ? Colors.grey.shade200
              : Colors.grey.shade800,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy,
            size: 48,
            color: theme.brightness == Brightness.light
                ? Colors.grey[400]
                : Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No Slots',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the "+" button\nto create a new slot for this day',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Map<String, int> _getWeekStats() {
    final slots = _currentWeekSessions;
    int confirmed = 0;
    int pending = 0;
    int recurring = 0;
    int past = 0;
    int requested = 0;

    final now = DateTime.now();

    for (var slot in slots) {
      final slotDate = (slot['sessionDate'] as Timestamp).toDate();
      final isPast = slotDate.isBefore(now);

      if (isPast) {
        past++;
      } else if (slot['status'] == 'confirmed') {
        confirmed++;
        if (slot['isRecurring'] == true) {
          recurring++;
        }
      } else if (slot['status'] == 'pending') {
        pending++;
        if (slot['isRecurring'] == true) {
          recurring++;
        }
      } else if (slot['status'] == 'requested') {
        requested++;
        if (slot['isRecurring'] == true) {
          recurring++;
        }
      }
    }

    return {
      'confirmed': confirmed,
      'pending': pending,
      'recurring': recurring,
      'past': past,
      'requested': requested,
    };
  }
}
