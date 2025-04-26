import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/auth/bloc/data_fetch_service.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/views/trainer_side/schedule_session_page.dart';
import 'package:naturafit/views/trainer_side/session_details_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AvailableSlotsPage extends StatefulWidget {
  const AvailableSlotsPage({super.key});

  @override
  State<AvailableSlotsPage> createState() => _AvailableSlotsPageState();
}

class _AvailableSlotsPageState extends State<AvailableSlotsPage>
    with SingleTickerProviderStateMixin {
  late DateTime _weekStartDate;
  late DateTime _selectedDate;
  late List<DateTime> _weekDates;
  bool _isLoading = false;

  // Add animation controller
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  // Add a cache map to store fetched data by week
  final Map<String, List<Map<String, dynamic>>> _weeklyDataCache = {};

  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _blinkAnimation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(_blinkController);

    _blinkController.repeat(reverse: true);

    _initializeWeek();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });

    // Delay fetching slots and next available session until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchWeekSlots();

        _fetchTrainerNextAvailableSession();
      }
    });
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

  Future<void> _fetchWeekSlots() async {
    if (_isLoading) return;

    final weekKey = _getWeekCacheKey(_weekStartDate);

    // Check if we already have data for this week in cache
    if (_weeklyDataCache.containsKey(weekKey)) {
      final userProvider = context.read<UserProvider>();
      userProvider.setCurrentWeekAvailableSlots(_weeklyDataCache[weekKey]!);
      debugPrint('Using cached data for week: $weekKey');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = context.read<UserProvider>();
      final userData = userProvider.userData;
      if (userData == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Calculate end of week (next Monday at 00:00)
      final weekEndDate = _weekStartDate.add(const Duration(days: 7));

      debugPrint(
          'Fetching slots from: ${_weekStartDate.toString()} to ${weekEndDate.toString()}');

      final snapshot = await FirebaseFirestore.instance
          .collection('trainer_sessions')
          .doc(userData['userId'])
          .collection('allTrainerSessions')
          .where('sessionDate', isGreaterThanOrEqualTo: _weekStartDate)
          .where('sessionDate', isLessThan: weekEndDate)
          .where('status',
              whereIn: ['available', 'group', 'pending', 'requested'])
          .orderBy('sessionDate')
          .get();

      if (!mounted) return;

      final slots = snapshot.docs
          .map((doc) => doc.data())
          .where((slot) =>
              slot['status'] == 'available' ||
              slot['scheduleType'] == 'group' ||
              slot['status'] == 'requested')
          .toList();

      // Store in cache
      _weeklyDataCache[weekKey] = slots;

      if (mounted) {
        userProvider.setCurrentWeekAvailableSlots(slots);
      }

      debugPrint(
          'Fetched and cached ${slots.length} available/group slots for week: $weekKey');
    } catch (e) {
      debugPrint('Error fetching slots: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Add method to clear cache when needed (e.g., when creating/updating slots)
  void _clearCache() {
    _weeklyDataCache.clear();
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _countdownTimer?.cancel();
    _clearCache(); // Clear cache when disposing the page
    super.dispose();
  }

  void _navigateWeek(int direction) {
    setState(() {
      _weekStartDate = _weekStartDate.add(Duration(days: 7 * direction));
      _generateWeekDates();
      // Only set _selectedDate if _weekDates is not empty
      if (_weekDates.isNotEmpty) {
        _selectedDate = _weekDates[0];
      }
    });
    _fetchWeekSlots();
  }

  List<Map<String, dynamic>> _getSlotsForDate(DateTime date) {
    try {
      final slots = context.watch<UserProvider>().currentWeekAvailableSlots;
      if (slots == null || slots.isEmpty) {
        debugPrint('No slots available for date: ${date.toString()}');
        return [];
      }

      return slots.where((slot) {
        try {
          if (slot == null || slot['sessionDate'] == null) {
            debugPrint('Invalid slot data found');
            return false;
          }

          final slotDate = (slot['sessionDate'] as Timestamp).toDate();
          final isMatchingDay = isSameDay(slotDate, date);
          final isValidStatus = slot['status'] == 'available' ||
              slot['scheduleType'] == 'group' ||
              slot['status'] == 'requested';

          return isValidStatus && isMatchingDay;
        } catch (e) {
          debugPrint('Error processing slot: $e');
          return false;
        }
      }).toList();
    } catch (e) {
      debugPrint('Error getting slots for date: $e');
      return [];
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Map<String, int> _getWeekStats() {
    final slots = context.watch<UserProvider>().currentWeekAvailableSlots ?? [];
    int available = 0;
    int recurring = 0;
    int oneTime = 0;
    int group = 0;
    int requested = 0;
    for (var slot in slots) {
      // Count available slots and all group sessions
      if (slot['status'] == 'requested') {
        requested++;
        if (slot['isRecurring'] == true) {
          recurring++;
        } else {
          oneTime++;
        }
      }

      if (slot['status'] == 'available') {
        available++;
        if (slot['isRecurring'] == true) {
          recurring++;
        } else {
          oneTime++;
        }
      }
      if (slot['isGroupSession'] == true) {
        group++;
        if (slot['isRecurring'] == true) {
          recurring++;
        } else {
          oneTime++;
        }
      }
    }

    return {
      'available': available,
      'recurring': recurring,
      'oneTime': oneTime,
      'group': group,
      'requested': requested,
    };
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

  Future<void> _fetchTrainerNextAvailableSession() async {
    // Get user data and fetch next available session
    final userProvider = context.read<UserProvider>();
    final userData = userProvider.userData;
    if (userData == null) {
      return;
    }
    final userId = userData['userId'];
    try {
      final now = DateTime.now();

      final nextAvailableSessionSnapshot = await FirebaseFirestore.instance
          .collection('trainer_sessions')
          .doc(userId)
          .collection('allTrainerSessions')
          .where('sessionDate', isGreaterThanOrEqualTo: now)
          .where('status', whereIn: ['available', 'group'])
          .orderBy('sessionDate')
          .limit(1)
          .get();

      if (nextAvailableSessionSnapshot.docs.isNotEmpty) {
        final nextAvailableSession =
            nextAvailableSessionSnapshot.docs.first.data();
        userProvider.setTrainerNextAvailableSession(nextAvailableSession);
        debugPrint(
            'Next available trainer session found: ${nextAvailableSession['sessionDate']}');
      } else {
        userProvider.setTrainerNextAvailableSession(null);
        debugPrint('No upcoming available sessions found for trainer');
      }
    } catch (e) {
      debugPrint('Error fetching next available trainer session: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekStats = _getWeekStats();
    final l10n = AppLocalizations.of(context)!;

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

    final height = MediaQuery.of(context).size.height;
    final isSmallHeight = height < 550;

    final myIsWebOrDektop = isWebOrDesktopCached;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: myIsWebOrDektop
            ? const SizedBox.shrink()
            : Container(
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
          l10n.available_slots,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: myIsWebOrDektop ? false : true,
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
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
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
                        child: Consumer<UserProvider>(
                          builder: (context, userProvider, child) {
                            return _buildNextAvailableSessionInfo(
                                userProvider, theme, l10n, weekStats);
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildWeekNavigator(theme),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const SizedBox(width: 16),
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
                Container(
                  height: isSmallHeight ? height - 300 : height - 380,
                  padding: const EdgeInsets.only(bottom: 88),
                  child: ListView(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    children: [
                      const SizedBox(height: 16),
                      ..._getSlotsForDate(_selectedDate)
                          .map((slot) => _buildSlotCard(slot, theme))
                          .toList(),
                      if (_getSlotsForDate(_selectedDate).isEmpty)
                        _buildEmptyState(theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isSmallHeight)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScheduleSessionPage(
                          initialScheduleType: 'available_slot',
                          initialSessionCategory: l10n.assessment,
                        ),
                      ),
                    );
                    debugPrint('Result: $result');

                    if (result != null && result is Map<String, dynamic>) {
                      _handleNewSession(result);
                    }
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
    final myIsWebOrDektop = isWebOrDesktopCached;

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

    return Column(
      children: [
        Row(
          mainAxisAlignment: myIsWebOrDektop
              ? MainAxisAlignment.center
              : MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left,
                  color: theme.brightness == Brightness.light
                      ? Colors.black
                      : Colors.white),
              onPressed: () => _navigateWeek(-1),
            ),
            if (myIsWebOrDektop) const SizedBox(width: 32),
            Text(
              '$formattedMonthFirst - $formattedMonthLast',
              style: GoogleFonts.plusJakartaSans(
                color: theme.brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (myIsWebOrDektop) const SizedBox(width: 32),
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
    );
  }

  Widget _buildNextAvailableSessionInfo(UserProvider userProvider,
      ThemeData theme, AppLocalizations l10n, Map<String, int> weekStats) {
    final nextAvailableSession = userProvider.trainerNextAvailableSession;

    if (nextAvailableSession == null) {
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

    try {
      final sessionDate =
          (nextAvailableSession['sessionDate'] as Timestamp?)?.toDate();
      if (sessionDate == null) {
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

      final now = DateTime.now();
      final difference = sessionDate.difference(now);
      final countdownText = _formatCountdown(difference);

      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.your_next_available_session_in,
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
                        builder: (context) => SessionDetailsPage(
                          sessionId: nextAvailableSession['sessionId'],
                          trainerId: userProvider.userData?['userId'],
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
                            userProvider.userData?['userId'],
                            'trainer',
                            context.read<UserProvider>());
                      }
                      _clearCache();
                      _fetchWeekSlots();
                      _fetchTrainerNextAvailableSession();
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: myBlue60,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.learn_more,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
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
                    '${l10n.availabale_slots_week_stats_available} ',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        color: myBlue50,
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${weekStats['available']}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${l10n.availabale_slots_week_stats_group} ',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        color: myPurple40,
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${weekStats['group']}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${l10n.availabale_slots_week_stats_recurring} ',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        color: myTeal30,
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${weekStats['recurring']}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
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
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    } catch (e) {
      debugPrint('Error building next available session info: $e');
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
  }

  Widget _buildSlotCard(Map<String, dynamic> slot, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final sessionDate = (slot['sessionDate'] as Timestamp).toDate();
    final isPast = sessionDate.isBefore(DateTime.now());
    final isGroupSession = slot['isGroupSession'] == true;
    final isRequested = slot['status'] == 'requested';

    // Get user's time format preference
    final userProvider = context.read<UserProvider>();
    final userData = userProvider.userData;
    final timePreference = userData?['timeFormat'] as String? ?? '24-hour';

    // Format time based on user preference
    String timeString;
    String meridiem = '';

    if (timePreference == '24-hour') {
      timeString = DateFormat('HH:mm').format(sessionDate);
    } else {
      timeString = DateFormat('h:mm').format(sessionDate);
      meridiem = DateFormat('a').format(sessionDate); // AM/PM
    }

    final groupSize = (slot['clients'] as List?)?.length ?? 0;

    final statusTag = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isPast
            ? myGrey30
            : isGroupSession
                ? myPurple60
                : (slot['status'] == 'requested'
                    ? myRed40
                    : (slot['isRecurring'] == true ? myBlue60 : myGreen50)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isGroupSession
            ? l10n.group
            : (slot['status'] == 'requested'
                ? l10n.requested
                : (slot['isRecurring'] == true
                    ? l10n.recurring
                    : l10n.available_capital)),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        ),
      ),
    );

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () async {
              final userData = context.read<UserProvider>().userData;
              if (userData == null) return;

              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SessionDetailsPage(
                    sessionId: slot['sessionId'],
                    trainerId: userData['userId'],
                  ),
                ),
              );

              // Handle deletion, cancellation, or edit result
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
                            userProvider.userData?['userId'],
                            'trainer',
                            context.read<UserProvider>());
                      }
                _clearCache();
                _fetchWeekSlots();
                _fetchTrainerNextAvailableSession();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Time column
                  Column(
                    children: [
                      Text(
                        timeString,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.brightness == Brightness.light
                              ? Colors.black87
                              : Colors.white,
                        ),
                      ),
                      if (timePreference != '24-hour')
                        Text(
                          meridiem,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: theme.brightness == Brightness.light
                                ? myGrey60
                                : myGrey40,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Session type icon
                  if (isGroupSession)
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
                  else
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
                        Icons.person,
                        color: theme.brightness == Brightness.light
                            ? Colors.white
                            : myGrey60,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGroupSession
                              ? 'Group Session${groupSize > 0 ? ' ($groupSize)' : ''}'
                              : 'Available Slot',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                            color: theme.brightness == Brightness.light
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          slot['sessionCategory'] ?? '1:1 Training',
                          style: theme.textTheme.bodySmall?.copyWith(
                            letterSpacing: -0.2,
                            color: theme.brightness == Brightness.light
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isRequested && !isPast)
                    FadeTransition(
                      opacity: _blinkAnimation,
                      child: statusTag,
                    )
                  else
                    statusTag,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekView(ThemeData theme) {
    if (_weekDates.isEmpty) {
      debugPrint('Warning: _weekDates is empty');
      _generateWeekDates(); // Regenerate dates if empty
    }
    final myIsWebOrDektop = isWebOrDesktopCached;

    return Row(
      mainAxisAlignment: myIsWebOrDektop
          ? MainAxisAlignment.center
          : MainAxisAlignment.spaceAround,
      children: _weekDates.map((date) {
        bool isSelected = date.day == _selectedDate.day &&
            date.month == _selectedDate.month &&
            date.year == _selectedDate.year;
        bool hasSlots = _getSlotsForDate(date).isNotEmpty;

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

        final width = MediaQuery.of(context).size.width;
        final isSmall = width < 700;

        return Padding(
          padding: myIsWebOrDektop
              ? EdgeInsets.symmetric(horizontal: isSmall ? 4.0 : 8.0)
              : const EdgeInsets.symmetric(horizontal: 0.0),
          child: GestureDetector(
            onTap: () {
              if (mounted) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? myBlue30 : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                width: 45,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? myBlue60
                      : theme.brightness == Brightness.light
                          ? Colors.white
                          : myGrey80,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.brightness == Brightness.light
                        ? myGrey20
                        : myGrey70,
                    width: 1,
                  ),
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
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
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
            l10n.no_slots_title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.no_slots_message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(48),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.white70,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper method to get cache key for a week
  String _getWeekCacheKey(DateTime weekStart) {
    return DateFormat('yyyy-MM-dd').format(weekStart);
  }

  void _handleNewSession(Map<String, dynamic> sessionData) {
    debugPrint('Handling new session: $sessionData');
    try {
      final sessionDate = (sessionData['sessionDate'] as Timestamp).toDate();
      final weekKey = _getWeekCacheKey(_weekStartDate);

      // Check if the session date falls within current week
      final weekEndDate = _weekStartDate.add(const Duration(days: 7));
      if (sessionDate.isAfter(_weekStartDate) &&
          sessionDate.isBefore(weekEndDate)) {
        // Update cache if it exists for this week
        if (_weeklyDataCache.containsKey(weekKey)) {
          final currentCache = _weeklyDataCache[weekKey] ?? [];
          currentCache.add(sessionData);

          // Sort the cache by session date
          currentCache.sort((a, b) {
            final dateA = (a['sessionDate'] as Timestamp).toDate();
            final dateB = (b['sessionDate'] as Timestamp).toDate();
            return dateA.compareTo(dateB);
          });

          _weeklyDataCache[weekKey] = currentCache;

          // Update the provider
          if (mounted) {
            final userProvider = context.read<UserProvider>();
            userProvider.setCurrentWeekAvailableSlots(currentCache);
          }

          debugPrint('Cache updated with new session for week: $weekKey');
        } else {
          // If no cache exists for this week, fetch all data
          _fetchWeekSlots();
        }

        // Update next available session if needed
        _fetchTrainerNextAvailableSession();
      }
    } catch (e) {
      debugPrint('Error handling new session: $e');
    }
  }
}
