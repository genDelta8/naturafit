import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:naturafit/views/client_side/client_session_details_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfessionalSlotsPage extends StatefulWidget {
  final Map<String, dynamic> professional;

  const ProfessionalSlotsPage({
    super.key,
    required this.professional,
  });

  @override
  State<ProfessionalSlotsPage> createState() => _ProfessionalSlotsPageState();
}

class _ProfessionalSlotsPageState extends State<ProfessionalSlotsPage> with SingleTickerProviderStateMixin {
  late DateTime _weekStartDate;
  late DateTime _selectedDate;
  late List<DateTime> _weekDates;
  bool _isLoading = false;
  List<Map<String, dynamic>> _currentWeekSlots = [];

  final Map<String, List<Map<String, dynamic>>> _weeklyDataCache = {};

  Map<String, dynamic>? _nextAvailableSession;
  Map<String, dynamic>? _weekStats;

  Timer? _countdownTimer;
  
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _fetchNextAvailableProfessionalSlot();
    _initializeWeek();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _blinkAnimation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(_blinkController);

    _blinkController.repeat(reverse: true);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
    _fetchWeekSlots();
  }
  

  void _fetchNextAvailableProfessionalSlot() async {
    try {
      final professionalId = widget.professional['professionalId'] ?? widget.professional['userId'];
      final now = DateTime.now();
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      final nextAvailableSessionSnapshot = await FirebaseFirestore.instance
          .collection('trainer_sessions')
          .doc(professionalId)
          .collection('allTrainerSessions')
          .where('sessionDate', isGreaterThanOrEqualTo: now)
          .where('status', whereIn: ['available', 'group', 'requested'])
          .orderBy('sessionDate')
          .limit(1)
          .get();

      if (nextAvailableSessionSnapshot.docs.isNotEmpty) {
        final nextAvailableSession = nextAvailableSessionSnapshot.docs.first.data();
        setState(() {
          _nextAvailableSession = nextAvailableSession;
        });
        debugPrint('Next available trainer session found: ${nextAvailableSession['sessionDate']}');
      } else {
        setState(() {
          _nextAvailableSession = null;
        });
        debugPrint('No upcoming available sessions found for trainer');
      }
    } catch (e) {
      debugPrint('Error fetching next available trainer session: $e');
      rethrow;
    }
    
    



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


String _getWeekCacheKey(DateTime weekStart) {
    return DateFormat('yyyy-MM-dd').format(weekStart);
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
      setState(() {
        _currentWeekSlots = _weeklyDataCache[weekKey]!;
      });
      debugPrint('Using cached data for week: $weekKey');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final professionalId = widget.professional['professionalId'] ?? widget.professional['userId'];
      final role = widget.professional['role'];
      debugPrint('Professional ID!: $professionalId');
      debugPrint('Professional Role!: $role');
      
      final collection = role == 'trainer' ? 'trainer_sessions' : 'dietitian_sessions';
      final subcollection = role == 'trainer' ? 'allTrainerSessions' : 'allDietitianSessions';

      // Calculate end of week (next Monday at 00:00)
      final weekEndDate = _weekStartDate.add(const Duration(days: 7));

      debugPrint('Fetching slots from: ${_weekStartDate.toString()} to ${weekEndDate.toString()}');

      final snapshot = await FirebaseFirestore.instance
          .collection(collection)
          .doc(professionalId)
          .collection(subcollection)
          .where('sessionDate', isGreaterThanOrEqualTo: _weekStartDate)
          .where('sessionDate', isLessThan: weekEndDate)
          .where('status', whereIn: ['available', 'group', 'requested'])
          .orderBy('sessionDate')
          .get();

      final slots = snapshot.docs
          .map((doc) => doc.data())
          .where((slot) => 
            slot['status'] == 'available' || 
            slot['status'] == 'requested' ||
            slot['scheduleType'] == 'group'
          )
          .toList();
          
      // Store in cache
      _weeklyDataCache[weekKey] = slots;

      setState(() {
        _currentWeekSlots = slots;
      });
      debugPrint('Fetched and cached ${slots.length} available/group slots for week: $weekKey');
    } catch (e) {
      debugPrint('Error fetching slots: $e');
    } finally {
      setState(() => _isLoading = false);
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
      _weekStats = _getWeekStats();
      _weekStartDate = _weekStartDate.add(Duration(days: 7 * direction));
      _generateWeekDates();
      _selectedDate = _weekDates[0]; // Select first day of new week
    });
    _fetchWeekSlots();
  }

  List<Map<String, dynamic>> _getSlotsForDate(DateTime date) {
    return _currentWeekSlots.where((slot) {
      final slotDate = (slot['sessionDate'] as Timestamp).toDate();
      return slotDate.year == date.year && 
             slotDate.month == date.month && 
             slotDate.day == date.day;
    }).toList();
  }

  Map<String, int> _getWeekStats() {
    int available = 0;
    int recurring = 0;
    int group = 0;
    int requested = 0;
    for (var slot in _currentWeekSlots) {
      if (slot['status'] == 'available') {
        available++;
      }

      if (slot['status'] == 'requested') {
        requested++;
      }
      
      if (slot['isRecurring'] == true) {
        recurring++;
      }

      if (slot['isGroupSession'] == true) {
        group++;
      }
    }

    return {
      'available': available,
      'recurring': recurring,
      'group': group,
      'requested': requested,
    };
  }

  Widget _buildWeekNavigator(ThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, color: theme.brightness == Brightness.light ? Colors.black : Colors.white),
              onPressed: () => _navigateWeek(-1),
            ),
            Text(
              '${DateFormat('MMM d').format(_weekDates.first)} - ${DateFormat('MMM d').format(_weekDates.last)}',
              style: GoogleFonts.plusJakartaSans(
                color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, color: theme.brightness == Brightness.light ? Colors.black : Colors.white),
              onPressed: () => _navigateWeek(1),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildWeekView(theme),
      ],
    );
  }

