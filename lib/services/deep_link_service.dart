// deep_link_service.dart
import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/invitation/connections_bloc.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/views/web/landing_page.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:naturafit/services/invitation/invitation_bloc.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/services/auth/bloc/my_auth_bloc.dart';
import 'package:naturafit/views/auth_side/welcome_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  final navigationKey = GlobalKey<NavigatorState>();

  String? pendingCode;
  String? pendingProfessionalUsername;
  String? pendingProfessionalFullName;
  String? pendingProfessionalId;
  String? pendingProfessionalProfileImageUrl;
  String? pendingProfessionalRole;

  void handleInviteLink(Uri uri, BuildContext context) async {
    debugPrint('🔗 Processing deep link: ${uri.toString()}');
    
    // Ensure we have a valid context with localizations
    if (!context.mounted) return;
    
    // Safely access localizations with null check and fallback
    final l10n = AppLocalizations.of(context);
    /*
    if (l10n == null) {
      debugPrint('❌ Localizations not available');
      // Use fallback error messages if localizations are not available
      _showError('Error processing invitation link', context);
      return;
    }
    */

    final code = uri.queryParameters['code'];
    final professional = uri.queryParameters['professional'];

    // Get the current auth state
    final authState = context.read<AuthBloc>().state;

    // Only proceed if user is authenticated
    if (authState is! AuthAuthenticated) {
      _navigateToWelcome();
      return;
    }

    // Get fresh user data from UserProvider
    final currentUserData = context.read<UserProvider>().userData;
    final currentUserRole = currentUserData?['role'];

    debugPrint('Current user role: $currentUserRole');

    if (code != null) {
      try {
        // Validate role first
        if (currentUserRole == 'trainer' || currentUserRole == 'dietitian') {
          _showError(l10n?.professionals_cannot_accept_client_invitations ?? 'Professionals cannot accept client invitations', context);
          return;
        }

        final invitationBloc = BlocProvider.of<InvitationBloc>(context);
        invitationBloc.add(ValidateInvitation(
          code: code,
          currentUserRole: currentUserRole ?? '',
          currentUserId: currentUserData?['userId'] ?? '',
        ));

        await for (final state in invitationBloc.stream) {
          if (!context.mounted) return;

          if (state is InvitationValidated) {
            debugPrint('✅ Invitation validated successfully');

            // Store pending data
            pendingCode = code;
            pendingProfessionalUsername =
                state.inviteData['professionalUsername'];
            pendingProfessionalFullName =
                state.inviteData['professionalFullName'];
            pendingProfessionalProfileImageUrl =
                state.inviteData['professionalProfileImageUrl'];
            pendingProfessionalId = state.inviteData['professionalId'];
            pendingProfessionalRole = state.inviteData['role'];

            // Update Firestore
            await FirebaseFirestore.instance
                .collection('invites')
                .doc(code)
                .update({
              'lastAccessed': FieldValue.serverTimestamp(),
              'status': 'clicked',
            });

            // Store invite data in UserProvider
            if (context.mounted) {
              Provider.of<UserProvider>(context, listen: false).setInviteData({
                'code': code,
                'professional': professional ?? '',
                'professionalId': state.inviteData['professionalId'] ?? '',
                'role': state.inviteData['role'] ?? '',
              });
            }

            // Show invite dialog for client
            if (navigationKey.currentContext != null) {
              invitationDialog(context, professional ?? '');
            }
          } else if (state is InvitationError) {
            debugPrint('❌ Invitation validation error: ${state.message}');
            _showError(state.message, context);
            break;
          }
        }
      } catch (e) {
        debugPrint('❌ Error processing invite: $e');
        _showError(l10n?.error_processing_invitation ?? 'Error processing invitation', context);
      }
    } else {
      debugPrint('❌ No invite code in URI');
      _showError(l10n?.invalid_invitation_link ?? 'Invalid invitation link', context);
    }
  }

  void invitationDialog(BuildContext context, String professional) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    showDialog(
      context: navigationKey.currentContext!,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.training_invitation ?? 'Training Invitation',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n?.you_have_been_invited_by(professional) ?? 'You have been invited by $professional. Would you like to accept?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: theme.brightness == Brightness.light 
                    ? myGrey60 
                    : myGrey40,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _clearPendingInvite();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n?.not_now ?? 'Not Now',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: theme.brightness == Brightness.light 
                          ? myGrey60 
                          : myGrey40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        debugPrint('Starting acceptance process...');
                        if (pendingCode != null && pendingProfessionalId != null) {
                          final userData = Provider.of<UserProvider>(dialogContext, listen: false).userData;
                          final userId = userData?['userId'];
                          final userRole = userData?['role'];
                          

                          // Check if invitation exists and is still valid
                          final inviteDoc = await FirebaseFirestore.instance
                              .collection('invites')
                              .doc(pendingCode)
                              .get();

                          if (!inviteDoc.exists) {
                            throw l10n?.invalid_invitation_code ?? 'Invalid invitation code';
                          }

                          final inviteData = inviteDoc.data()!;

                          // Validate that trainer is not trying to connect with themselves
                          if (inviteData['trainerClientId'] == userId) {
                            throw l10n?.cannot_connect_with_yourself ?? 'You cannot connect with yourself';
                          }

                          if (inviteData['used'] == true) {
                            throw l10n?.invitation_code_already_used ?? 'This invitation code has already been used';
                          }

                          // Check for existing connection
                          final existingConnection = await FirebaseFirestore.instance
                              .collection('connections')
                              .doc('client')
                              .collection(userId)
                              .doc(pendingProfessionalId)
                              .get();

                          if (existingConnection.exists) {
                            throw l10n?.already_have_connection_with_professional ?? 'You already have a connection with this professional';
                          }

                          if (userRole == 'trainer') {
                            throw l10n?.trainers_cannot_connect_to_other_trainers ?? 'Trainers cannot connect to other trainers';
                          }

                          // Update invite status
                          await FirebaseFirestore.instance
                              .collection('invites')
                              .doc(pendingCode)
                              .update({
                            'status': fbClientConfirmedStatus,
                            'used': true,
                            'acceptedAt': FieldValue.serverTimestamp(),
                          });
                          debugPrint('Updated invite status');

                          if (dialogContext.mounted) {
                            final inviteData = Provider.of<UserProvider>(dialogContext, listen: false).inviteData;

                            if (inviteData != null && userData != null) {
                              debugPrint('Creating connection...');
                              // Create the connection using ConnectionsBloc
                              BlocProvider.of<ConnectionsBloc>(dialogContext)
                                  .add(
                                AcceptInvitation(
                                  clientId: userData['userId'],
                                  clientName: userData[fbRandomName] ?? '',
                                  professionalId: pendingProfessionalId!,
                                  professionalRole: inviteData['role'] ?? '',
                                  professionalUsername:
                                      pendingProfessionalUsername ?? '',
                                  professionalFullName:
                                      pendingProfessionalFullName ??
                                          pendingProfessionalUsername ??
                                          '',
                                  professionalProfileImageUrl:
                                      pendingProfessionalProfileImageUrl ??
                                          '',
                                ),
                              );

                              // Add the new professional to UserProvider
                              final newProfessional = {
                                'professionalId': pendingProfessionalId,
                                'professionalUsername': pendingProfessionalUsername,
                                'professionalFullName': pendingProfessionalFullName ?? pendingProfessionalUsername,
                                'professionalProfileImageUrl': pendingProfessionalProfileImageUrl,
                                'role': inviteData['role'],
                                'status': fbClientConfirmedStatus,
                                'timestamp': DateTime.now().millisecondsSinceEpoch,
                              };

                              final userProvider = Provider.of<UserProvider>(dialogContext, listen: false);
                              final currentProfessionals = List<Map<String, dynamic>>.from(
                                userProvider.partiallyTotalProfessionals ?? []
                              );
                              currentProfessionals.add(newProfessional);
                              userProvider.setPartiallyTotalProfessionals(currentProfessionals);

                              // Show success message
                              ScaffoldMessenger.of(dialogContext)
                                  .showSnackBar(
                                CustomSnackBar.show(
                                  title: l10n?.connection_invitation ?? 'Connection Invitation',
                                  message: l10n?.connection_created_successfully ?? 'Connection created successfully',
                                  type: SnackBarType.success,
                                ),
                              );
                            }
                            Navigator.pop(dialogContext);
                          }
                          _clearPendingInvite();
                        }
                      } catch (e) {
                        debugPrint('Error accepting invitation: $e');
                        _showError(e.toString(), dialogContext);
                        Navigator.pop(dialogContext);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: myBlue60,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n?.accept ?? 'Accept',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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

  void _clearPendingInvite() {
    pendingCode = null;
    pendingProfessionalUsername = null;
    pendingProfessionalFullName = null;
    pendingProfessionalId = null;
    pendingProfessionalRole = null;
  }

  void _showError(String message, BuildContext context) {
    if (navigationKey.currentContext != null) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(navigationKey.currentContext!).showSnackBar(
        CustomSnackBar.show(
          title: l10n?.connection_invitation ?? 'Connection Invitation',
          message: message,
          type: SnackBarType.error,
        ),
      );
    }
  }

  void _navigateToWelcome() {
    if (navigationKey.currentState != null) {
      navigationKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => kIsWeb ? const LandingPage() : const WelcomeScreen(),),
        (route) => false,
      );
    }
  }

  Future<void> initDeepLinks(BuildContext context) async {
    try {
      debugPrint('🚀 Initializing deep link handling');

      final uri = await _appLinks.getInitialLink();
      debugPrint('📥 Initial URI: $uri');
      if (uri != null) {
        handleInviteLink(uri, context);
      }

      _appLinks.uriLinkStream.listen(
        (uri) {
          debugPrint('📨 Received URI from stream: $uri');
          if (uri != null) {
            handleInviteLink(uri, context);
          }
        },
        onError: (err) {
          debugPrint('❌ Deep link stream error: $err');
        },
      );
    } catch (e) {
      debugPrint('❌ Deep link initialization error: $e');
    }
  }
}
