import 'package:cached_network_image/cached_network_image.dart';
import 'package:naturafit/services/auth/bloc/data_fetch_service.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/views/trainer_side/session_details_page.dart';
import 'package:flutter/material.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WebUpcomingSessionsCard extends StatefulWidget {
  final List<Map<String, dynamic>> upcomingSessions;
  final Map<String, dynamic> session;
  final Map<String, dynamic> userData;

  const WebUpcomingSessionsCard({
    super.key,
    required this.upcomingSessions,
    required this.session,
    required this.userData,
  });

  @override
  State<WebUpcomingSessionsCard> createState() => _WebUpcomingSessionsCardState();
}

class _WebUpcomingSessionsCardState extends State<WebUpcomingSessionsCard> with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

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
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userData = context.read<UserProvider>().userData;
    final l10n = AppLocalizations.of(context)!;
    if (userData == null) return const SizedBox.shrink();

    final isGroup = widget.session['isGroupSession'] ?? false;
    final isAvailable = widget.session['status'] == fbCreatedStatusForAvailableSlot;
    final isRequested = widget.session['status'] == 'requested';
    final sessionDate = (widget.session['sessionDate'] as Timestamp).toDate();
    final formattedDate = DateFormat('E, MMM d').format(sessionDate);
    final formattedDay = DateFormat('dd').format(sessionDate);
    final formattedMonth = DateFormat('MMM').format(sessionDate);
    final formattedDayName = DateFormat('EEEE').format(sessionDate);

    final width = MediaQuery.of(context).size.width;
    // Responsive breakpoints
    final isVerySmall = width < 600;
    final isSmall = width < 800;
    final isMedium = width < 1200;
    final showSideBars = width > 1000;
    final canExpandLeftBar = width > 700;

    // Get user's time format preference
    final is24Hour = userData['timeFormat'] == '24-hour';
    
    // Format time based on preference
    final timeFormat = is24Hour ? 'HH:mm' : 'h:mm a';
    final formattedTime = DateFormat(timeFormat).format(sessionDate);

    // Get client info with proper field names
    final String clientName =
        widget.session['clientFullname']?.toString().isNotEmpty == true
            ? widget.session['clientFullname']
            : widget.session['clientUsername'] ?? 'Client';
    final String? profileImageUrl = widget.session['clientProfileImageUrl'];

    // Get initial for avatar - safely handle empty strings
    final String clientInitial =
        clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C';

    // For group sessions
    final List<dynamic> groupClients = widget.session['clients'] ?? [];
    final int groupSize = groupClients.length;

    // Replace the status badge Container with this conditional widget
    final statusWidget = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: getStatusColor(isGroup, widget.session['status'])['backgroundColor'],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isGroup && widget.session['status'] != 'cancelled'
            ? l10n.group
            : getLocalizedStatus(context, widget.session['status']).toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: isSmall ? 10 : 12,
          color: getStatusColor(isGroup, widget.session['status'])['textColor'],
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    // Wrap the status badge in FadeTransition if status is 'requested'
    final statusBadge = isRequested
        ? FadeTransition(
            opacity: _blinkAnimation,
            child: statusWidget,
          )
        : statusWidget;

    return Container(
      child: Column(
      children: [
        InkWell(
          onTap: () async {
            debugPrint('=== WEB SESSION CARD TAP ===');
            debugPrint('Session id: ${widget.session['sessionId']}');
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SessionDetailsPage(
                  sessionId: widget.session['sessionId'],
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
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Date and Time Row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Date
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            formattedDay,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                            ),
                          ),
                          Text(
                            getLocalizedMonthName(context, formattedMonth).toUpperCase(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Time
                      if (!isMedium)
                      Column(
                        children: [
                          Text(
                            getLocalizedDayName(context, formattedDayName),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              //color: myGrey90,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.brightness == Brightness.light ? myGrey90 : Colors.white, width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  formattedTime,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Keep existing avatar code
                if (!isMedium) ...[
                if (isGroup)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light ? myGrey30 : myGrey80,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.groups,
                      color: Colors.white,
                    ),
                  )
                else if (isAvailable || isRequested)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light ? myGrey30 : myGrey80,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  )
                else if (profileImageUrl != null &&
                    profileImageUrl != 'null' &&
                    profileImageUrl != '')
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: profileImageUrl.toString().startsWith('assets/')
                          ? myAvatarBackground
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: profileImageUrl.toString().startsWith('assets/')
                          ? Image.asset(
                              profileImageUrl,
                              fit: BoxFit.cover,
                            )
                          : CachedNetworkImage(
                              imageUrl: profileImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: myGrey20,
                                child: const Center(
                                  child: CircularProgressIndicator(color: myGrey30),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: myGrey20,
                                child: const Icon(
                                  Icons.person_outline,
                                  color: myGrey60,
                                ),
                              ),
                            ),
                          
                    ),
                  )
                else
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light ? myGrey30 : myGrey80,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        clientInitial,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),
                ],
                

                // Client Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGroup ? l10n.group_session_count(groupSize)
                            : isAvailable ? l10n.available_slot
                            : isRequested ? l10n.available_slot
                            : clientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.session['sessionCategory'] ?? l10n.training_session,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: myGrey60,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                statusBadge,
              ],
            ),
          ),
        ),
        if (widget.upcomingSessions.last != widget.session)
          Divider(
            color: theme.dividerColor,
            height: 1,
          ),
      ],
    ),
    );
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
      default:
        return {
          'backgroundColor': myYellow50,
          'textColor': Colors.white,
        };
    }
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
      default:
        return l10n.status_pending;
    }
  }

  String getLocalizedDayName(BuildContext context, String dayName) {
    final l10n = AppLocalizations.of(context)!;
    switch (dayName) {
      case 'Monday':
        return l10n.monday;
      case 'Tuesday':
        return l10n.tuesday;  
      case 'Wednesday':
        return l10n.wednesday;
      case 'Thursday':
        return l10n.thursday;
      case 'Friday':
        return l10n.friday;
      case 'Saturday':
        return l10n.saturday;
      case 'Sunday':
        return l10n.sunday;
      default:
        return dayName;
    }
  }

  String getLocalizedMonthName(BuildContext context, String monthName) {
    final l10n = AppLocalizations.of(context)!;
    switch (monthName) {
      case 'Jan':
        return l10n.january_date;
      case 'Feb':
        return l10n.february_date;
      case 'Mar':
        return l10n.march_date;
      case 'Apr':
        return l10n.april_date;
      case 'May':
        return l10n.may_date;
      case 'Jun':
        return l10n.june_date;
      case 'Jul':
        return l10n.july_date;
      case 'Aug':
        return l10n.august_date;
      case 'Sep':
        return l10n.september_date;
      case 'Oct':
        return l10n.october_date;
      case 'Nov':
        return l10n.november_date;
      case 'Dec':
        return l10n.december_date;
      default:
        return monthName;
    }
  }
}
