import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_top_selector.dart';
import 'package:naturafit/widgets/custom_user_profile_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
class ClientSelectionSheet extends StatefulWidget {
  final Function(String clientId, String clientUsername, String clientFullName,
      String connectionType, String clientProfileImageURL) onClientSelected;

  const ClientSelectionSheet({
    Key? key,
    required this.onClientSelected,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context,
    Function(String clientId, String clientUsername, String clientFullName,
            String connectionType, String clientProfileImageURL)
        onClientSelected,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClientSelectionSheet(
        onClientSelected: onClientSelected,
      ),
    );
  }

  @override
  State<ClientSelectionSheet> createState() => _ClientSelectionSheetState();
}

class _ClientSelectionSheetState extends State<ClientSelectionSheet> {
  bool showAppClients = true;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final userData = context.watch<UserProvider>().userData;
    final userTrainerClientId = userData?['trainerClientId'] ?? '';
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
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
              color: theme.brightness == Brightness.light
                  ? Colors.grey[300]
                  : myGrey60,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  l10n.select_client,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 16),
                // Toggle buttons
                CustomTopSelector(
                      options: [
                          TopSelectorOption(title: l10n.app_users),
                          TopSelectorOption(title: l10n.manual_clients)
                      ],
                      selectedIndex: showAppClients ? 0 : 1,
                      onOptionSelected: (index) =>
                          setState(() => showAppClients = index == 0)),
                const SizedBox(height: 16),
                // Search TextField
                CustomFocusTextField(
                  label: '',
                  hintText: l10n.search_clients,
                  controller: TextEditingController(),
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
                  final isAppClient =
                      client['connectionType'] == fbAppConnectionType;
                  final matchesType =
                      showAppClients ? isAppClient : !isAppClient;

                  if (!matchesType) return false;

                  final name = client['clientFullName'] ?? client['clientName'];
                  return name
                      .toString()
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase());
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredClients.length,
                  itemBuilder: (context, index) {
                    final client = filteredClients[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CustomUserProfileImage(
                        imageUrl: client['clientProfileImageUrl'],
                        name: client['clientFullName'] ?? client['clientName'],
                        size: 48,
                        borderRadius: 12,
                      ),
                      title: Row(
                        children: [
                          Text(
                            client['clientFullName'] ?? client['clientName'],
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (client['clientId'] == userTrainerClientId) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${l10n.you})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: myGrey60,
                              ),
                            )
                          ]
                        ],
                      ),
                      onTap: () {
                        debugPrint('Client selected: ${client}');
                        widget.onClientSelected(
                          client['clientId'],
                          client['clientName'],
                          client['clientFullName'] ?? client['clientName'],
                          client['connectionType'],
                          client['clientProfileImageUrl'] ?? '',
                        );
                        Navigator.pop(context);
                      },
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
