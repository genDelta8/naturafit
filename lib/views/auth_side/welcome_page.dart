import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/views/auth_side/email_auth_page.dart';
import 'package:naturafit/views/auth_side/select_role_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Container
                  Container(
                    width: 144,
                    height: 144,
                    
                    child: Image.asset(
                      theme.brightness == Brightness.light 
                          ? 'assets/lightTransparent.png'
                          : 'assets/darkTransparent.png',
                      width: 144,
                      height: 144,
                    ),
                  ),
                  const SizedBox(height: 16),
              
                  Text(
                    l10n.welcome_to_coachtrack,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.your_complete_fitness_management_solution,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
              
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmailAuthPage(isLogin: false),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 0, 102, 255),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.get_started,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        /*
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: const Icon(Icons.chevron_right, color: Colors.white, size: 24),
                        ),
                        */
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}