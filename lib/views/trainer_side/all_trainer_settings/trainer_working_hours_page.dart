import 'package:naturafit/widgets/custom_available_hours_selector.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/services/firebase_service.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TrainerWorkingHoursPage extends StatefulWidget {
  final Map<String, List<TimeRange>> initialAvailableHours;
  
  const TrainerWorkingHoursPage({
    super.key,
    required this.initialAvailableHours,
  });

  @override
  State<TrainerWorkingHoursPage> createState() => _TrainerWorkingHoursPageState();
}

class _TrainerWorkingHoursPageState extends State<TrainerWorkingHoursPage> {
  bool _hasUnsavedChanges = false;
  final TextEditingController _availabilityController = TextEditingController();
  Map<String, List<TimeRange>> _availableHours = {};

  @override
  void initState() {
    super.initState();
    _availableHours = Map<String, List<TimeRange>>.from(widget.initialAvailableHours);
  }

  @override
  void dispose() {
    _availabilityController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final initialHours = widget.initialAvailableHours;
    final currentHours = _availableHours;
    
    bool areHoursEqual() {
      if (initialHours.length != currentHours.length) return false;
      
      for (final day in initialHours.keys) {
        final initialRanges = initialHours[day] ?? [];
        final currentRanges = currentHours[day] ?? [];
        
        if (initialRanges.length != currentRanges.length) return false;
        
        for (int i = 0; i < initialRanges.length; i++) {
          // Convert to string format for comparison
          final initialStart = '${initialRanges[i].start.format(context)}';
          final initialEnd = '${initialRanges[i].end.format(context)}';
          final currentStart = '${currentRanges[i].start.format(context)}';
          final currentEnd = '${currentRanges[i].end.format(context)}';
          
          if (initialStart != currentStart || initialEnd != currentEnd) {
            return false;
          }
        }
      }
      return true;
    }

    setState(() {
      _hasUnsavedChanges = !areHoursEqual();
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
          l10n.working_hours,
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

                    // Convert TimeRange objects to Map format for Firebase
                    final hoursForFirebase = _availableHours.map(
                      (key, value) => MapEntry(
                        key,
                        value.map((range) => {
                          'start': '${range.start.hour}:${range.start.minute}',
                          'end': '${range.end.hour}:${range.end.minute}',
                        }).toList(),
                      ),
                    );

                    // Update data in Firebase
                    if (context.mounted) {
                      await FirebaseService().updateUser({
                        'availableHours': hoursForFirebase,
                      }, context);
                    }

                    // Update UserProvider
                    if (context.mounted) {
                      final userProvider = context.read<UserProvider>();
                      final currentData = Map<String, dynamic>.from(userProvider.userData ?? {});
                      currentData['availableHours'] = hoursForFirebase;
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
      body: _buildAvailabilityStep(),
    );
  }




  Widget _buildAvailabilityStep() {
    final l10n = AppLocalizations.of(context)!;
    final userData = context.read<UserProvider>().userData;
    final use24HourFormat = userData?['timeFormat'] == '24-hour';
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.weekly_availability,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                ),
              ),
              const SizedBox(height: 16),
              
              CustomAvailableHoursSelector(
                initialValue: _availableHours,
                use24HourFormat: use24HourFormat,
                onChanged: (value) {
                  setState(() {
                    _availableHours = value.map(
                      (key, list) => MapEntry(
                        key,
                        List<TimeRange>.from(list),
                      ),
                    );
                  });
                  _checkForChanges();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }



  
} 