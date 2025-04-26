import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/services/firebase_service.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/widgets/custom_date_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TrainerCertificationsPage extends StatefulWidget {
  final List<Map<String, dynamic>> initialEducationList;
  
  const TrainerCertificationsPage({
    super.key,
    required this.initialEducationList,
  });

  @override
  State<TrainerCertificationsPage> createState() => _TrainerCertificationsPageState();
}

class _TrainerCertificationsPageState extends State<TrainerCertificationsPage> {
  final ScrollController _educationScrollController = ScrollController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _educationStartDateController = TextEditingController();
  final TextEditingController _educationEndDateController = TextEditingController();
  String? _selectedEducationCategory;
  String? _selectedEducationItem;
  final List<Map<String, String>> _educationList = [];
  final int _currentStep = 1;
  final int _totalSteps = 4;
  bool _hasUnsavedChanges = false;


  @override
  void initState() {
    super.initState();
    // Convert the dynamic map to String map and initialize the list
    _educationList.addAll(
      widget.initialEducationList.map((item) => 
        item.map((key, value) => MapEntry(key, value.toString()))
      )
    );
  }

  @override
  void dispose() {
    _educationScrollController.dispose();
    _categoryController.dispose();
    _educationController.dispose();
    _subjectController.dispose();
    _educationStartDateController.dispose();
    _educationEndDateController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final initialList = List<Map<String, dynamic>>.from(widget.initialEducationList);
    final currentList = _educationList.map((e) => Map<String, dynamic>.from(e)).toList();
    
    bool areListsEqual() {
      if (initialList.length != currentList.length) return false;
      
      for (int i = 0; i < initialList.length; i++) {
        final initial = initialList[i];
        final current = currentList[i];
        
        if (initial['category'] != current['category'] ||
            initial['education'] != current['education'] ||
            initial['subject'] != current['subject'] ||
            initial['startDate'] != current['startDate'] ||
            initial['endDate'] != current['endDate']) {
          return false;
        }
      }
      return true;
    }

    setState(() {
      _hasUnsavedChanges = !areListsEqual();
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
          l10n.certifications,
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

                    // Update educationList in Firebase
                    if (context.mounted) {
                      await FirebaseService().updateUser({
                        'educationList': _educationList,
                      }, context);
                    }

                    // Update UserProvider
                    if (context.mounted) {
                      final userProvider = context.read<UserProvider>();
                      final currentData = Map<String, dynamic>.from(userProvider.userData ?? {});
                      currentData['educationList'] = _educationList;
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
      body: _buildEducationStep(),
      
    );
  }

  Widget _buildEducationStep() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final Map<String, List<String>> educationCategories = {
    l10n.formal_education: [
      l10n.high_school_diploma,
      l10n.associate_degree,
      l10n.bachelor_degree,
      l10n.master_degree,
      l10n.phd,
    ],
    l10n.certifications: [
      l10n.certified_personal_trainer,
      l10n.certified_strength_and_conditioning_specialist,
      l10n.certified_functional_strength_coach,
      l10n.corrective_exercise_specialist,
      l10n.performance_enhancement_specialist,
      l10n.certified_nutrition_specialist,
      l10n.precision_nutrition_certification,
      l10n.certified_pilates_instructor,
      l10n.certified_yoga_instructor,
      l10n.crossfit_level_1_trainer,
      l10n.trx_suspension_training_certification,
      l10n.kettlebell_instructor_certification,
      l10n.sports_massage_therapy_certification,
      l10n.senior_fitness_specialist_certification,
      l10n.pre_and_post_natal_fitness_certification,
      l10n.youth_fitness_specialist_certification,
      l10n.group_fitness_instructor_certification,
    ],
    l10n.specialized_education: [
      l10n.aquatic_exercise_association_certification,
      l10n.tactical_strength_and_conditioning_certification,
      l10n.behavior_change_specialist_certification,
      l10n.mobility_and_movement_specialist_certification,
      l10n.advanced_biomechanics_certification,
      l10n.martial_arts_and_self_defense_trainer_certification,
      l10n.cpr_aed_certification,
      l10n.first_aid_certification,
      l10n.injury_prevention_and_management,
      l10n.advanced_program_design,
      l10n.nutrition_for_athletes,
      l10n.mental_health_and_fitness_integration,
      l10n.sports_psychology_basics,
      l10n.functional_movement_screen_fms_certification,
      l10n.advanced_recovery_techniques,
    ],
  };
  
    return SingleChildScrollView(
      controller: _educationScrollController,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
          
              // Category Field
              CustomFocusTextField(
                label: l10n.category,
                hintText: l10n.enter_select_category,
                controller: _categoryController,
                prefixIcon: Icons.school_outlined,
                suffixIcon: Icon(
                  Icons.arrow_drop_down,
                  color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                ),
                onSuffixTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: educationCategories.keys.length,
                        itemBuilder: (context, index) {
                          final category =
                              educationCategories.keys.elementAt(index);
                          return ListTile(
                            title: Text(category),
                            onTap: () {
                              setState(() {
                                _categoryController.text = category;
                                _selectedEducationCategory = category;
                                _selectedEducationItem = null;
                                _educationController.clear();
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
                onChanged: (value) {
                  setState(() {
                    _selectedEducationCategory = value;
                    _selectedEducationItem = null;
                  });
                },
              ),
              const SizedBox(height: 16),
          
              // Education/Certification Field
              CustomFocusTextField(
                label: l10n.education_certification,
                hintText: l10n.enter_select_education,
                controller: _educationController,
                prefixIcon: Icons.workspace_premium_outlined,
                suffixIcon:
                    educationCategories.keys.contains(_selectedEducationCategory)
                        ? Icon(
                            Icons.arrow_drop_down,
                            color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                          )
                        : null,
                onSuffixTap: educationCategories.keys
                        .contains(_selectedEducationCategory)
                    ? () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount:
                                  educationCategories[_selectedEducationCategory]
                                          ?.length ??
                                      0,
                              itemBuilder: (context, index) {
                                final item = educationCategories[
                                    _selectedEducationCategory]![index];
                                return ListTile(
                                  title: Text(item),
                                  onTap: () {
                                    setState(() {
                                      _educationController.text = item;
                                      _selectedEducationItem = item;
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      }
                    : null,
                onChanged: (value) {
                  setState(() {
                    _selectedEducationItem = value;
                  });
                },
              ),
              const SizedBox(height: 16),
          
              // Subject Field
              CustomFocusTextField(
                label: l10n.subject_specialization,
                hintText: l10n.enter_subject,
                controller: _subjectController,
                prefixIcon: Icons.topic_outlined,
                onChanged: (value) {
                  // Add any onChange logic here if needed
                },
              ),
              const SizedBox(height: 16),
          
              // Date Fields Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.start_date,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _educationStartDateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: l10n.select_date,
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.calendar_today_outlined,
                                color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            onTap: () async {
                              final date = await CustomDatePicker.show(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1940),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  _educationStartDateController.text =
                                      DateFormat('yyyy-MM-dd').format(date);
                                });
                                _checkForChanges();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.end_date,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _educationEndDateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: l10n.select_date,
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.calendar_today_outlined,
                                color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            onTap: () async {
                              final date = await CustomDatePicker.show(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1940),
                                lastDate: DateTime(2100), // Allow future dates for end date
                              );
                              if (date != null) {
                                setState(() {
                                  _educationEndDateController.text =
                                      DateFormat('yyyy-MM-dd').format(date);
                                });
                                _checkForChanges();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          
              // Add Button
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_categoryController.text.isNotEmpty &&
                          _educationController.text.isNotEmpty) {
                        setState(() {
                          _educationList.add({
                            'category': _categoryController.text,
                            'education': _educationController.text,
                            'subject': _subjectController.text,
                            'startDate': _educationStartDateController.text,
                            'endDate': _educationEndDateController.text,
                          });
                          // Clear the form
                          _categoryController.clear();
                          _educationController.clear();
                          _subjectController.clear();
                          _educationStartDateController.clear();
                          _educationEndDateController.clear();
                          _selectedEducationCategory = null;
                          _selectedEducationItem = null;
                        });
                        _checkForChanges();
          
                        // Add scroll animation after setState
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _educationScrollController.animateTo(
                            _educationScrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: myBlue20,
                      foregroundColor: myBlue60,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.add_education,
                          style: GoogleFonts.plusJakartaSans(
                            color: myBlue60,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_currentStep != _totalSteps) const SizedBox(width: 8),
                        if (_currentStep != _totalSteps)
                          const Icon(
                            Icons.school_outlined,
                            color: myBlue60,
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
          
              // Added Education List
              if (_educationList.isNotEmpty) ...[
                Text(
                  l10n.added_education,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _educationList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final education = _educationList[index];
                    return Card(
                      margin: EdgeInsets.zero,
                      elevation: 1,
                      color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left side - Icon
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: myBlue60.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.school_outlined,
                                color: myBlue60,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
          
                            // Middle - Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    education['education'] ?? '',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: myGrey20,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      education['category'] ?? '',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: theme.brightness == Brightness.light ? myGrey70 : myGrey30,
                                      ),
                                    ),
                                  ),
                                  if (education['subject'] != null &&
                                      education['subject']!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      education['subject'] ?? '',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        color: theme.brightness == Brightness.light ? myGrey70 : myGrey30,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 14,
                                        color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${education['startDate']} - ${education['endDate'] != null && education['endDate']!.isNotEmpty ? education['endDate'] : 'Present'}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
          
                            // Right side - Delete button
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: myRed50,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _educationList.removeAt(index);
                                });
                                _checkForChanges();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  } 
}