import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/views/client_side/client_side.dart';
import 'package:naturafit/views/trainer_side/coach_side.dart';
import 'package:naturafit/views/web/web_client_side.dart';
import 'package:naturafit/views/web/web_coach_side.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/views/auth_side/select_role_page.dart';
import 'package:naturafit/services/firebase_service.dart';
import 'package:naturafit/views/auth_side/forgot_password_page.dart';

class EmailAuthPage extends StatefulWidget {
  final bool isLogin;
  
  const EmailAuthPage({super.key, this.isLogin = false});

  @override
  State<EmailAuthPage> createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends State<EmailAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLogin = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.isLogin;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCredential;
      if (_isLogin) {
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        debugPrint('Storing user auth data in email auth page ${userCredential.user!.uid}');
        await _firebaseService.storeUserAuthData(
          userId: userCredential.user!.uid,
          email: _emailController.text.trim(),
          createdAt: DateTime.now(),
        );
      }

      final userId = userCredential.user!.uid;
      debugPrint('userId in email auth page: $userId');

      // Check if user already has a role
      final userData = await _firebaseService.getUserData(userId);
      
      if (mounted) {
        if (userData != null && userData['role'] != null) {
          _navigateBasedOnRole(context, userData['role']);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserTypeScreen(passedUserId: userId),
            ),
          );
        }
      }
      
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: !kIsWeb ? const SizedBox.shrink() : Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
              width: 1
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.chevron_left,
              color: theme.brightness == Brightness.light ? Colors.black : Colors.white
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isLogin ? l10n.welcome_back : l10n.create_account,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLogin
                          ? l10n.please_sign_in_to_continue
                          : l10n.please_fill_in_the_form_to_continue,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        color: theme.brightness == Brightness.dark
                            ? myGrey40
                            : myGrey60,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    CustomFocusTextField(
                      label: l10n.email,
                      hintText: l10n.enter_your_email_address,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      shouldShowBorder: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.please_enter_your_email;
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return l10n.please_enter_a_valid_email;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomFocusTextField(
                      label: l10n.password,
                      hintText: l10n.enter_your_password,
                      controller: _passwordController,
                      shouldShowBorder: true,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.please_enter_your_password;
                        }
                        if (!_isLogin && value.length < 6) {
                          return l10n.password_must_be_at_least_6_characters;
                        }
                        return null;
                      },
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: myBlue60,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _isLogin ? l10n.sign_in : l10n.sign_up,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _errorMessage = null;
                        });
                      },
                      child: Text(
                        _isLogin
                            ? l10n.dont_have_an_account_sign_up
                            : l10n.already_have_an_account_sign_in,
                        style: GoogleFonts.plusJakartaSans(
                          color: theme.brightness == Brightness.light ? myBlue60 : myGrey40,
                        ),
                      ),
                    ),
                    if (_isLogin) ...[
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordPage(),
                            ),
                          );
                        },
                        child: Text(
                          l10n.forgot_password,
                          style: GoogleFonts.plusJakartaSans(
                            color: theme.brightness == Brightness.light ? myBlue60 : myGrey40,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateBasedOnRole(BuildContext context, String role) {
    final myIsWebOrDektop = isWebOrDesktopCached;
    Widget destination;
    switch (role.toLowerCase()) {
      case 'trainer':
        destination = myIsWebOrDektop ? const WebCoachSide() : const CoachSide();
        break;
      case 'client':
        destination = myIsWebOrDektop ? const WebClientSide() : const ClientSide();
        break;
      default:
        throw Exception('Invalid role: $role');
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }
} 