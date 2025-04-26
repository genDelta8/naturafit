import 'package:naturafit/services/auth/bloc/data_fetch_service.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/views/trainer_side/schedule_session_page.dart';
import 'package:naturafit/views/trainer_side/session_details_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeeklySchedulePage extends StatefulWidget {
  const WeeklySchedulePage({super.key});

  @override
  State<WeeklySchedulePage> createState() => _WeeklySchedulePageState();
}

class _WeeklySchedulePageState extends State<WeeklySchedulePage> with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  DateTime currentWeekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );

  Map<String, List<Map<String, dynamic>>> cachedWeekData = {};
  bool isLoading = false;

  String? expandedHintKey;

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
    
    // Get current week's data from UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    /*
    if (userProvider.currentWeekSlots != null) {
      debugPrint('MyCurrent week slots: ${userProvider.currentWeekSlots}');
      final weekKey = _getWeekKey(currentWeekStart);
      cachedWeekData[weekKey] = userProvider.currentWeekSlots!;
    }
    */
    cachedWeekData = {};
    // Add this line to fetch data when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchWeekData(currentWeekStart));
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  String _getWeekKey(DateTime weekStart) {
    return DateFormat('yyyy-MM-dd').format(weekStart);
  }

  Future<void> _fetchWeekData(DateTime weekStart) async {
    if (isLoading) return;

    final weekKey = _getWeekKey(weekStart);
    if (cachedWeekData.containsKey(weekKey)) return;

    setState(() => isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.userData?['userId'];
      if (userId == null) throw Exception('User ID not found');

      final weekStartDate = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day,
        0,
        0,
        0,
      );
      final weekEnd = weekStartDate.add(const Duration(days: 7));

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('trainer_sessions')
          .doc(userId)
          .collection('allTrainerSessions')
          .where('sessionDate', isGreaterThanOrEqualTo: weekStartDate)
          .where('sessionDate', isLessThan: weekEnd)
          .orderBy('sessionDate')
          .get();

      final slots = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['sessionDate'] is Timestamp) {
          return data;
        } else {
          final date = (data['sessionDate'] as DateTime);
          return {
            ...data,
            'sessionDate': Timestamp.fromDate(date),
          };
        }
      }).toList();

      slots.sort((a, b) {
        final aDate = (a['sessionDate'] as Timestamp).toDate();
        final bDate = (b['sessionDate'] as Timestamp).toDate();
        final dateCompare = aDate.compareTo(bDate);
        if (dateCompare != 0) return dateCompare;
        return a['time'].compareTo(b['time']);
      });

      setState(() {
        cachedWeekData[weekKey] = slots;
        isLoading = false;
      });

      userProvider.setCurrentWeekSlots(slots);
      debugPrint('Fetched ${slots.length} slots for week starting $weekStart');
    } catch (e) {
      debugPrint('Error fetching week data: $e');
      setState(() => isLoading = false);
    }
  }

  void _previousWeek() {
    final newWeekStart = currentWeekStart.subtract(const Duration(days: 7));
    setState(() => currentWeekStart = newWeekStart);
    _fetchWeekData(newWeekStart);
  }

  void _nextWeek() {
    final newWeekStart = currentWeekStart.add(const Duration(days: 7));
    setState(() => currentWeekStart = newWeekStart);
    _fetchWeekData(newWeekStart);
  }

  List<Map<String, dynamic>> _getSlotsForDate(DateTime date) {
    final weekKey = _getWeekKey(currentWeekStart);
    final weekSlots = cachedWeekData[weekKey] ?? [];

    return weekSlots.where((slot) {
      final slotDate = (slot['sessionDate'] as Timestamp).toDate();
      return slotDate.year == date.year &&
          slotDate.month == date.month &&
          slotDate.day == date.day;
    }).toList()
      ..sort((a, b) => a['time'].compareTo(b['time']));
  }

  bool _isPastSlot(Map<String, dynamic> slot) {
    final now = DateTime.now();
    final slotDate = (slot['sessionDate'] as Timestamp).toDate();
    final timeStr = slot['time'] as String;

    try {
      // Get time format from UserProvider
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final timeFormat = userProvider.userData?['timeFormat'] ?? '24-hour';

      // Parse time string based on format
      final timeParts = timeStr.split(' ');
      final timeComponents = timeParts[0].split(':');
      var hour = int.parse(timeComponents[0]);
      final minute = int.parse(timeComponents[1]);

      // For 12-hour format (e.g., "9:00 AM" or "2:30 PM")
      if (timeParts.length > 1) {
        if (timeParts[1].toUpperCase() == 'PM' && hour != 12) {
          hour += 12;
        }
        // Handle 12 AM case
        if (timeParts[1].toUpperCase() == 'AM' && hour == 12) {
          hour = 0;
        }
      }
      // For 24-hour format (e.g., "14:30"), no additional conversion needed

      final slotDateTime = DateTime(
        slotDate.year,
        slotDate.month,
        slotDate.day,
        hour,
        minute,
      );
      
      return slotDateTime.isBefore(now);
    } catch (e) {
      debugPrint('Error parsing time: $e');
      return false;
    }
  }

  Icon _getSessionTypeIcon(Map<String, dynamic> slot) {
    return Icon(
      slot['mode'] == 'virtual' ? Icons.videocam : Icons.person,
      color: Colors.white,
      size: 16,
    );
  }

  Color _getSlotColor(Map<String, dynamic> slot) {
    if (_isPastSlot(slot)) {
      return myGrey40;
    }
    // Check if it's a group session first
    if (slot['isGroupSession'] == true && slot['status'] != 'cancelled') {
      return myPurple60;
    }
    switch (slot['status']) {
      case fbClientConfirmedStatus:
      case fbCreatedStatusForNotAppUser:
      case 'booked':
        return myBlue50;
      case 'cancelled':
        return myRed50;
      case 'requested':
        return myRed40;
      case fbCreatedStatusForAppUser:
        return myYellow50;
      case fbCreatedStatusForAvailableSlot:
        return myGreen50;
      default:
        return myGreen50;
    }
  }

  Widget _buildHintButton({
    IconData? icon,
    String? text,
    required String label,
    bool isIconOnly = false,
  }) {
    final String key = text ?? icon.toString();
    bool isExpanded = expandedHintKey == key;

    return GestureDetector(
      onTap: () {
        setState(() {
          expandedHintKey = isExpanded ? null : key;
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(
              icon,
              size: 18,
              color: isExpanded ? Colors.black87 : Colors.grey[600],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                text!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: SizedBox(width: isExpanded ? 8 : 0),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: SizedBox(
                width: isExpanded ? null : 0,
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorHint({
    required Color color,
    required String label,
  }) {
    final String key = color.toString();
    bool isExpanded = expandedHintKey == key;

    return GestureDetector(
      onTap: () {
        setState(() {
          expandedHintKey = isExpanded ? null : key;
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: SizedBox(width: isExpanded ? 8 : 0),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: SizedBox(
                width: isExpanded ? null : 0,
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final myIsWebOrDektop = isWebOrDesktopCached;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          l10n.weekly_schedule,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: myIsWebOrDektop ? false : true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
                child: Row(
                  children: [
                    const Spacer(),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _previousWeek(),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.chevron_left,
                              color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.week_date_range(
                            DateFormat('MMM d').format(currentWeekStart),
                            DateFormat('MMM d').format(currentWeekStart.add(const Duration(days: 6))),
                          ),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _nextWeek(),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.chevron_right,
                              color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScheduleSessionPage(
                                initialScheduleType: 'available_slot',
                                initialSessionCategory: l10n.assessment),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 20, color: Colors.white),
                      label: Text(
                        l10n.add_slot,
                        style: GoogleFonts.plusJakartaSans(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: myBlue60,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, bottom: 100, top: 0),
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final date = currentWeekStart.add(Duration(days: index));
                    final slots = _getSlotsForDate(date);
                    final isToday = date.day == DateTime.now().day &&
                        date.month == DateTime.now().month &&
                        date.year == DateTime.now().year;

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: theme.brightness == Brightness.light ? myGrey20 : myGrey80,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('EEEE').format(date),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                                    color: isToday ? myBlue60 : theme.textTheme.titleMedium?.color,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd/MM').format(date),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.brightness == Brightness.light ? Colors.grey[600] : Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: slots.isEmpty
                                ? Text(
                                    l10n.no_slots,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: theme.brightness == Brightness.light ? myGrey50 : myGrey40,
                                    ),
                                  )
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: slots.map((slot) {
                                      return _buildSlotItem(context, slot);
                                    }).toList(),
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: myBlue60,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlotItem(BuildContext context, Map<String, dynamic> slot) {
    final isRequested = slot['status']?.toLowerCase() == 'requested';
    final l10n = AppLocalizations.of(context)!;
    final slotContent = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: _getSlotColor(slot),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            slot['time'],
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          _getSessionTypeIcon(slot),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              slot['isGroupSession'] == true
                  ? l10n.group_session_indicator
                  : slot['sessionType'] == 'initial'
                      ? l10n.initial_session_indicator
                      : l10n.follow_up_session_indicator,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (slot['isRecurring'] == true) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.refresh,
              color: Colors.white,
              size: 12,
            ),
          ],
        ],
      ),
    );

    return GestureDetector(
      onTap: () async {
        final userData = context.read<UserProvider>().userData;
        if (userData == null) return;
            debugPrint('=== WEB SESSION CARD TAP ===');
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SessionDetailsPage(
                  sessionId: slot['sessionId'],
                  trainerId: userData['userId'],
                ),
              ),
            );
            debugPrint('Web session card result: $result');
            
            if (result != null &&
                result is Map<String, dynamic> &&
                (result['deleted'] == true ||
                    result['cancelled'] == true ||
                    result['edited'] == true)) {
              if (context.mounted) {
                debugPrint('Refreshing professional slots in web view');
                await DataFetchService().fetchProfessionalSlots(
                    userData['userId'],
                    'trainer',
                    context.read<UserProvider>());
                    cachedWeekData = {};
                _fetchWeekData(currentWeekStart);
              }
            }
          },
      child: isRequested
          ? FadeTransition(
              opacity: _blinkAnimation,
              child: slotContent,
            )
          : slotContent,
    );
  }
}
