import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/widgets/custom_user_profile_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:naturafit/widgets/custom_top_selector.dart';

class SessionClient {
  String? clientId;
  String clientName;
  String? fullName;
  String? profileImageUrl;
  String connectionType;
  String status;

  SessionClient({
    this.clientId,
    required this.clientName,
    this.fullName,
    this.profileImageUrl,
    required this.connectionType,
    this.status = 'pending',
  });
}

class MultipleClientSelectionSheet extends StatefulWidget {
  final List<SessionClient> selectedClients;
  final Function(List<SessionClient>) onClientsSelected;

  const MultipleClientSelectionSheet({
    Key? key,
    required this.selectedClients,
    required this.onClientsSelected,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context,
    List<SessionClient> selectedClients,
    Function(List<SessionClient>) onClientsSelected,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MultipleClientSelectionSheet(
        selectedClients: selectedClients,
        onClientsSelected: onClientsSelected,
      ),
    );
  }

  @override
  State<MultipleClientSelectionSheet> createState() =>
      _MultipleClientSelectionSheetState();
}

class _MultipleClientSelectionSheetState
    extends State<MultipleClientSelectionSheet> {
  bool showAppClients = true;
  String searchQuery = '';
  late List<SessionClient> selectedClients;

  @override
  void initState() {
    super.initState();
    selectedClients = List.from(widget.selectedClients);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light ? Colors.white : myGrey90,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light ? myGrey30 : myGrey60,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.select_clients,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.onClientsSelected(selectedClients);
                        Navigator.pop(context);
                      },
                      child: Text(
                        l10n.done,
                        style: GoogleFonts.plusJakartaSans(
                          color: myBlue60,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Replace toggle buttons with CustomTopSelector
                CustomTopSelector(
                  options: [
                    TopSelectorOption(title: l10n.app_users),
                    TopSelectorOption(title: l10n.manual_clients),
                  ],
                  selectedIndex: showAppClients ? 0 : 1,
                  onOptionSelected: (index) {
                    setState(() {
                      showAppClients = index == 0;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Search TextField
                TextField(
                  style: GoogleFonts.plusJakartaSans(
                    color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.search_clients,
                    hintStyle:
                        GoogleFonts.plusJakartaSans(color: theme.brightness == Brightness.light ? myGrey40 : myGrey60),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.brightness == Brightness.light ? myGrey30 : myGrey60),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: myBlue60),
                    ),
                    filled: true,
                    fillColor: theme.brightness == Brightness.light ? Colors.white : myGrey90,
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ],
            ),
          ),
          // Client List
          Expanded(
            child: Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                final activeClients = userProvider.partiallyTotalClients ?? [];
                final filteredClients = activeClients.where((client) {
                  final isAppClient = client['connectionType'] == fbAppConnectionType;
                  final matchesType = showAppClients ? isAppClient : !isAppClient;

                  if (!matchesType) return false;

                  final name = client['clientFullName'] ?? client['clientName'];
                  return name
                      .toString()
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase());
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 0),
                  itemCount: filteredClients.length,
                  itemBuilder: (context, index) {
                    final client = filteredClients[index];
                    final isSelected = selectedClients.any(
                        (selected) => selected.clientId == client['clientId']);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CheckboxListTile(
                        activeColor: myBlue60,
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedClients.add(SessionClient(
                                clientId: client['clientId'],
                                clientName: client['clientName'],
                                fullName: client['clientFullName'],
                                profileImageUrl: client['clientProfileImageUrl'],
                                connectionType: client['connectionType'],
                              ));
                            } else {
                              selectedClients.removeWhere((selected) =>
                                  selected.clientId == client['clientId']);
                            }
                          });
                        },
                        title: Text(
                          client['clientFullName'] ?? client['clientName'],
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        secondary: CustomUserProfileImage(
                                  imageUrl: client['clientProfileImageUrl'],
                                  name: client['clientFullName'] ?? client['clientName'],
                                  size: 48,
                                  borderRadius: 12,
                                ),
                        
                        
                        
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 