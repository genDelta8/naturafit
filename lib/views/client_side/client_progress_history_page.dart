import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/widgets/custom_top_selector.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/views/client_side/client_progress_detail_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProgressHistoryPage extends StatefulWidget {
  const ProgressHistoryPage({super.key, this.isEnteredByTrainer = false, this.passedClientForTrainer, this.passedConsentSettingsForTrainer, this.passedLogs,});
  final bool isEnteredByTrainer;
  final Map<String, dynamic>? passedClientForTrainer;
  final Map<String, dynamic>? passedConsentSettingsForTrainer;
  final List<Map<String, dynamic>>? passedLogs;

  @override
  State<ProgressHistoryPage> createState() => _ProgressHistoryPageState();
}

class _ProgressHistoryPageState extends State<ProgressHistoryPage> {
  final List<TopSelectorOption> _options = [
    TopSelectorOption(title: 'by Client'),
    TopSelectorOption(title: 'by Trainer'),
  ];
  int _selectedIndex = 0;
  bool _isLoading = false;
  List<QueryDocumentSnapshot> _allLogs = [];

  @override
  void initState() {
    super.initState();
    //_fetchLogs();
  }


/*
  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
    });

   
    //debugPrint('passedClientForTrainer: ${widget.passedClientForTrainer}');
    

    try {
      final userId = widget.isEnteredByTrainer ? (widget.passedClientForTrainer?['clientId'] ?? '') : context.read<UserProvider>().userData?['userId'] ?? '';
      final snapshot = await FirebaseFirestore.instance
          .collection('progress_logs')
          .doc(userId)
          .collection('all_progress_logs')
          .get();

      setState(() {
        _allLogs = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching logs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  */

  List<Map<String, dynamic>> _processLogs() {
    // Filter by selected type (client/trainer)
      final filtered = widget.passedLogs?.where((log) {
      return log['loggedByClient'] == (_selectedIndex == 0);
    }).toList() ?? [];

    // Sort by date descending
    filtered.sort((a, b) {
      final aDate = (a['date'] as Timestamp).toDate();
      final bDate = (b['date'] as Timestamp).toDate();
      return bDate.compareTo(aDate); // Descending order
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.progress_history,
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: Container(
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
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: myBlue60))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CustomTopSelector(
                    options: _options,
                    selectedIndex: _selectedIndex,
                    onOptionSelected: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final processedLogs = _processLogs();

                      if (processedLogs.isEmpty) {
                        return Center(
                          child: Text(
                            'No progress logs found',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              color: theme.brightness == Brightness.light ? myGrey70 : Colors.grey[400],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: processedLogs.length,
                        itemBuilder: (context, index) {
                          final log = processedLogs[index];
                          final date = (log['date'] as Timestamp).toDate();
                          final weight = log['weight']?.toString() ?? 'N/A';
                          final height = log['height']?.toString() ?? 'N/A';
                          final bodyFat = log['bodyFat']?.toString() ?? 'N/A';
                          final hasPhotos = log['progressPhotos'] != null;

                          final consentSettings = widget.passedConsentSettingsForTrainer ??
                      {
                        'birthday': false,
                        'email': false,
                        'phone': false,
                        'location': false,
                        'measurements': false,
                        'progressPhotos': false,
                        'socialMedia': false,
                      };

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProgressDetailPage(
                                      progressData: log,
                                      passedConsentSettingsForTrainer: consentSettings,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: theme.brightness == Brightness.light 
                                                  ? myGrey20 
                                                  : myGrey70,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.calendar_today,
                                                size: 16,
                                                color: theme.brightness == Brightness.light 
                                                  ? myGrey90 
                                                  : Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              DateFormat('dd MMMM yyyy').format(date),
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: theme.brightness == Brightness.light 
                                                  ? myGrey90 
                                                  : Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (hasPhotos)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.brightness == Brightness.light 
                                                ? myBlue20 
                                                : myBlue60.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.photo_library,
                                                  color: myBlue60,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Photos',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12,
                                                    color: myBlue60,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildMeasurement(
                                          icon: Icons.monitor_weight,
                                          value: double.tryParse(weight)?.toStringAsFixed(1) ?? 'N/A',
                                          unit: 'kg',
                                          label: 'Weight',
                                        ),
                                        Container(
                                          height: 40,
                                          width: 1,
                                          color: theme.brightness == Brightness.light 
                                            ? myGrey30 
                                            : myGrey70,
                                        ),
                                        _buildMeasurement(
                                          icon: Icons.height,
                                          value: double.tryParse(height)?.toStringAsFixed(1) ?? 'N/A',
                                          unit: 'cm',
                                          label: 'Height',
                                        ),
                                        Container(
                                          height: 40,
                                          width: 1,
                                          color: theme.brightness == Brightness.light 
                                            ? myGrey30 
                                            : myGrey70,
                                        ),
                                        _buildMeasurement(
                                          icon: Icons.speed,
                                          value: bodyFat,
                                          unit: '%',
                                          label: 'Body Fat',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      l10n.logged_by(log['loggedByName'] ?? 'Unknown'),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMeasurement({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(
              icon, 
              size: 20, 
              color: theme.brightness == Brightness.light ? myGrey70 : Colors.grey[400]
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                unit,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: theme.brightness == Brightness.light ? myGrey70 : Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: theme.brightness == Brightness.light ? myGrey70 : Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
} 