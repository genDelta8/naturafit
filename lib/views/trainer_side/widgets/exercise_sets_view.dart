import 'package:naturafit/models/exercise_set.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/views/trainer_side/create_workout_plan_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ExerciseSetsView extends StatelessWidget {
  final List<ExerciseSet> exerciseSets;
  final Function(ExerciseSet) onAddSet;
  final Function(int) onRemoveSet;
  final Function(void Function()) setModalState;
  final Function()? onSetChanged;

  const ExerciseSetsView({
    Key? key,
    required this.exerciseSets,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.setModalState,
    this.onSetChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const boxHeight = 66.0;
    final userData = Provider.of<UserProvider>(context).userData;
    final weightUnit = userData?['weightUnit'];
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Table structure
        Row(
          children: [
            // Set Numbers Column
            SizedBox(
              width: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Set',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 0),
                  ...List.generate(
                      exerciseSets.length,
                      (index) => Container(
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(top: 8),
                            height: boxHeight,
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          )),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Reps Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Reps',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 0),
                  ...exerciseSets.map((set) => Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(top: 8),
                        height: boxHeight,
                        child: SizedBox(
                          height: boxHeight,
                          child: CustomFocusTextField(
                              label: '',
                              hintText: '12',
                              height: boxHeight,
                              controller: set.repsController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => onSetChanged?.call()),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Weight Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    l10n.weight_unit(weightUnit == 'lbs' ? 'lbs' : 'kg'),
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 12
                    )
                  ),
                  const SizedBox(height: 0),
                  ...exerciseSets.map((set) => Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(top: 8),
                        height: boxHeight,
                        child: SizedBox(
                          height: boxHeight,
                          child: CustomFocusTextField(
                              label: '',
                              hintText: '20',
                              height: boxHeight,
                              controller: set.weightController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => onSetChanged?.call()),
                        ),
                          
                        
                      )),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Rest Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    l10n.rest,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 12
                    )
                  ),
                  const SizedBox(height: 0),
                  ...exerciseSets.map((set) => Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(top: 8),
                        height: boxHeight,
                        child: SizedBox(
                          height: boxHeight,
                          child: CustomFocusTextField(
                              label: '',
                              hintText: '60s',
                              height: boxHeight,
                              controller: set.restController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => onSetChanged?.call()),
                        ),
                          
                        
                      )),
                ],
              ),
            ),

            // Remove buttons column
            if (exerciseSets.length > 1) ...[
              const SizedBox(width: 8),
              Container(
                alignment: Alignment.center,
                width: 32,
                child: Column(
                  children: [
                    const SizedBox(height: 16), // Offset for header
                    ...List.generate(
                        exerciseSets.length,
                        (index) => Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: SizedBox(
                                height: boxHeight,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: myRed50, size: 20),
                                  onPressed: () => onRemoveSet(index),
                                ),
                              ),
                            )),
                  ],
                ),
              ),
            ],
          ],
        ),

        // Add set button
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () => onAddSet(ExerciseSet()),
                icon: const Icon(Icons.add, size: 20, color: myBlue60),
                label: Text(
                  l10n.add_set,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: myBlue60,
                  ),
                ),
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  side: WidgetStateProperty.all(
                    const BorderSide(color: myBlue60, width: 1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
