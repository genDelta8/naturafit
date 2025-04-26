import 'package:naturafit/widgets/custom_checkbox_card.dart';
import 'package:naturafit/widgets/custom_preference_check_box_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/services/firebase_service.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ClientUnitPreferencesPage extends StatefulWidget {
  final String initialHeightUnit;
  final String initialWeightUnit;
  final String initialDistanceUnit;
  final String initialTimeFormat;
  final String initialDateFormat;
  const ClientUnitPreferencesPage({
    super.key,
    required this.initialHeightUnit,
    required this.initialWeightUnit,
    required this.initialDistanceUnit,
    required this.initialTimeFormat,
    required this.initialDateFormat,
  });

  @override
  State<ClientUnitPreferencesPage> createState() => _ClientUnitPreferencesPageState();
}

class _ClientUnitPreferencesPageState extends State<ClientUnitPreferencesPage> {
  late String _heightUnit;
  late String _weightUnit;
  late String _distanceUnit;
  late String _timeFormat;
  late String _dateFormat;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _heightUnit = widget.initialHeightUnit;
    _weightUnit = widget.initialWeightUnit;
    _distanceUnit = widget.initialDistanceUnit;
    _timeFormat = widget.initialTimeFormat == '12-hour' ? '12-hour\n(1:30 PM)' : '24-hour\n(13:30)';
    _dateFormat = widget.initialDateFormat;
  }

  void _checkForChanges() {
    setState(() {
      _hasUnsavedChanges = _heightUnit != widget.initialHeightUnit ||
          _weightUnit != widget.initialWeightUnit ||
          _distanceUnit != widget.initialDistanceUnit ||
          _timeFormat != widget.initialTimeFormat ||
          _dateFormat != widget.initialDateFormat;
    });
  }

  Widget _buildUnitSelector({
    required String title,
    required String currentValue,
    required List<String> options,
    required Function(String) onChanged,
    required IconData? icon,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Row(
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                ),
              ),
              const SizedBox(width: 8),
              if (icon != null)
                Icon(icon, color: theme.brightness == Brightness.light ? myGrey90 : myGrey10, size: 20),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            //color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            //border: Border.all(color: myGrey20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: options.map((option) {
              final isSelected = currentValue == option;
              return CustomPreferenceCheckboxCard(title: option, isSelected: isSelected, onTap: () {
                  onChanged(option);
                  _checkForChanges();
                });
                
                
                
                
              
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
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
          l10n.unit_preferences_page_title,
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

                      final updatedData = {
                        'heightUnit': _heightUnit,
                        'weightUnit': _weightUnit,
                        'timeFormat': _timeFormat == '12-hour\n(1:30 PM)' ? '12-hour' : '24-hour',
                        'dateFormat': _dateFormat,
                      };

                      // Store in SharedPreferences
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('heightUnit', _heightUnit);
                      await prefs.setString('weightUnit', _weightUnit);
                      await prefs.setString('timeFormat', _timeFormat == '12-hour\n(1:30 PM)' ? '12-hour' : '24-hour');
                      await prefs.setString('dateFormat', _dateFormat);
                      await prefs.setBool('isMetric', _heightUnit == 'cm' && _weightUnit == 'kg');

                      // Update Firebase
                      if (context.mounted) {
                        await FirebaseService().updateUser(updatedData, context);
                      }

                      if (context.mounted) {
                        final userProvider = context.read<UserProvider>();
                        final currentData = Map<String, dynamic>.from(userProvider.userData ?? {});
                        currentData.addAll(updatedData);
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
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                _buildUnitSelector(
                  title: l10n.height_unit_title,
                  currentValue: _heightUnit,
                  options: const ['ft', 'cm'],
                  icon: Icons.height_outlined,
                  onChanged: (value) => setState(() => _heightUnit = value),
                ),
                _buildUnitSelector(
                  title: l10n.weight_unit_title,
                  currentValue: _weightUnit,
                  options: const ['lbs', 'kg'],
                  icon: Icons.monitor_weight_outlined,
                  onChanged: (value) => setState(() => _weightUnit = value),
                ),
                /*
                _buildUnitSelector(
                  title: 'DISTANCE',
                  currentValue: _distanceUnit,
                  options: const ['km', 'mi'],
                  icon: Icons.directions_run_outlined,
                  onChanged: (value) => setState(() => _distanceUnit = value),
                ),
                */
                _buildUnitSelector(
                  title: l10n.time_format_title,
                  currentValue: _timeFormat,
                  options: [l10n.time_format_12hour, l10n.time_format_24hour],
                  icon: Icons.watch_later_outlined,
                  onChanged: (value) => setState(() => _timeFormat = value),
                ),
            
                _buildUnitSelector(
                  title: l10n.date_format_title,
                  currentValue: _dateFormat,
                  options: const ['MM/dd/yyyy', 'dd/MM/yyyy'],
                  icon: Icons.calendar_month_outlined,
                  onChanged: (value) => setState(() => _dateFormat = value),
                ),
                
              ],
            ),
          ),
        ),
      ),
    );
  }
} 