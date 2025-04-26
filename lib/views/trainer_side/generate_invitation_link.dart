import 'package:naturafit/services/invitation/invitation_bloc.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/views/trainer_side/add_client_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GenerateInviteLinkPage extends StatelessWidget {
  const GenerateInviteLinkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userData = context.read<UserProvider>().userData;
    final l10n = AppLocalizations.of(context)!;

    final screenWidth = MediaQuery.of(context).size.width;
    final generateSize = screenWidth * 0.175;
    final iconSize = screenWidth * 0.1;
    final generateLargerPadding = screenWidth * 0.085;
    final generateSmallerPadding = screenWidth * 0.042;
    final fadeRadius = screenWidth * 0.075;
    final buttonRadius = screenWidth * 0.035;

    return Scaffold(
      backgroundColor: myGrey10,
      body: BlocListener<InvitationBloc, InvitationState>(
        listener: (context, state) {
          if (state is InvitationGenerated) {
            _showInvitationDialog(context, state);
          }
        },
        child: Container(
          color: myGrey80,
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Top spacer
                  //const Spacer(),

                  // Icon and main text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scale: 1.5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: myGrey50.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(fadeRadius * 3.5),
                          ),
                          child: Container(
                            margin: EdgeInsets.all(generateLargerPadding),
                            decoration: BoxDecoration(
                              color: myGrey50.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(fadeRadius * 2.5),
                            ),
                            child: Container(
                              margin: EdgeInsets.all(generateLargerPadding),
                              decoration: BoxDecoration(
                                color: myGrey50.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(fadeRadius * 2),
                              ),
                              child: Container(
                                margin: EdgeInsets.all(generateLargerPadding),
                                decoration: BoxDecoration(
                                  color: myGrey50.withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(fadeRadius * 1.5),
                                ),
                                child: Container(
                                  margin: EdgeInsets.all(generateLargerPadding),
                                  decoration: BoxDecoration(
                                    color: myGrey50.withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(fadeRadius),
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      // Handle tap
                                      debugPrint('Generate Invitation Link');
                                      if (userData != null) {
                                        debugPrint(
                                            'userId: ${userData['userId']}');
                                        context.read<InvitationBloc>().add(
                                              GenerateInvitation(
                                                trainerClientId:
                                                    userData['trainerClientId'] ?? '',
                                                professionalId:
                                                    userData['userId'] ?? '',
                                                professionalUsername:
                                                    userData[fbRandomName] ??
                                                        'User',
                                                professionalFullName: userData[
                                                        fbFullName] ??
                                                    userData[fbRandomName] ??
                                                    'User',
                                                professionalProfileImageUrl:
                                                    userData[
                                                            fbProfileImageURL] ??
                                                        '',
                                                role: userData['role'] ?? '',
                                              ),
                                            );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          CustomSnackBar.show(
                                            title:
                                                l10n.generate_invitation_link,
                                            message:
                                                l10n.user_data_not_available,
                                            type: SnackBarType.error,
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      margin: EdgeInsets.all(
                                          generateSmallerPadding),
                                      decoration: BoxDecoration(
                                        color: myGrey50,
                                        borderRadius:
                                            BorderRadius.circular(buttonRadius),
                                      ),
                                      child: Container(
                                        width: generateSize,
                                        height: generateSize,
                                        margin: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                              color: myGrey60, width: 1),
                                          borderRadius: BorderRadius.circular(
                                              buttonRadius),
                                        ),
                                        child: Icon(
                                          Icons.link_rounded,
                                          size: iconSize,
                                          color: myBlue60,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  //const Spacer(),
                ],
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: generateSize * 2.5),
                        child: Text(
                          l10n.generate_invitation_link,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 64),
                  Container(
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
                ],
              ),

              // Or Add Manually Button
              Column(
                children: [
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddClientPage(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.or_add_manually,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.person_add_alt_1_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Bottom spacing
                  const SizedBox(height: 72),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInvitationDialog(BuildContext context, InvitationGenerated state) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
              color: theme.brightness == Brightness.dark ? myGrey60 : myGrey30),
        ),
        child: Container(
          width: 400, // Fixed width for web dialog
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.share_invitation,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white
                          : myGrey80,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white70
                          : myGrey60,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Message
              Text(
                l10n.share_link_message,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: theme.brightness == Brightness.dark
                      ? Colors.white70
                      : myGrey60,
                ),
              ),
              const SizedBox(height: 16),

              // Link Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      theme.brightness == Brightness.dark ? myGrey70 : myGrey10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.brightness == Brightness.dark
                        ? myGrey60
                        : myGrey30,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.webLink,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : myGrey80,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final message = '''${l10n.coachtrack_invitation}

${l10n.join_me_on_coachtrack}

${l10n.click_here_to_join}
${state.webLink}

${l10n.or_enter_this_invitation_code}
${state.inviteCode}

${l10n.dont_have_the_app_yet}
${l10n.android_store_link(state.androidStoreLink)}
${l10n.ios_store_link(state.iOSStoreLink)}''';

                        Clipboard.setData(ClipboardData(text: message));
                        ScaffoldMessenger.of(context).showSnackBar(
                          CustomSnackBar.show(
                            title: l10n.invitation_link,
                            message: l10n.copied_to_clipboard,
                            type: SnackBarType.success,
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.copy,
                        size: 20,
                        color: theme.brightness == Brightness.dark
                            ? Colors.white70
                            : myGrey60,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Share buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // WhatsApp button
                  OutlinedButton.icon(
                    onPressed: () => _shareLink(state, 'whatsapp', context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.message,
                        color: Colors.green, size: 20),
                    label: Text(
                      l10n.whatsapp,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Share button
                  ElevatedButton.icon(
                    onPressed: () => _shareLink(state, 'share', context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: myBlue60,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon:
                        const Icon(Icons.share, color: Colors.white, size: 20),
                    label: Text(
                      l10n.share,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareLink(
      InvitationGenerated state, String method, BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final message = '''${l10n.coachtrack_invitation}

${l10n.join_me_on_coachtrack}

${l10n.click_here_to_join}
${state.webLink}

${l10n.or_enter_this_invitation_code}
${state.inviteCode}

${l10n.dont_have_the_app_yet}
${l10n.android_store_link(state.androidStoreLink)}
${l10n.ios_store_link(state.iOSStoreLink)}''';

/*
    final message = l10n.join_message(
      state.webLink,
      state.androidStoreLink,
      state.iOSStoreLink,
    );
    */

    switch (method) {
      case 'whatsapp':
        final whatsappUrl =
            "whatsapp://send?text=${Uri.encodeComponent(message)}";
        if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
          await launchUrl(Uri.parse(whatsappUrl));
        }
        break;
      case 'share':
        await Share.share(message);
        break;
    }
  }
}
