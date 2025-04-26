import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:naturafit/models/feedback_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
class FeedbackSheet extends StatefulWidget {
  const FeedbackSheet({super.key});

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  final List<Map<String, dynamic>> _areas = [
    {'title': 'Performance', 'selected': false, 'color': myBlue50},
    {'title': 'Bug', 'selected': false, 'color': myRed50},
    {'title': 'UI', 'selected': false, 'color': myTeal50},
    {'title': 'UX', 'selected': false, 'color': myGreen50},
    {'title': 'Crashes', 'selected': false, 'color': const Color(0xFFFF8C42)},
    {'title': 'Loading', 'selected': false, 'color': const Color(0xFF96CEB4)},
    {'title': 'Support', 'selected': false, 'color': const Color(0xFFD4A5A5)},
    {'title': 'Security', 'selected': false, 'color': const Color(0xFF3F72AF)},
    {'title': 'Pricing', 'selected': false, 'color': const Color(0xFF9B5DE5)},
    {'title': 'Animation', 'selected': false, 'color': const Color(0xFFF15BB5)},
    {'title': 'Design', 'selected': false, 'color': const Color(0xFF00BBF9)},
    {'title': 'Marketing', 'selected': false, 'color': myYellow40},
  ];

  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  String _currentText = '';

  bool get _isValid {
    final hasSelectedArea = _areas.any((area) => area['selected']);
    final hasText = _currentText.trim().isNotEmpty;
    return hasSelectedArea || hasText;
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final l10n = AppLocalizations.of(context)!;
    final selectedAreas = _areas
        .where((area) => area['selected'])
        .map((area) => area['title'] as String)
        .toList();
    
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      

      final feedback = FeedbackModel(
        userId: user.uid,
        areas: selectedAreas,
        message: _feedbackController.text.trim(),
        timestamp: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('feedback')
          .add(feedback.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
                                    title: l10n.feedback,
                                    message: l10n.thank_you_for_your_feedback,
                                    type: SnackBarType.success,
                                  ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
                                    title: l10n.feedback,
                                    message: l10n.error_submitting_feedback(e.toString()),
                                    type: SnackBarType.error,
                                  ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light ? myGrey40 : myGrey60,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Text(
              'Which Of The Area\nNeeds Improvement?',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
              ),
            ),
          ),

          // Areas grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: _areas.map((area) {

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        area['selected'] = !area['selected'];
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: area['selected'] ? area['color'].withOpacity(0.4) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: area['selected'] ? area['color'] : theme.brightness == Brightness.light ? myGrey20 : myGrey80,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(area['title'],
                         style: GoogleFonts.plusJakartaSans(
                          color: area['selected'] ? Colors.white : theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                         ),),
                      ),
                    ),
                  );

                  
                }).toList(),
              ),
            ),
          ),



          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: CustomFocusTextField(
              hintText: 'Enter your feedback..',
              label: '',
              controller: _feedbackController,
              maxLines: 4,
              prefixIcon: Icons.feedback_outlined,
              onChanged: (value) {
                setState(() {
                  _currentText = value;
                });
              },
            ),
          ),



          // Submit button
          Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, MediaQuery.of(context).padding.bottom + 16),
            child: ElevatedButton(
              onPressed: _isSubmitting || !_isValid ? null : _submitFeedback,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.disabled)) {
                    return myGrey40;
                  }
                  return myBlue60;
                }),
                foregroundColor: WidgetStateProperty.all(Colors.white),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 16),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                overlayColor: WidgetStateProperty.all(Colors.transparent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSubmitting ? 'Submitting...' : 'Submit Feedback',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isSubmitting ? Icons.hourglass_empty : Icons.check,
                    size: 20,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ],
              ),
            ),
          ),

          






        ],
      ),
    );
  }
} 