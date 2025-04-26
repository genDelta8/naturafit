import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_user_profile_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/views/client_side/trainer_detail_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:naturafit/widgets/custom_expandable_search.dart';

class YourTeamPage extends StatefulWidget {
  const YourTeamPage({super.key});

  @override
  State<YourTeamPage> createState() => _YourTeamPageState();
}

class _YourTeamPageState extends State<YourTeamPage> {
  String _searchQuery = '';
  String _selectedFilter = 'Active';
  late List<String> _filters;  // Changed to late initialization
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filters = ['All', 'Active', 'Completed'];  // We'll map these to translations in build
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredProfessionals {
    final professionals =
        context.watch<UserProvider>().partiallyTotalProfessionals ?? [];
    final filtered = professionals.where((professional) {
      // Apply both status and search filters
      bool matchesStatus;
      if (_selectedFilter == 'Active') {
        matchesStatus = professional['status'] == fbClientConfirmedStatus;
      } else if (_selectedFilter == 'Completed') {
        matchesStatus = professional['status'] == fbCompletedStatus;
      } else {
        // 'All' filter
        matchesStatus = true;
      }

      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        matchesSearch = professional['professionalFullName']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
      }

      return matchesStatus && matchesSearch;
    }).toList();

    // Sort professionals alphabetically
    filtered.sort((a, b) {
      return a['professionalFullName']
          .toString()
          .compareTo(b['professionalFullName'].toString());
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final userData = context.watch<UserProvider>().userData;
    final userLinkedTrainerId = userData?['linkedTrainerId'] ?? '';
    final l10n = AppLocalizations.of(context)!;

    final myProfessionals =
        context.watch<UserProvider>().partiallyTotalProfessionals ?? [];
    final confirmedProfessionals = myProfessionals
        .where(
            (professional) => professional['status'] == fbClientConfirmedStatus)
        .toList();
    final completedProfessionals = myProfessionals
        .where((professional) => professional['status'] == fbCompletedStatus)
        .toList();
    final theme = Theme.of(context);
    final myIsWebOrDektop = isWebOrDesktopCached;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: myBlue60,
            borderRadius: myIsWebOrDektop ? const BorderRadius.only(
              topLeft: Radius.circular(35),
              topRight: Radius.circular(35),
            ) : null,
          ),
          child: AppBar(
            leading: myIsWebOrDektop ? const SizedBox.shrink() : Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1),
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
                  l10n.my_team,
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
            actions: myIsWebOrDektop ? [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CustomExpandableSearch(
                  hintText: l10n.search_team,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ] : null,
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
                  hintText: l10n.search_team,
                  controller: _searchController,
                  prefixIcon: Icons.search,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                ],
                
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      // Get translated filter text
                      String filterText;
                      switch (filter) {
                        case 'All':
                          filterText = l10n.filter_all;
                          break;
                        case 'Active':
                          filterText = confirmedProfessionals.isNotEmpty
                              ? '${l10n.filter_active} (${confirmedProfessionals.length})'
                              : l10n.filter_active;
                          break;
                        case 'Completed':
                          filterText = l10n.filter_completed;
                          break;
                        default:
                          filterText = filter;
                      }
                      
                      // Get appropriate icon for each filter
                      IconData filterIcon = Icons.all_inclusive;
                      switch (filter) {
                        case 'All':
                          filterIcon = Icons.all_inclusive;
                          break;
                        case 'Active':
                          filterIcon = Icons.check_circle_outline;
                          break;
                        case 'Completed':
                          filterIcon = Icons.pause_circle_outline;
                          break;
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
                              color: isSelected ? myBlue60 : Colors.grey[300]!,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredProfessionals.length,
              itemBuilder: (context, index) {
                final professional = filteredProfessionals[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TrainerDetailPage(
                            trainer: professional,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CustomUserProfileImage(
                            imageUrl: professional['professionalProfileImageUrl'],
                            name: professional['professionalFullName'],
                            size: 48,
                            borderRadius: 12,
                            backgroundColor: theme.brightness == Brightness.dark ? myGrey70 : myGrey30,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      professional['professionalFullName'],
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                                      ),
                                    ),
                                    if (professional['professionalId'] ==
                                        userLinkedTrainerId) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '(${l10n.you})',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: theme.brightness == Brightness.light ? myGrey60 : Colors.white,
                                        ),
                                      )
                                    ]
                                  ],
                                ),
                              ],
                            ),
                          ),
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
}
