import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_select_textfield.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:naturafit/services/firebase_service.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _categoryController = TextEditingController();
  String _selectedCategory = 'Technical Issue';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Technical Issue',
    'Account Problem',
    'Billing Question',
    'Feature Request',
    'Bug Report',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _categoryController.text = _selectedCategory;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final userData = context.read<UserProvider>().userData;
      final userEmail = userData?['email'] as String? ?? '';
      final userName = userData?['fullName'] as String? ?? '';
      final userId = userData?['userId'] as String? ?? '';

      await FirebaseService().createDocument(
        'support_tickets',
        {
          'category': _selectedCategory,
          'subject': _subjectController.text,
          'message': _messageController.text,
          'userEmail': userEmail,
          'userName': userName,
          'status': 'open',
          'createdAt': DateTime.now(),
          'userId': userId,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
                                    title: l10n.support_ticket,
                                    message: l10n.ticket_submitted_successfully,
                                    type: SnackBarType.success,
                                  ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
                                    title: l10n.support_ticket,
                                    message: l10n.error_submitting_ticket,
                                    type: SnackBarType.error,
                                  ),
        );
            
      }
    } finally {
      setState(() => _isSubmitting = false);
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
        title: Text(l10n.submit_support_ticket,
            style: GoogleFonts.plusJakartaSans(
              color: theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            )),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             
              const SizedBox(height: 24),

              CustomSelectTextField(
                label: l10n.category,
                hintText: '',
                controller: _categoryController,
                options: _categories,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _categoryController.text = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              CustomFocusTextField(
                label: l10n.subject,
                hintText: l10n.please_enter_subject,
                controller: _subjectController,
                isRequired: false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.please_enter_subject;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              CustomFocusTextField(
                label: l10n.message,
                hintText: l10n.please_enter_message,
                controller: _messageController,
                isRequired: true,
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar.show(
                                    title: l10n.support_ticket,
                                    message: l10n.please_enter_message,
                                    type: SnackBarType.error,
                                  ),
                    );
                    
                    return l10n.please_enter_message;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: myBlue60,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(l10n.submit_ticket,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
