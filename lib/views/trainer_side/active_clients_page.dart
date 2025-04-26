import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/theme_provider.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/views/shared_side/direct_message_page.dart';
import 'package:naturafit/views/trainer_side/add_client_page.dart';
import 'package:naturafit/views/trainer_side/client_detail_page.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/views/trainer_side/generate_invitation_link.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:intl/intl.dart';
import 'package:naturafit/widgets/custom_user_profile_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:naturafit/widgets/custom_expandable_search.dart';
import 'package:flutter/gestures.dart';

class ActiveClientsPage extends StatefulWidget {
  const ActiveClientsPage({super.key});

  @override
  State<ActiveClientsPage> createState() => _ActiveClientsPageState();
}

class _ActiveClientsPageState extends State<ActiveClientsPage> {
  String _searchQuery = '';
  String _selectedFilter = 'Active';
  final List<String> _filters = [
    'All',
    'Active',
    'New',
    'App Users',
    'Manual',
    'Completed'
  ];

  List<Map<String, dynamic>> get filteredClients {
    final clients = context.watch<UserProvider>().partiallyTotalClients ?? [];

    if (_searchQuery.isNotEmpty) {
      return clients.where((client) {
        return client['clientName']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Handle 'New' filter first
    if (_selectedFilter == 'New') {
      return _getNewClients();
    }

    // Handle other filters
    final filtered = clients.where((client) {
      switch (_selectedFilter) {
        case 'All':
          return true;
        case 'Active':
          return client['status'] == 'active' ||
              client['status'] == 'confirmed';
        case 'Completed':
          return client['status'] == 'completed';
        case 'Manual':
          return client['connectionType'] == 'manual';
        case 'App Users':
          return client['connectionType'] == 'app';
        default:
          return true;
      }
    }).toList();

    // Sort clients: those with upcoming sessions first, then alphabetically
    filtered.sort((a, b) {
      final aSession = a['nextSession'] as Timestamp?;
      final bSession = b['nextSession'] as Timestamp?;

      if (aSession != null && bSession != null) {
        final aDate = aSession.toDate();
        final bDate = bSession.toDate();
        if (aDate.isAfter(DateTime.now()) && bDate.isAfter(DateTime.now())) {
          return aDate.compareTo(bDate);
        }
      }

      // If no valid next sessions, sort by name
      return a['clientName'].toString().compareTo(b['clientName'].toString());
    });

    return filtered;
  }

  List<Map<String, dynamic>> _getNewClients() {
    final clients = context.watch<UserProvider>().partiallyTotalClients ?? [];
    final sortedClients = List<Map<String, dynamic>>.from(clients);
    sortedClients.sort((a, b) {
      final aTime = a['createdAt'] as Timestamp?;
      final bTime = b['createdAt'] as Timestamp?;

      // If either createdAt is null, put those entries last
      if (aTime == null) return 1;
      if (bTime == null) return -1;

      return bTime.compareTo(aTime); // Newest first
    });
    return sortedClients.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final myIsWebOrDektop = isWebOrDesktopCached;

    final userData = context.watch<UserProvider>().userData;
    final userTrainerClientId = userData?['trainerClientId'] ?? '';
    final clients = context.watch<UserProvider>().partiallyTotalClients ?? [];
    final completedClients = clients
        .where((client) => client['status'] == fbCompletedStatus)
        .toList();
    final activeAndConfirmedClients = clients
        .where((client) =>
            client['status'] == fbClientConfirmedStatus ||
            client['status'] == fbCreatedStatusForNotAppUser)
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: myBlue60,
            borderRadius: myIsWebOrDektop
                ? const BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  )
                : null,
          ),
          child: AppBar(
            leading: myIsWebOrDektop
                ? const SizedBox.shrink()
                : Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
            title: Row(
              children: [
                Text(
                  l10n.my_clients,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.group, color: Colors.white),
              ],
            ),
            centerTitle: myIsWebOrDektop ? false : true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: myIsWebOrDektop
                ? [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CustomExpandableSearch(
                        hintText: l10n.search_clients,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ]
                : [
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const GenerateInviteLinkPage()),
                          );
                        },
                        label: Text(
                          l10n.add_client,
                          style: GoogleFonts.plusJakartaSans(),
                        ),
                        icon: const Icon(Icons.add,
                            size: 18, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          foregroundColor: Colors.white,
                          backgroundColor: myBlue60,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side:
                                const BorderSide(color: Colors.white, width: 1),
                          ),
                        ),
                      ),
                    ),
                  ],
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: myIsWebOrDektop ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: myBlue60,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
            child: Column(
              children: [
                if (!myIsWebOrDektop) ...[
                  CustomFocusTextField(
                    label: '',
                    hintText: l10n.search_clients,
                    controller: TextEditingController(),
                    prefixIcon: Icons.search,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    },
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        String filterText = filter == 'All'
                            ? l10n.filter_all
                            : filter == 'Active'
                                ? l10n.filter_active
                                : filter == 'New'
                                    ? l10n.filter_new
                                    : filter == 'App Users'
                                        ? l10n.filter_app_users
                                        : filter == 'Manual'
                                            ? l10n.filter_manual
                                            : l10n.filter_completed;

                        // Get appropriate icon for each filter
                        IconData filterIcon = Icons.all_inclusive;
                        switch (filter) {
                          case 'All':
                            filterIcon = Icons.all_inclusive;
                            break;
                          case 'Active':
                            filterIcon = Icons.check_circle_outline;
                            break;
                          case 'New':
                            filterIcon = Icons.fiber_new;
                            break;
                          case 'Completed':
                            filterIcon = Icons.thumb_up_off_alt;
                            break;
                          case 'Manual':
                            filterIcon = Icons.person_add;
                            break;
                          case 'App Users':
                            filterIcon = Icons.smartphone;
                            break;
                        }
                        // Add count to filter text if needed
                        if (filter == 'Active' &&
                            activeAndConfirmedClients.isNotEmpty) {
                          filterText =
                              '$filterText (${activeAndConfirmedClients.length})';
                        } else if (filter == 'Completed' &&
                            completedClients.isNotEmpty) {
                          filterText =
                              '$filterText (${completedClients.length})';
                        } else if (filter == 'New') {
                          filterText =
                              '$filterText (${_getNewClients().length})';
                        } else if (filter == 'Manual' &&
                            clients
                                .where((c) => c['connectionType'] == 'manual')
                                .isNotEmpty) {
                          filterText =
                              '$filterText (${clients.where((c) => c['connectionType'] == 'manual').length})';
                        } else if (filter == 'App Users' &&
                            clients
                                .where((c) => c['connectionType'] == 'app')
                                .isNotEmpty) {
                          filterText =
                              '$filterText (${clients.where((c) => c['connectionType'] == 'app').length})';
                        }

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            showCheckmark: false,
                            avatar: Icon(
                              filterIcon,
                              size: 18,
                              color: isSelected ? myBlue60 : Colors.white,
                            ),
                            labelPadding:
                                const EdgeInsets.only(left: -4, right: 4),
                            label: Text(
                              filterText,
                              style: GoogleFonts.plusJakartaSans(
                                color: isSelected ? myBlue60 : Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                            backgroundColor: myBlue60,
                            selectedColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color:
                                    isSelected ? myBlue60 : Colors.grey[300]!,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredClients.length,
              itemBuilder: (context, index) {
                final client = filteredClients[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ClientDetailPage(client: client),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CustomUserProfileImage(
                                imageUrl: client['clientProfileImageUrl'],
                                name: client['clientFullName'] ??
                                    client['clientName'],
                                size: 48,
                                borderRadius: 12,
                                backgroundColor:
                                    theme.brightness == Brightness.dark
                                        ? myGrey70
                                        : myGrey30,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  client['clientFullName'] ??
                                                      client['clientName'],
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme.bodyLarge
                                                      ?.copyWith(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              if (client['clientId'] ==
                                                  userTrainerClientId) ...[
                                                const SizedBox(width: 4),
                                                Text(
                                                  '(${l10n.you})',
                                                  style: theme
                                                      .textTheme.bodyMedium
                                                      ?.copyWith(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                )
                                              ],
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            if (client['lastActivity'] !=
                                                null) ...[
                                              Text(
                                                _getLastActivityText(
                                                    client['lastActivity'],
                                                    l10n),
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  fontSize: 12,
                                                  color: myBlue60,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                            if (client['connectionType'] ==
                                                    'app' &&
                                                client['clientId'] !=
                                                    userTrainerClientId) ...[
                                              const SizedBox(height: 4),
                                              IconButton(
                                                onPressed: () {
                                                  final otherUserId =
                                                      client['clientId']
                                                              as String? ??
                                                          '';
                                                  if (otherUserId.isEmpty) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      CustomSnackBar.show(
                                                        title:
                                                            l10n.direct_message,
                                                        message: l10n
                                                            .invalid_chat_data,
                                                        type:
                                                            SnackBarType.error,
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  _markAsRead(
                                                      userData?['userId'] ?? '',
                                                      otherUserId);
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          DirectMessagePage(
                                                        otherUserId:
                                                            otherUserId,
                                                        otherUserName:
                                                            client['clientFullName']
                                                                    as String? ??
                                                                'Unknown',
                                                        chatType: 'client',
                                                        otherUserProfileImageUrl:
                                                            client['clientProfileImageUrl']
                                                                    as String? ??
                                                                '',
                                                      ),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.message_outlined,
                                                  size: 20,
                                                  color: myBlue60,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: client['connectionType'] == 'app'
                                            ? myBlue20
                                            : theme.brightness ==
                                                    Brightness.light
                                                ? myGrey20
                                                : myGrey80,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        client['connectionType'] == 'app'
                                            ? l10n.app_user
                                            : l10n.manual,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color:
                                              client['connectionType'] == 'app'
                                                  ? myBlue60
                                                  : theme.brightness ==
                                                          Brightness.light
                                                      ? myGrey60
                                                      : myGrey40,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (client['goal'] != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        client['goal'],
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (client['nextSession'] != null) ...[
                            if ((client['nextSession'] as Timestamp)
                                .toDate()
                                .isAfter(DateTime.now())) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: myBlue60,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.next_session(
                                        DateFormat('MMM d, y • HH:mm').format(
                                            (client['nextSession'] as Timestamp)
                                                .toDate())),
                                    style: GoogleFonts.plusJakartaSans(
                                      color: myBlue60,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsRead(String myId, String otherUserId) async {
    final FirebaseFirestore myFirestore = FirebaseFirestore.instance;
    try {
      await myFirestore
          .collection('messages')
          .doc(myId)
          .collection('last_messages')
          .doc(otherUserId)
          .update({'read': true});
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  String _getLastActivityText(Timestamp? lastActivity, AppLocalizations l10n) {
    if (lastActivity == null) return '';

    final now = DateTime.now();
    final activityTime = lastActivity.toDate();
    final difference = now.difference(activityTime);

    if (difference.inMinutes < 60) {
      return '${l10n.active} ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${l10n.active} ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${l10n.active} ${difference.inDays}d';
    } else if (difference.inDays < 30) {
      return '${l10n.active} ${(difference.inDays / 7).floor()}w';
    } else {
      return '${l10n.active} ${(difference.inDays / 30).floor()}mo';
    }
  }
}
