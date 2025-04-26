import 'package:naturafit/widgets/custom_consent_checkbox.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/services/firebase_service.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ClientSensitiveDataPage extends StatefulWidget {
  final Map<String, bool> initialConsentSettings;
  
  const ClientSensitiveDataPage({
    super.key,
    required this.initialConsentSettings,
  });

  @override
  State<ClientSensitiveDataPage> createState() => _ClientSensitiveDataPageState();
}

class _ClientSensitiveDataPageState extends State<ClientSensitiveDataPage> {
  bool _hasUnsavedChanges = false;
  late bool _consentBirthday;
  late bool _consentEmail;
  late bool _consentPhone;
  late bool _consentLocation;
  late bool _consentSocialMedia;
  late bool _consentMeasurements;
  late bool _consentProgressPhotos;

  @override
  void initState() {
    super.initState();
    // Initialize consent values from widget
    _consentBirthday = widget.initialConsentSettings['birthday'] ?? false;
    _consentEmail = widget.initialConsentSettings['email'] ?? false;
    _consentPhone = widget.initialConsentSettings['phone'] ?? false;
    _consentLocation = widget.initialConsentSettings['location'] ?? false;
    _consentSocialMedia = widget.initialConsentSettings['socialMedia'] ?? false;
    _consentMeasurements = widget.initialConsentSettings['measurements'] ?? false;
    _consentProgressPhotos = widget.initialConsentSettings['progressPhotos'] ?? false;
  }

  void _checkForChanges() {
    final initialSettings = widget.initialConsentSettings;
    final currentSettings = {
      'birthday': _consentBirthday,
      'email': _consentEmail,
      'phone': _consentPhone,
      'location': _consentLocation,
      'socialMedia': _consentSocialMedia,
      'measurements': _consentMeasurements,
      'progressPhotos': _consentProgressPhotos,
    };

    bool areEqual = initialSettings.entries.every(
      (entry) => currentSettings[entry.key] == entry.value
    );

    setState(() {
      _hasUnsavedChanges = !areEqual;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: theme.brightness == Brightness.light ? Colors.black : Colors.white, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.chevron_left, color: theme.brightness == Brightness.light ? Colors.black : Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          l10n.sensitive_data_page_title,
          style: GoogleFonts.plusJakartaSans(
            color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: _hasUnsavedChanges
              ? () async {
                  try {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(color: myBlue60),
                      ),
                    );

                    final consentSettings = {
                      'birthday': _consentBirthday,
                      'email': _consentEmail,
                      'phone': _consentPhone,
                      'location': _consentLocation,
                      'socialMedia': _consentSocialMedia,
                      'measurements': _consentMeasurements,
                      'progressPhotos': _consentProgressPhotos,
                    };

                    // Update data in Firebase
                    if (context.mounted) {
                      await FirebaseService().updateUser({
                        'consentSettings': consentSettings,
                      }, context);
                    }

                    // Update UserProvider
                    if (context.mounted) {
                      final userProvider = context.read<UserProvider>();
                      final currentData = Map<String, dynamic>.from(userProvider.userData ?? {});
                      currentData['consentSettings'] = consentSettings;
                      userProvider.setUserData(currentData);

                      Navigator.pop(context); // Close loading dialog
                      Navigator.pop(context); // Return to settings page
                    }
                  } catch (e) {
                    if (context.mounted && Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }

                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.update_failed),
                          content: Text(e.toString()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(l10n.ok),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                }
              : null,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: _hasUnsavedChanges ? myBlue30 : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                margin: const EdgeInsets.all(3),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _hasUnsavedChanges ? myBlue60 : myGrey30,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.save,
                  style: GoogleFonts.plusJakartaSans(
                    color: _hasUnsavedChanges ? Colors.white : myGrey60,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _buildConsentStep(),
    );
  }

  Widget _buildConsentStep() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.data_sharing_consent_title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                ),
              ),
              const SizedBox(height: 12),
              CustomConsentCheckbox(
                title: l10n.birthday_consent_title,
                description: l10n.birthday_consent_desc,
                value: _consentBirthday,
                onChanged: (value) {
                  setState(() => _consentBirthday = value);
                  _checkForChanges();
                },
                icon: Icons.cake_outlined,
              ),
              CustomConsentCheckbox(
                title: l10n.email_consent_title,
                description: l10n.email_consent_desc,
                value: _consentEmail,
                onChanged: (value) {
                  setState(() => _consentEmail = value);
                  _checkForChanges();
                },
                icon: Icons.email_outlined,
              ),
              CustomConsentCheckbox(
                title: l10n.phone_consent_title,
                description: l10n.phone_consent_desc,
                value: _consentPhone,
                onChanged: (value) {
                  setState(() => _consentPhone = value);
                  _checkForChanges();
                },
                icon: Icons.phone_outlined,
              ),
              CustomConsentCheckbox(
                title: l10n.location_consent_title,
                description: l10n.location_consent_desc,
                value: _consentLocation,
                onChanged: (value) {
                  setState(() => _consentLocation = value);
                  _checkForChanges();
                },
                icon: Icons.location_on_outlined,
              ),
              CustomConsentCheckbox(
                title: l10n.social_media_consent_title,
                description: l10n.social_media_consent_desc,
                value: _consentSocialMedia,
                onChanged: (value) {
                  setState(() => _consentSocialMedia = value);
                  _checkForChanges();
                },
                icon: Icons.share_outlined,
              ),
              CustomConsentCheckbox(
                title: l10n.measurements_consent_title,
                description: l10n.measurements_consent_desc,
                value: _consentMeasurements,
                onChanged: (value) {
                  setState(() => _consentMeasurements = value);
                  _checkForChanges();
                },
                icon: Icons.straighten_outlined,
              ),
              CustomConsentCheckbox(
                title: l10n.progress_photos_consent_title,
                description: l10n.progress_photos_consent_desc,
                value: _consentProgressPhotos,
                onChanged: (value) {
                  setState(() => _consentProgressPhotos = value);
                  _checkForChanges();
                },
                icon: Icons.photo_camera_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 