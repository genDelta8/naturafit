import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';

class ExerciseFeedbackSheet extends StatefulWidget {
  final String exerciseName;
  final List<String>? selectedAreas;
  final String? existingComment;

  const ExerciseFeedbackSheet({
    super.key,
    required this.exerciseName,
    this.selectedAreas,
    this.existingComment,
  });

  @override
  State<ExerciseFeedbackSheet> createState() => _ExerciseFeedbackSheetState();
}

class _ExerciseFeedbackSheetState extends State<ExerciseFeedbackSheet> {
  late final List<Map<String, dynamic>> _areas;
  late final TextEditingController _feedbackController;
  String _currentText = '';

  @override
  void initState() {
    super.initState();
    _areas = [
      {'title': 'Too Easy', 'selected': false, 'color': myGreen50},
      {'title': 'Too Hard', 'selected': false, 'color': myRed50},
      {'title': 'Form Issue', 'selected': false, 'color': myBlue50},
      {'title': 'Equipment', 'selected': false, 'color': myTeal50},
      {'title': 'Pain/Discomfort', 'selected': false, 'color': const Color(0xFFFF8C42)},
      {'title': 'Need Demo', 'selected': false, 'color': const Color(0xFF96CEB4)},
      {'title': 'Rest Time', 'selected': false, 'color': const Color(0xFFD4A5A5)},
      {'title': 'Sets/Reps', 'selected': false, 'color': const Color(0xFF3F72AF)},
      {'title': 'Weight Issue', 'selected': false, 'color': const Color(0xFF9B5DE5)},
      {'title': 'Alternative?', 'selected': false, 'color': const Color(0xFFF15BB5)},
      {'title': 'Great Exercise', 'selected': false, 'color': myGreen50},
      {'title': 'Need Help', 'selected': false, 'color': myYellow40},
    ];

    if (widget.selectedAreas != null) {
      for (var area in _areas) {
        area['selected'] = widget.selectedAreas!.contains(area['title']);
      }
    }

    _feedbackController = TextEditingController(text: widget.existingComment ?? '');
    _currentText = widget.existingComment ?? '';
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        border: Border.all(color: theme.brightness == Brightness.light ? Colors.transparent : myGrey70),
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
              color: theme.brightness == Brightness.light ? myGrey40 : Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              'Exercise Feedback',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Exercise name
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Text(
              widget.exerciseName,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: theme.brightness == Brightness.light ? myGrey60 : Colors.grey[400],
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
                        color: area['selected'] 
                            ? area['color'].withOpacity(0.4) 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: area['selected'] ? area['color'] : theme.brightness == Brightness.light ? myGrey20 : myGrey70,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          area['title'],
                          style: GoogleFonts.plusJakartaSans(
                            color: area['selected']
                                ? Colors.white
                                : theme.brightness == Brightness.light ? myGrey60 : Colors.grey[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Feedback text field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: CustomFocusTextField(
              hintText: 'Additional comments...',
              label: '',
              controller: _feedbackController,
              maxLines: 3,
              prefixIcon: Icons.rate_review_outlined,
              onChanged: (value) {
                setState(() {
                  _currentText = value;
                });
              },
            ),
          ),

          // Submit button
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.plusJakartaSans(
                        color: theme.brightness == Brightness.light ? myGrey60 : Colors.grey[400],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final selectedAreas = _areas
                          .where((area) => area['selected'])
                          .map((area) => area['title'] as String)
                          .toList();
                          
                      Navigator.pop(
                        context,
                        {
                          'areas': selectedAreas,
                          'comment': _feedbackController.text.trim(),
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: myBlue60,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 