Widget _buildWeekView(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _weekDates.map((date) {
        bool isSelected = date.day == _selectedDate.day;
        bool hasSlots = _getSlotsForDate(date).isNotEmpty;

        final l10n = AppLocalizations.of(context)!;
        var formattedDate = DateFormat('E').format(date);
        switch (formattedDate) {
          case 'Mon': formattedDate = l10n.monday;
          case 'Tue': formattedDate = l10n.tuesday;
          case 'Wed': formattedDate = l10n.wednesday;
          case 'Thu': formattedDate = l10n.thursday;
          case 'Fri': formattedDate = l10n.friday;
          case 'Sat': formattedDate = l10n.saturday;
          case 'Sun': formattedDate = l10n.sunday;
          default: formattedDate = formattedDate;
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
                color: isSelected ? myBlue60 : theme.brightness == Brightness.light ? Colors.white : myGrey80,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.brightness == Brightness.light ? myGrey20 : myGrey70, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formattedDate.substring(0, 1),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isSelected ? Colors.white : theme.brightness == Brightness.light ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : theme.brightness == Brightness.light ? Colors.black : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasSlots
                          ? (isSelected ? Colors.white : theme.brightness == Brightness.light ? myGrey30 : myGrey50)
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

  Widget _buildSlotCard(Map<String, dynamic> slot) {
    final l10n = AppLocalizations.of(context)!;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userData?['userId'];
    final slotDate = (slot['sessionDate'] as Timestamp).toDate();
    final isPast = slotDate.isBefore(DateTime.now());
    final isGroupSession = slot['isGroupSession'] == true;
    final isGroupRequested = ((slot['requestedByClients'] as List?)?.any(
                      (client) => client['clientId'] == userId
                    ) == true);
    //final formattedDate = DateFormat('E, MMM d').format(sessionDate);
    var formattedThreeLettersDay = DateFormat('E').format(slotDate);
    var formattedThreeLettersMonth = DateFormat('MMM').format(slotDate);
    final formattedDayOfMonth = DateFormat('d').format(slotDate);
    final groupSize = (slot['clients'] as List?)?.length ?? 0;
    final theme = Theme.of(context);


    switch (formattedThreeLettersDay) {
      case 'Mon': formattedThreeLettersDay = l10n.monday_date;
      case 'Tue': formattedThreeLettersDay = l10n.tuesday_date;
      case 'Wed': formattedThreeLettersDay = l10n.wednesday_date;
      case 'Thu': formattedThreeLettersDay = l10n.thursday_date;
      case 'Fri': formattedThreeLettersDay = l10n.friday_date;
      case 'Sat': formattedThreeLettersDay = l10n.saturday_date;
      case 'Sun': formattedThreeLettersDay = l10n.sunday_date;
      default: formattedThreeLettersDay = formattedThreeLettersDay;
    }

    switch (formattedThreeLettersMonth) {
      case 'Jan': formattedThreeLettersMonth = l10n.january_date;
      case 'Feb': formattedThreeLettersMonth = l10n.february_date;
      case 'Mar': formattedThreeLettersMonth = l10n.march_date;
      case 'Apr': formattedThreeLettersMonth = l10n.april_date;
      case 'May': formattedThreeLettersMonth = l10n.may_date;
      case 'Jun': formattedThreeLettersMonth = l10n.june_date;
      case 'Jul': formattedThreeLettersMonth = l10n.july_date;
      case 'Aug': formattedThreeLettersMonth = l10n.august_date;
      case 'Sep': formattedThreeLettersMonth = l10n.september_date;
      case 'Oct': formattedThreeLettersMonth = l10n.october_date;
      case 'Nov': formattedThreeLettersMonth = l10n.november_date;
      case 'Dec': formattedThreeLettersMonth = l10n.december_date;
      default: formattedThreeLettersMonth = formattedThreeLettersMonth;
    }

    final formattedDate = '$formattedThreeLettersDay, $formattedThreeLettersMonth $formattedDayOfMonth';

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              final userData = FirebaseAuth.instance.currentUser;
              if (userData == null) return;



              debugPrint('MYSession ID: ${slot['sessionId']}');
              debugPrint('MYClient ID: ${userData.uid}');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClientSessionDetailsPage(
                    clientId: userData.uid,
                    sessionId: slot['sessionId'],
                    isProfessionalAvailableSlot: true,
                  ),
                ),
              ).then((_) {
                // Refresh all the necessary data when returning from edit page
                _clearCache(); // Clear the cached data
                _fetchWeekSlots(); // Fetch fresh slots data
                _fetchNextAvailableProfessionalSlot(); // Refresh the next available slot
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (isGroupSession)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light ? myGrey30 : myGrey70,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                      Icons.groups,
                      color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                    ),
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light ? myGrey30 : myGrey70,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person,
                      color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                    ),
                  ),



                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGroupSession 
                            ? '${l10n.group_session}${groupSize > 0 ? ' ($groupSize)' : ''}'
                            : l10n.available_slot,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                            color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: theme.brightness == Brightness.light ? Colors.grey[600] : Colors.grey[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$formattedDate  @${slot['time']}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: theme.brightness == Brightness.light ? Colors.grey[600] : Colors.grey[400],
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          slot['sessionCategory'] ?? '1:1 Training',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: theme.brightness == Brightness.light ? Colors.grey[600] : Colors.grey[400],
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusTag(isGroupSession, slot['status'], isPast, isGroupRequested),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTag(bool isGroupSession, String status, bool isPast, bool isGroupRequested) {
    final l10n = AppLocalizations.of(context)!;
    if ((status == 'requested' && !isPast) || (isGroupRequested && !isPast)) {
      return FadeTransition(
        opacity: _blinkAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isGroupRequested && isGroupSession ? myPurple60 : myRed40,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isGroupRequested && isGroupSession ? l10n.group : l10n.requested,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isPast ? myGrey30 : isGroupRequested ? myRed40 : isGroupSession ? myPurple60 : myGreen50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isGroupSession ? l10n.group : 
        status == 'requested' ? l10n.requested : 
        l10n.available,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.brightness == Brightness.light ? Colors.grey.shade200 : Colors.grey.shade800),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy,
            size: 48,
            color: theme.brightness == Brightness.light ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.no_slots_available,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.brightness == Brightness.light ? Colors.grey[800] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no available slots for this day',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: theme.brightness == Brightness.light ? Colors.grey[600] : Colors.grey[400],
            ),
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
        borderRadius: BorderRadius.circular(16),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _weekStats = _getWeekStats();
    final userData = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);


    var formattedMonth = DateFormat('MMMM').format(_selectedDate);
    switch (formattedMonth) {
      case 'January': formattedMonth = l10n.january;
      case 'February': formattedMonth = l10n.february;
      case 'March': formattedMonth = l10n.march;
      case 'April': formattedMonth = l10n.april;
      case 'May': formattedMonth = l10n.may;
      case 'June': formattedMonth = l10n.june;
      case 'July': formattedMonth = l10n.july;
      case 'August': formattedMonth = l10n.august;
      case 'September': formattedMonth = l10n.september;
      case 'October': formattedMonth = l10n.october;
      case 'November': formattedMonth = l10n.november;
      case 'December': formattedMonth = l10n.december;
      default: formattedMonth = formattedMonth;
    }
    final formattedDate = '$formattedMonth ${_selectedDate.day}, ${_selectedDate.year}';

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
          l10n.available_slots,
          style: GoogleFonts.plusJakartaSans(
            color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    //color: const Color(0xFF1E293B),
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
                            color: myGrey80,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Consumer<UserProvider>(
                            builder: (context, userProvider, child) {
                              
              
                              if (_nextAvailableSession == null) {
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
              
                              final session = _nextAvailableSession;
                              final sessionDate = (session?['sessionDate'] as Timestamp).toDate();
                              final now = DateTime.now();
                              final difference = sessionDate.difference(now);
                              final countdownText = _formatCountdown(difference);
                              //debugPrint('myweekStats: ${weekStats}');
              
                              return Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          l10n.next_session_in,
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
                                          onTap: () {
                                            debugPrint('Daily Calories');
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ClientSessionDetailsPage(
                                                  clientId: userData?.uid ?? '',
                                                  sessionId: session?['sessionId'] ?? '',
                                                  isProfessionalAvailableSlot: true,
                                                ),
                                              ),
                                            ).then((_) {
                                              _clearCache();
                                              _fetchWeekSlots();
                                              _fetchNextAvailableProfessionalSlot();
                                            });
                                          },
                                          
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: myBlue60,
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                            '${l10n.availabale_slots_week_stats_available} ',
                                            style: GoogleFonts.plusJakartaSans(
                                                fontSize: 16,
                                                color: myTeal30,
                                                fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            '${_weekStats?['available'] ?? 0}',
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
                                            '${_weekStats?['group'] ?? 0}',
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
                                                color: myBlue50,
                                                fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            '${_weekStats?['recurring'] ?? 0}',
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
                                            '${_weekStats?['requested'] ?? 0}',
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
                            },
                          ),
                        ),
                      const SizedBox(height: 8),
                      _buildWeekNavigator(theme),
                    ],
                    ),
                  ),
              
              
                  Row(
                    //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 16),
                      Text(
                        formattedDate,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      children: [
                        const SizedBox(height: 16),
                        ..._getSlotsForDate(_selectedDate)
                            .map((slot) => _buildSlotCard(slot))
                            .toList(),
                        if (_getSlotsForDate(_selectedDate).isEmpty)
                          _buildEmptyState(theme),
                      ],
                    ),
                  ),
              
              
                ],
              ),
            ),
          ),
          
        ],
      ),
    );
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

} 