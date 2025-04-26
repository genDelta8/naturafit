import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_user_profile_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/views/client_side/professional_slots_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BookSessionPage extends StatefulWidget {
  const BookSessionPage({super.key});

  @override
  State<BookSessionPage> createState() => _BookSessionPageState();
}

class _BookSessionPageState extends State<BookSessionPage> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Trainer', 'Dietitian'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredProfessionals {
    final professionals = context.watch<UserProvider>().partiallyTotalProfessionals ?? [];
    final filtered = professionals.where((professional) {
      // First apply the role filter
      if (_selectedFilter != 'All' && professional['role'] != _selectedFilter.toLowerCase()) {
        return false;
      }

      // Then apply the search filter
      if (_searchQuery.isNotEmpty) {
        return professional['professionalFullName']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
      }

      return true;
    }).toList();

    // Sort professionals alphabetically
    filtered.sort((a, b) {
      return a['professionalFullName'].toString().compareTo(b['professionalFullName'].toString());
    });

    return filtered;
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
        title: Text(
          l10n.book_a_session,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: myBlue60,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: myBlue60,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
            child: Column(
              children: [
                CustomFocusTextField(
                  label: '',
                  hintText: l10n.search_trainers,
                  prefixIcon: Icons.search,
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
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
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfessionalSlotsPage(
                          professional: professional,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CustomUserProfileImage(
                            imageUrl: professional['professionalProfileImageUrl'],
                            name: professional['professionalFullname'] ?? professional['professionalUsername'],
                            size: 70,
                            borderRadius: 16,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  professional['professionalFullName'],
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: theme.brightness == Brightness.light ? Colors.black87 : Colors.grey[400],
                                  ),
                                ),
                                
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: myBlue60.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_outlined,
                                            size: 16,
                                            color: myBlue60,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            l10n.view_slots,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: myBlue60,
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
                          Icon(
                            Icons.chevron_right,
                            color: theme.brightness == Brightness.light ? Colors.black54 : Colors.grey[400],
                            size: 24,
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