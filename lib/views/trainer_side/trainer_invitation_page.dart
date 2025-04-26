// generate_invite_link_page.dart
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:naturafit/services/invitation/invitation_bloc.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GenerateInviteLinkPageOldMethod extends StatelessWidget {
  const GenerateInviteLinkPageOldMethod({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InvitationBloc(),
      child: const InviteLinkView(),
    );
  }
}

class InviteLinkView extends StatelessWidget {
  const InviteLinkView({super.key});

  Future<void> _shareLink(InvitationGenerated state, String method) async {
    final message = '''Join me on NaturaFit!

Click here to join:
${state.webLink}

Don't have the app yet? Download it here:
Android: ${state.androidStoreLink}
iOS: ${state.iOSStoreLink}''';

    switch (method) {
      case 'whatsapp':
        final whatsappUrl = "whatsapp://send?text=${Uri.encodeComponent(message)}";
        if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
          await launchUrl(Uri.parse(whatsappUrl));
        }
        break;
      case 'share':
        await Share.share(message);
        break;
    }
  }

  String _getProfessionalTypeText(String role) {
    return role == 'trainer' ? 'Client' : 'Patient';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userData = context.read<UserProvider>().userData;
    final professionalType = _getProfessionalTypeText(userData?['role'] ?? 'trainer');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.generate_invite_link,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
      body: BlocConsumer<InvitationBloc, InvitationState>(
        listener: (context, state) {
          if (state is InvitationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              CustomSnackBar.show(
                title: l10n.invitation,
                message: state.message,
                type: SnackBarType.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.share_invite_link,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.generate_link_description(professionalType),
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (state is InvitationLoading)
                          const Center(child: CircularProgressIndicator(color: myBlue60))
                        else if (state is InvitationGenerated) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.app_link_label,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  state.webLink,
                                  style: GoogleFonts.plusJakartaSans(),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.web_link_label,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  state.webLink,
                                  style: GoogleFonts.plusJakartaSans(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _shareLink(state, 'whatsapp'),
                                  icon: const Icon(Icons.message),
                                  label: Text(l10n.whatsapp),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _shareLink(state, 'share'),
                                  icon: const Icon(Icons.share),
                                  label: Text(l10n.share),
                                ),
                              ),
                            ],
                          ),
                        ] else
                          ElevatedButton.icon(
                            onPressed: () {
                              if (userData != null) {
                                debugPrint('userId: ${userData['userId']}'); 
                                context.read<InvitationBloc>().add(
                                      GenerateInvitation(
                                        trainerClientId: userData['trainerClientId'] ?? '',
                                        professionalId: userData['userId'] ?? '',
                                        professionalUsername: userData[fbRandomName] ?? 'User',
                                        professionalFullName: userData[fbFullName] ?? userData[fbRandomName] ?? 'User',
                                        professionalProfileImageUrl: userData[fbProfileImageURL] ?? '',
                                        role: userData['role'] ?? '',
                                      ),
                                    );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  CustomSnackBar.show(
                                    title: l10n.invitation,
                                    message: l10n.user_data_not_available,
                                    type: SnackBarType.error,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.link),
                            label: Text(l10n.generate_link),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 0, 102, 255),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}