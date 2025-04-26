import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactInfoPage extends StatelessWidget {
  const ContactInfoPage({super.key});

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
                                    title: l10n.contact_information,
                                    message: l10n.copied_to_clipboard,
                                    type: SnackBarType.success,
                                  ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.brightness == Brightness.light 
                  ? Colors.black 
                  : Colors.white,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.chevron_left,
              color: theme.brightness == Brightness.light 
                  ? Colors.black 
                  : Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          l10n.contact_information,
          style: GoogleFonts.plusJakartaSans(
            color: theme.brightness == Brightness.light 
                ? Colors.black 
                : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: myBlue60,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.fitness_center,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            
            // App Version
            Text(
              'NaturaFit v1.0.0',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),

            // Contact Information Cards
            _buildContactCard(
              context,
              icon: Icons.phone_outlined,
              title: '+1 (555) 123-4567',
              onTap: () => _launchUrl('tel:+15551234567'),
              onLongPress: () => _copyToClipboard(context, '+15551234567'),
            ),
            
            _buildContactCard(
              context,
              icon: Icons.email_outlined,
              title: 'support@naturafit.app',
              onTap: () => _launchUrl('mailto:support@naturafit.app'),
              onLongPress: () => _copyToClipboard(context, 'support@naturafit.app'),
            ),
            
            _buildContactCard(
              context,
              icon: Icons.language_outlined,
              title: 'naturafit.app',
              onTap: () => _launchUrl('https://naturafit.app'),
              onLongPress: () => _copyToClipboard(context, 'https://naturafit.app'),
            ),

            _buildContactCard(
              context,
              icon: Icons.location_on_outlined,
              title: '123 Fitness Street\nHealth District\nNew York, NY 10001',
              onTap: () => _launchUrl('https://maps.google.com/?q=123+Fitness+Street+NY'),
              onLongPress: () => _copyToClipboard(context, '123 Fitness Street, Health District, New York, NY 10001'),
            ),

            const SizedBox(height: 16),

            // Social Media Section
            Text(
              l10n.follow_us,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Social Media Icons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(
                  icon: Icons.facebook,
                  onTap: () => _launchUrl('https://facebook.com/naturafit'),
                ),
                _buildSocialButton(
                  icon: Icons.camera_alt_outlined,
                  onTap: () => _launchUrl('https://instagram.com/naturafit'),
                ),
                _buildSocialButton(
                  icon: Icons.telegram,
                  onTap: () => _launchUrl('https://t.me/naturafit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: myBlue60.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: myBlue60),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: myBlue60,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
} 