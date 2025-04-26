
import 'package:naturafit/services/unit_preferences.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/widgets/custom_select_textfield.dart';
import 'dart:io';
import 'package:naturafit/models/workout_models.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WorkoutScheduleStep extends StatefulWidget {
  final List<WorkoutDay> workoutDays;
  final int selectedDayIndex;
  final Function(int) onDaySelected;
  final Function(int, String) onAddExercise;
  final Function(int) onRemoveDay;
  final Function() onAddDay;
  final List<String> focusAreaSuggestions;
  final Function(int, int, String) onEditExercise;
  final Function(int, int) onDeleteExercise;
  final Function(String) getExerciseIcon;

  const WorkoutScheduleStep({
    Key? key,
    required this.workoutDays,
    required this.selectedDayIndex,
    required this.onDaySelected,
    required this.onAddExercise,
    required this.onRemoveDay,
    required this.onAddDay,
    required this.focusAreaSuggestions,
    required this.onEditExercise,
    required this.onDeleteExercise,
    required this.getExerciseIcon,
  }) : super(key: key);

  @override
  _WorkoutScheduleStepState createState() => _WorkoutScheduleStepState();
}

class _WorkoutScheduleStepState extends State<WorkoutScheduleStep> {
  Map<String, TextEditingController> phaseControllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize controllers for all phases in the current day
    for (var phase in widget.workoutDays[widget.selectedDayIndex].phases) {
      phaseControllers[phase.id] = TextEditingController(text: phase.name);
    }
  }

  @override
  void didUpdateWidget(WorkoutScheduleStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDayIndex != widget.selectedDayIndex) {
      // Clean up old controllers
      phaseControllers.values.forEach((controller) => controller.dispose());
      phaseControllers.clear();

      // Initialize controllers for the new day's phases
      for (var phase in widget.workoutDays[widget.selectedDayIndex].phases) {
        phaseControllers[phase.id] = TextEditingController(text: phase.name);
      }
    }
  }

  void _addNewPhase() {
    final l10n = AppLocalizations.of(context)!;

    final List<String> _phaseNames = [
      l10n.main_workout_phase,
      l10n.warm_up_phase,
      l10n.cool_down_phase,
      l10n.cardio_phase,
      l10n.mobility_phase,
      l10n.recovery_phase,
      l10n.hiit_phase,
      l10n.core_work_phase,
      l10n.stretching_phase,
    ];

    final availablePhases = _phaseNames.where((name) {
      return !widget.workoutDays[widget.selectedDayIndex].phases
          .any((phase) => phase.name == name);
    }).toList();

    setState(() {
      String newPhaseName;
      if (availablePhases.isNotEmpty) {
        newPhaseName = availablePhases[0];
      } else {
        int counter = 1;
        do {
          newPhaseName = 'Phase ${counter}';
          counter++;
        } while (widget.workoutDays[widget.selectedDayIndex].phases
            .any((phase) => phase.name == newPhaseName));
      }

      final newPhase = WorkoutPhase(
        id: '${DateTime.now().millisecondsSinceEpoch}_${widget.selectedDayIndex}',
        name: newPhaseName,
      );

      widget.workoutDays[widget.selectedDayIndex].phases.add(newPhase);
      phaseControllers[newPhase.id] =
          TextEditingController(text: newPhase.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _buildDaySelector(),
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CustomSelectTextField(
                      label: l10n.focus_area,
                      hintText: l10n.focus_area_hint,
                      controller: widget.workoutDays[widget.selectedDayIndex]
                          .focusAreaController,
                      options: widget.focusAreaSuggestions,
                      prefixIcon: Icons.fitness_center_outlined,
                      isRequired: false,
                    ),
                  ),
                ],
              ),
            ),
            // Phase Cards
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final WorkoutPhase item = widget
                      .workoutDays[widget.selectedDayIndex].phases
                      .removeAt(oldIndex);
                  widget.workoutDays[widget.selectedDayIndex].phases
                      .insert(newIndex, item);
                });
              },
              children: widget.workoutDays[widget.selectedDayIndex].phases
                  .map((phase) {
                return KeyedSubtree(
                  key: ValueKey(phase.id),
                  child: _buildPhaseCard(phase),
                );
              }).toList(),
            ),
            // Add Phase Button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: GestureDetector(
                onTap: _addNewPhase,
                child: Container(
                  decoration: BoxDecoration(
                    color: myGrey30,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    width: 140,
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: myGrey80,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 20, color: Colors.white),
                        Text(
                          l10n.add_phase,
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 72,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.workoutDays.length,
              itemBuilder: (context, index) {
                final isSelected = index == widget.selectedDayIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: InkWell(
                    onTap: () => widget.onDaySelected(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? myGrey30 : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? myGrey80 : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : myGrey20,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.day,
                              style: GoogleFonts.plusJakartaSans(
                                color: isSelected ? Colors.white : myGrey80,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${index + 1}',
                              style: GoogleFonts.plusJakartaSans(
                                color: isSelected ? Colors.white : myGrey80,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            if (widget.workoutDays.length > 1)
                              GestureDetector(
                                onTap: () => widget.onRemoveDay(index),
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: isSelected ? myGrey60 : myGrey30,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 10,
                                    color: isSelected ? Colors.white : myGrey90,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.workoutDays.length < 7)
            GestureDetector(
              onTap: widget.onAddDay,
              child: Container(
                decoration: const BoxDecoration(
                  color: myBlue30,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: myBlue60,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExercisesList(WorkoutPhase phase) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: phase.exercises.length,
      itemBuilder: (context, exerciseIndex) {
        final exercise = phase.exercises[exerciseIndex];
        return _buildExerciseCard(exercise, exerciseIndex, phase);
      },
    );
  }

  Widget _buildExerciseCard(
      Exercise exercise, int exerciseIndex, WorkoutPhase phase) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.brightness == Brightness.light ? Colors.white : myGrey90,
      elevation: 1,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light
                ? myBlue60.withOpacity(0.1)
                : myGrey60.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              widget.getExerciseIcon(exercise.equipment ?? ''),
              color: theme.brightness == Brightness.light ? myBlue60 : myGrey50,
              size: 20,
            ),
          ),
        ),
        title: Text(
          exercise.name,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: theme.brightness == Brightness.light
                ? Colors.black
                : Colors.white,
          ),
        ),
        subtitle: _buildExerciseSubtitle(exercise),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => widget.onEditExercise(
                  widget.selectedDayIndex, exerciseIndex, phase.id),
              child: Icon(Icons.edit_outlined,
                  color: theme.brightness == Brightness.light
                      ? myBlue60
                      : myGrey50,
                  size: 20),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  phase.exercises.removeAt(exerciseIndex);
                });
              },
              child: Icon(Icons.delete_outline,
                  color:
                      theme.brightness == Brightness.light ? myRed40 : myGrey50,
                  size: 20),
            ),
          ],
        ),
        children: [
          _buildExerciseDetails(exercise),
        ],
      ),
    );
  }

  Widget _buildExerciseSubtitle(Exercise exercise) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (exercise.sets.isEmpty) return const SizedBox();
    final firstSet = exercise.sets[0];
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light
                  ? myBlue60.withOpacity(0.1)
                  : myGrey60.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${exercise.sets.length} sets',
              style: GoogleFonts.plusJakartaSans(
                color:
                    theme.brightness == Brightness.light ? myBlue60 : myGrey50,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light
                  ? myBlue60.withOpacity(0.1)
                  : myGrey60.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${firstSet['reps']} reps',
              style: GoogleFonts.plusJakartaSans(
                color:
                    theme.brightness == Brightness.light ? myBlue60 : myGrey50,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseDetails(Exercise exercise) {
    final userData = Provider.of<UserProvider>(context).userData;
    final weightUnit = userData?['weightUnit'];
    final unitPrefs = Provider.of<UnitPreferences>(context, listen: false);
    if (exercise.sets.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (exercise.equipment != null)
          _buildDetailRow(
              'Equipment:', exercise.equipment!, Icons.fitness_center_outlined),

        // New sets display
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: exercise.sets.asMap().entries.map((entry) {
            final index = entry.key;
            final set = entry.value;
            final weight = weightUnit == 'kg'
                ? set['weight']
                : unitPrefs
                    .kgToLbs(double.parse(set['weight']))
                    .toStringAsFixed(0);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      //color: myBlue60.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '@${index + 1}',
                      style: GoogleFonts.plusJakartaSans(
                        color: myBlue60,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${set['reps']} Reps',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                    ),
                  ),
                  if (set['weight']?.isNotEmpty ?? false) ...[
                    const SizedBox(width: 8),
                    Text(
                      '$weight $weightUnit',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                      ),
                    ),
                  ],
                  if (set['rest']?.isNotEmpty ?? false) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${set['rest']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),

        if (exercise.instructions.isNotEmpty)
          _buildInstructions(exercise.instructions),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: theme.brightness == Brightness.light
                  ? Colors.black
                  : Colors.white),
          const SizedBox(width: 8),
          Text(
            '$label ',
            style: GoogleFonts.plusJakartaSans(
              color: theme.brightness == Brightness.light
                  ? Colors.black
                  : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: theme.brightness == Brightness.light
                  ? Colors.black87
                  : myGrey10,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(List<String> instructions) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_list_bulleted,
                  size: 16,
                  color: theme.brightness == Brightness.light
                      ? myGrey90
                      : myGrey10),
              const SizedBox(width: 8),
              Text(
                l10n.instructions,
                style: GoogleFonts.plusJakartaSans(
                  color: theme.brightness == Brightness.light
                      ? myGrey90
                      : myGrey10,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...instructions.asMap().entries.map((entry) {
            int idx = entry.key;
            String instruction = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${idx + 1}. ',
                    style: GoogleFonts.plusJakartaSans(
                      color: theme.brightness == Brightness.light
                          ? myGrey90
                          : myGrey10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      instruction,
                      style: GoogleFonts.plusJakartaSans(
                        color: theme.brightness == Brightness.light
                            ? myGrey90
                            : myGrey10,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAddExerciseButton(BuildContext context, WorkoutPhase phase) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => widget.onAddExercise(widget.selectedDayIndex, phase.id),
      child: Container(
        decoration: BoxDecoration(
          color: myBlue30,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          width: 140,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: myBlue60,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 20, color: Colors.white),
              Text(l10n.add_exercise,
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeletePhaseButton(WorkoutPhase phase) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: myRed40,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.close, color: Colors.white, size: 16),
        onPressed: () {
          setState(() {
            widget.workoutDays[widget.selectedDayIndex].phases.remove(phase);
            phaseControllers[phase.id]?.dispose();
            phaseControllers.remove(phase.id);
            // Clear exercises for this phase
            widget.workoutDays[widget.selectedDayIndex].phases.remove(phase);
          });
        },
      ),
    );
  }

  Widget _buildPhaseCard(WorkoutPhase phase) {
    final l10n = AppLocalizations.of(context)!;

    final List<String> _phaseNames = [
      l10n.main_workout_phase,
      l10n.warm_up_phase,
      l10n.cool_down_phase,
      l10n.cardio_phase,
      l10n.mobility_phase,
      l10n.recovery_phase,
      l10n.hiit_phase,
      l10n.core_work_phase,
      l10n.stretching_phase,
    ];

    phaseControllers[phase.id] ??= TextEditingController(text: phase.name);
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light ? myGrey20 : myGrey80,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.brightness == Brightness.light ? myGrey20 : myGrey80),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: CustomSelectTextField(
                    label: '',
                    hintText: l10n.enter_phase_name,
                    controller: phaseControllers[phase.id]!,
                    options: _phaseNames,
                    prefixIcon: Icons.fitness_center_outlined,
                    isRequired: true,
                    onChanged: (value) {
                      setState(() {
                        // Simply update the phase name
                        phase.name = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                _buildDeletePhaseButton(phase),
              ],
            ),
          ),
          _buildExercisesList(phase),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildAddExerciseButton(context, phase),
              const SizedBox(width: 12),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
