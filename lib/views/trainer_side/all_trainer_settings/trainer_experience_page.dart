import 'package:naturafit/services/firebase_service.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:intl/intl.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/horizontal_number_slider.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/widgets/custom_date_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TrainerExperiencePage extends StatefulWidget {
  final List<Map<String, dynamic>> initialExperienceList;
  final int initialYearsOfExperience;
  
  const TrainerExperiencePage({
    super.key,
    required this.initialExperienceList,
    required this.initialYearsOfExperience,
  });

  @override
  State<TrainerExperiencePage> createState() => _TrainerExperiencePageState();
}

class _TrainerExperiencePageState extends State<TrainerExperiencePage> {
  final ScrollController _experienceScrollController = ScrollController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _experienceStartDateController = TextEditingController();
  final TextEditingController _experienceEndDateController = TextEditingController();
  final List<Map<String, String>> _experienceList = [];
  int _yearsOfExperience = 0;
  final int _currentStep = 1;
  final int _totalSteps = 4;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _yearsOfExperience = widget.initialYearsOfExperience;
    _experienceList.addAll(
      widget.initialExperienceList.map((item) => 
        item.map((key, value) => MapEntry(key, value.toString()))
      )
    );
  }

  @override
  void dispose() {
    _experienceScrollController.dispose();
    _jobTitleController.dispose();
    _organizationController.dispose();
    _experienceStartDateController.dispose();
    _experienceEndDateController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final initialList = List<Map<String, dynamic>>.from(widget.initialExperienceList);
    final currentList = _experienceList.map((e) => Map<String, dynamic>.from(e)).toList();
    
    bool areListsEqual() {
      if (initialList.length != currentList.length) return false;
      
      for (int i = 0; i < initialList.length; i++) {
        final initial = initialList[i];
        final current = currentList[i];
        
        if (initial['jobTitle'] != current['jobTitle'] ||
            initial['organization'] != current['organization'] ||
            initial['startDate'] != current['startDate'] ||
            initial['endDate'] != current['endDate']) {
          return false;
        }
      }
      return true;
    }

    setState(() {
      _hasUnsavedChanges = !areListsEqual() || 
          _yearsOfExperience != widget.initialYearsOfExperience;
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
          l10n.experience,
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

                    // Update experience data in Firebase
                    if (context.mounted) {
                      await FirebaseService().updateUser({
                        'experienceList': _experienceList,
                        'yearsOfExperience': _yearsOfExperience,
                      }, context);
                    }

                    // Update UserProvider
                    if (context.mounted) {
                      final userProvider = context.read<UserProvider>();
                      final currentData = Map<String, dynamic>.from(userProvider.userData ?? {});
                      currentData['experienceList'] = _experienceList;
                      currentData['yearsOfExperience'] = _yearsOfExperience;
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
      body: _buildExperienceStep(),
    );
  }


  Widget _buildExperienceStep() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      controller: _experienceScrollController,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
          
              // Years of Experience Slider
              Container(
                margin: const EdgeInsets.only(top: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HorizontalNumberSlider(
                      title: l10n.years_of_experience,
                      initialValue: widget.initialYearsOfExperience,
                      onValueChanged: (value) {
                        setState(() {
                          _yearsOfExperience = value;
                        });
                        _checkForChanges();
                      },
                    ),
                  ],
                ),
              ),
              //const Divider(height: 32),
              const SizedBox(height: 16),
          
              // Experience Form
              CustomFocusTextField(
                label: l10n.job_title,
                hintText: l10n.enter_job_title,
                controller: _jobTitleController,
                prefixIcon: Icons.work_outline,
                onChanged: (value) {
                  // Add any onChange logic here if needed
                },
              ),
              const SizedBox(height: 16),
              CustomFocusTextField(
                label: l10n.organization,
                hintText: l10n.enter_organization,
                controller: _organizationController,
                prefixIcon: Icons.business_outlined,
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
                            controller: _experienceStartDateController,
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
                                  horizontal: 16, vertical: 16),
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
                                  _experienceStartDateController.text =
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
                            controller: _experienceEndDateController,
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
                                  horizontal: 16, vertical: 16),
                            ),
                            onTap: () async {
                              final date = await CustomDatePicker.show(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1940),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                setState(() {
                                  _experienceEndDateController.text =
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
                      if (_jobTitleController.text.isNotEmpty &&
                          _organizationController.text.isNotEmpty) {
                        setState(() {
                          _experienceList.add({
                            'jobTitle': _jobTitleController.text,
                            'organization': _organizationController.text,
                            'startDate': _experienceStartDateController.text,
                            'endDate': _experienceEndDateController.text,
                          });
                          // Clear the form
                          _jobTitleController.clear();
                          _organizationController.clear();
                          _experienceStartDateController.clear();
                          _experienceEndDateController.clear();
                        });
                        _checkForChanges();
          
                        // Add scroll animation after setState
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _experienceScrollController.animateTo(
                            _experienceScrollController.position.maxScrollExtent,
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
                          l10n.add_experience,
                          style: GoogleFonts.plusJakartaSans(
                            color: myBlue60,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_currentStep != _totalSteps) const SizedBox(width: 8),
                        if (_currentStep != _totalSteps)
                          const Icon(
                            Icons.work_outline,
                            color: myBlue60,
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
          
              // Experience List
              if (_experienceList.isNotEmpty) ...[
                Text(
                  l10n.added_experience,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _experienceList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final experience = _experienceList[index];
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
                                Icons.work_outline,
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
                                    experience['jobTitle'] ?? '',
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
                                      experience['organization'] ?? '',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: theme.brightness == Brightness.light ? myGrey70 : myGrey30,
                                      ),
                                    ),
                                  ),
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
                                        '${experience['startDate']} - ${experience['endDate']?.isEmpty ?? true ? l10n.present : experience['endDate']}',
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
                                  _experienceList.removeAt(index);
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
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }


  
} 