import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/views/client_side/client_session_details_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ClientWeeklySchedulePage extends StatefulWidget {
  const ClientWeeklySchedulePage({super.key});

  @override
  State<ClientWeeklySchedulePage> createState() =>
      _ClientWeeklySchedulePageState();
}

class _ClientWeeklySchedulePageState extends State<ClientWeeklySchedulePage>
    with SingleTickerProviderStateMixin {
  DateTime currentWeekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );

  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  Map<String, List<Map<String, dynamic>>> cachedWeekData = {};
  bool isLoading = false;
  String? expandedHintKey;
  String _dateFormat = 'MM/DD/YYYY'; // default value

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _blinkAnimation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(_blinkController);

    _blinkController.repeat(reverse: true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentWeekSlots != null) {
      //cachedWeekData.clear();
      final weekKey = _getWeekKey(currentWeekStart);
      cachedWeekData[weekKey] = userProvider.currentWeekSlots!;
    }

    _loadDateFormat();
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
      );
      final weekEnd = weekStartDate.add(const Duration(days: 7));

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('client_sessions')
          .doc(userId)
          .collection('allClientSessions')
          .where('sessionDate', isGreaterThanOrEqualTo: weekStartDate)
          .where('sessionDate', isLessThan: weekEnd)
          .get();

      final sessions = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Sort sessions by date and time
      sessions.sort((a, b) {
        final aDate = (a['sessionDate'] as Timestamp).toDate();
        final bDate = (b['sessionDate'] as Timestamp).toDate();
        final dateCompare = aDate.compareTo(bDate);
        if (dateCompare != 0) return dateCompare;
        return a['time'].compareTo(b['time']);
      });

      setState(() {
        cachedWeekData[weekKey] = sessions;
        isLoading = false;
      });
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
      final timeParts = timeStr.split(' ');
      final timeComponents = timeParts[0].split(':');
      var hour = int.parse(timeComponents[0]);
      final minute = int.parse(timeComponents[1]);

      if (timeParts[1].toUpperCase() == 'PM' && hour != 12) {
        hour += 12;
      }
      if (timeParts[1].toUpperCase() == 'AM' && hour == 12) {
        hour = 0;
      }

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

  Color _getSlotColor(Map<String, dynamic> slot) {
    if (_isPastSlot(slot)) {
      return myGrey40;
    }

    if (slot['status'] == 'cancelled') {
      return myRed50;
    }


    if (slot['isGroupSession'] == true) {
      return myPurple60;
    }
    switch (slot['status']) {
      case 'confirmed':
      case 'booked':
        return myBlue50;
      case 'cancelled':
      case 'withdrawn':
      case 'rejected':
        return myRed50;
      case 'pending':
        return myYellow50;
      case 'available':
        return myGreen50;
      case 'requested':
        return myRed40;
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
    final l10n = AppLocalizations.of(context)!;
    final String key = text ?? icon.toString();
    bool isExpanded = expandedHintKey == key;

    String getTranslatedLabel(String label) {
      switch (label) {
        case 'Virtual':
          return l10n.virtual;
        case 'In-person':
          return l10n.in_person;
        case 'Initial Session':
          return l10n.initial_session;
        case 'Follow-up Session':
          return l10n.follow_up_session;
        case 'Group Session':
          return l10n.group_session;
        case 'Recurring Session':
          return l10n.recurring_session;
        default:
          return label;
      }
    }

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
                getTranslatedLabel(text!),
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
                  getTranslatedLabel(label),
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
    final l10n = AppLocalizations.of(context)!;
    final String key = color.toString();
    bool isExpanded = expandedHintKey == key;

    String getTranslatedLabel(String label) {
      switch (label) {
        case 'Booked':
          return l10n.booked;
        case 'Cancelled':
          return l10n.cancelled;
        case 'Pending':
          return l10n.pending;
        case 'Available':
          return l10n.available;
        case 'Group Session':
          return l10n.group_session;
        case 'Past':
          return l10n.past;
        default:
          return label;
      }
    }

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
                  getTranslatedLabel(label),
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

  Widget _buildSlot(Map<String, dynamic> slot, String timeFormat) {
    final isRequested = slot['status'] == 'requested';
    final isPast = _isPastSlot(slot);
    final isGroup = slot['isGroupSession'] == true;
    final displayTime = _formatTimeByPreference(slot['time'], timeFormat);
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
            displayTime,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            slot['mode'] == 'virtual' ? Icons.videocam : Icons.person,
            color: Colors.white,
            size: 16,
          ),
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
                  ? 'G'
                  : slot['sessionType'] == 'initial'
                      ? 'I'
                      : 'F',
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
      onTap: () {
        final userData = context.read<UserProvider>().userData;
        if (userData == null) return;

        debugPrint('MY Session ID: ${slot['sessionId']}');
        debugPrint('MY Trainer ID: ${slot['professionalId']}');
        debugPrint('MY Group Session: $isGroup');
        debugPrint('MY Client ID: ${userData['userId']}');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClientSessionDetailsPage(
              sessionId: slot['sessionId'],
              clientId: userData['userId'],
              isGroupSession: isGroup,
              passedTrainerId: slot['professionalId'],
              isProfessionalAvailableSlot: false,
            ),
          ),
        ).then((_) {
          if (context.mounted) {
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          final weekKey = _getWeekKey(currentWeekStart);
          if (cachedWeekData[weekKey] != userProvider.currentWeekSlots!) {
            debugPrint('MY Clearing cached week data');
            cachedWeekData.clear();
            _fetchWeekData(currentWeekStart);
            }
          }
        });
      },
      child: (isRequested && !isPast)
          ? FadeTransition(
              opacity: _blinkAnimation,
              child: slotContent,
            )
          : slotContent,
    );
  }

  Future<void> _loadDateFormat() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dateFormat = prefs.getString('dateFormat') ?? 'MM/DD/YYYY';
    });
  }

  @override
  Widget build(BuildContext context) {
    final myIsWebOrDektop = isWebOrDesktopCached;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final userData = context.read<UserProvider>().userData;
    final myDateFormat = userData?['dateFormat'] as String? ?? 'MM/DD/YYYY';
    final myTimeFormat = userData?['timeFormat'] as String? ?? '12-hour';
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.weekly_schedule,
          style: GoogleFonts.plusJakartaSans(
            color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
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
              // Week navigation
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _previousWeek,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.brightness == Brightness.light ? Colors.grey[700]! : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.chevron_left,
                          color: theme.brightness == Brightness.light ? Colors.grey[700] : Colors.grey[300],
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Text(
                      '${DateFormat('MMM d').format(currentWeekStart)} - '
                      '${DateFormat('MMM d').format(currentWeekStart.add(const Duration(days: 6)))}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: _nextWeek,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.brightness == Brightness.light ? Colors.grey[700]! : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          color: theme.brightness == Brightness.light ? Colors.grey[700] : Colors.grey[300],
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              /*
              Column(
                children: [
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildHintButton(
                              icon: Icons.videocam,
                              label: 'Virtual',
                              isIconOnly: true,
                            ),
                            const SizedBox(width: 16),
                            _buildHintButton(
                              icon: Icons.person,
                              label: 'In-person',
                              isIconOnly: true,
                            ),
                            const SizedBox(width: 16),
                            _buildHintButton(
                              text: 'I',
                              label: 'Initial Session',
                            ),
                            const SizedBox(width: 16),
                            _buildHintButton(
                              text: 'F',
                              label: 'Follow-up Session',
                            ),
                            const SizedBox(width: 16),
                            _buildHintButton(
                              text: 'G',
                              label: 'Group Session',
                            ),
                            const SizedBox(width: 16),
                            _buildHintButton(
                              icon: Icons.refresh,
                              label: 'Recurring Session',
                              isIconOnly: true,
                            ),
                            //const SizedBox(width: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildColorHint(
                              color: myBlue50,
                              label: 'Booked',
                            ),
                            const SizedBox(width: 16),
                            _buildColorHint(
                              color: myRed50,
                              label: 'Cancelled',
                            ),
                            const SizedBox(width: 16),
                            _buildColorHint(
                              color: myYellow50,
                              label: 'Pending',
                            ),
                            const SizedBox(width: 16),
                            _buildColorHint(
                              color: myGreen50,
                              label: 'Available',
                            ),
                            const SizedBox(width: 16),
                            _buildColorHint(
                              color: myPurple60,
                              label: 'Group Session',
                            ),
                            const SizedBox(width: 16),
                            _buildColorHint(
                              color: myGrey40,
                              label: 'Past',
                            ),
                            //const SizedBox(width: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              */
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
                            color: theme.brightness == Brightness.light ? Colors.grey[200]! : Colors.grey[800]!,
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
                                  getWeekdayName(date),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: isToday
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isToday 
                                      ? myBlue60 
                                      : theme.brightness == Brightness.light ? Colors.black87 : Colors.white70,
                                  ),
                                ),
                                Text(
                                  DateFormat(myDateFormat == 'DD/MM/YYYY' ? 'dd/MM' : 'MM/dd').format(date),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: theme.brightness == Brightness.light ? Colors.grey[600] : Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: slots.isEmpty
                                ? Text(
                                    l10n.no_sessions,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: theme.brightness == Brightness.light ? Colors.grey[500] : Colors.grey[400],
                                    ),
                                  )
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: slots
                                        .map((slot) => _buildSlot(slot, myTimeFormat))
                                        .toList(),
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
              color: theme.brightness == Brightness.light 
                ? Colors.black.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
              child: Center(
                child: CircularProgressIndicator(
                  color: theme.brightness == Brightness.light ? myBlue60 : myBlue40,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String getWeekdayName(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    switch (date.weekday) {
      case 1:
        return l10n.monday;
      case 2:
        return l10n.tuesday;
      case 3:
        return l10n.wednesday;
      case 4:
        return l10n.thursday;
      case 5:
        return l10n.friday;
      case 6:
        return l10n.saturday;
      case 7:
        return l10n.sunday;
      default:
        return '';
    }
  }
}
