import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/views/client_side/client_log_progress_page.dart';
import 'package:naturafit/views/client_side/client_progress_history_page.dart';
import 'package:naturafit/views/client_side/client_workout/workout_history_page.dart';
import 'package:naturafit/views/client_side/progress_photo_viewer.dart';
import 'package:naturafit/widgets/custom_top_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:naturafit/views/client_side/photo_comparison_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProgressPage extends StatefulWidget {
  final bool isEnteredByTrainer;
  final Map<String, dynamic>? passedClientForTrainer;
  final Map<String, dynamic>? passedConsentSettingsForTrainer;
  final double? passedHeight;
  final double? passedWeight;

  const ProgressPage({
    super.key,
    this.isEnteredByTrainer = false,
    this.passedClientForTrainer,
    this.passedConsentSettingsForTrainer,
    this.passedHeight,
    this.passedWeight,
  });

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  // Helper method to calculate change between current value and most recent previous value
  double _calculateChange(dynamic current, List<Map<String, dynamic>> progressLogs) {
    if (current == null || progressLogs.isEmpty) return 0;
    
    // Convert current to double
    final currentValue = _toDouble(current);
    if (currentValue == null) return 0;

    // Find the most recent previous value that's not null
    double? previousValue;
    for (var i = 1; i < progressLogs.length; i++) {
      previousValue = _toDouble(progressLogs[i][current.runtimeType == String ? current : progressLogs[0].keys.firstWhere((k) => progressLogs[0][k] == current, orElse: () => '')]);
      if (previousValue != null) {
        return currentValue - previousValue;
      }
    }
    
    return 0; // Return 0 if no valid previous value found
  }

  // Helper method to format change value with sign
  String _formatChange(double change, {bool percentage = false}) {
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(1)}${percentage ? '%' : ''}';
  }

  // Add BMI calculation helper method
  double _calculateBMI(double weightKg, double heightCm) {
    final heightM = heightCm / 100; // Convert cm to m
    return weightKg / (heightM * heightM);
  }

  // Helper method to safely convert to double
  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  final List<TopSelectorOption> _options = [
    TopSelectorOption(title: 'Body'),
    TopSelectorOption(title: 'Workout'),
    TopSelectorOption(title: 'Trophies'),
  ];
  int selectedIndex = 0;
  void onOptionSelected(int index) {
    setState(() {
      selectedIndex = index;
      if (index == 1) {
        // Workout tab
        _fetchBookmarkedExercises();
      }
    });
  }

  List<Map<String, dynamic>> _bookmarkedExercises = [];

  bool _isLoading = true;
  List<QueryDocumentSnapshot> _allLogsForTrainer = [];

  List<Map<String, dynamic>>? _progressLogsTrainer;
  Map<String, dynamic>? _latestMeasurementsTrainer;

  late final Future<QuerySnapshot> _workoutHistoryFuture;

  @override
  void initState() {
    super.initState();
    if (widget.isEnteredByTrainer) {
      _fetchLogsForTrainer();
    } else {
      setState(() {
        _isLoading = false;
      });
    }


    debugPrint('Fetching workout history');
    // Initialize the future in initState
    final myUserId = widget.isEnteredByTrainer
        ? (widget.passedClientForTrainer?['clientId'] ?? '')
        : context.read<UserProvider>().userData?['userId'] ?? '';
    
    _workoutHistoryFuture = FirebaseFirestore.instance
        .collection('workout_history')
        .doc('clients')
        .collection(myUserId)
        .orderBy('completedAt', descending: true)
        .get();
  }

  Future<void> _fetchLogsForTrainer() async {
    setState(() {
      _isLoading = true;
    });

    //debugPrint('passedClientForTrainer: ${widget.passedClientForTrainer}');

    try {
      final userId = (widget.passedClientForTrainer?['clientId'] ?? '');
      final snapshot = await FirebaseFirestore.instance
          .collection('progress_logs')
          .doc(userId)
          .collection('all_progress_logs')
          .get();

      setState(() {
        _allLogsForTrainer = snapshot.docs;
        _progressLogsTrainer = snapshot.docs
          .map((doc) => doc.data())
          .toList();
        _latestMeasurementsTrainer = _progressLogsTrainer?.first;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching logs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchBookmarkedExercises() async {
    try {
      final userData = context.read<UserProvider>().userData;
      if (userData == null) return;

      final myUserId = widget.isEnteredByTrainer
          ? (widget.passedClientForTrainer?['clientId'] ?? '')
          : userData['userId'];

      final workoutsSnapshot = await FirebaseFirestore.instance
          .collection('workouts')
          .doc('clients')
          .collection(myUserId)
          .get();

      final uniqueExercises = <String, Map<String, dynamic>>{};

      for (var workoutDoc in workoutsSnapshot.docs) {
        final workoutData = workoutDoc.data();
        final List<dynamic> workoutDays = workoutData['workoutDays'] ?? [];

        for (var day in workoutDays) {
          for (var phase in day['phases'] as List<dynamic>) {
            for (var exercise in phase['exercises'] as List<dynamic>) {
              if (exercise['isBookmarked'] == true) {
                uniqueExercises[exercise['name']] = {
                  ...exercise,
                  'workoutName': workoutData['planName'],
                  'phaseName': phase['name'],
                };
              }
            }
          }
        }
      }

      setState(() {
        _bookmarkedExercises = uniqueExercises.values.toList();
      });
    } catch (e) {
      debugPrint('Error fetching bookmarked exercises: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final progressLogs = widget.isEnteredByTrainer ? (_progressLogsTrainer ?? []) : userProvider.progressLogs ?? [];
        final latestMeasurements = widget.isEnteredByTrainer ? _latestMeasurementsTrainer : userProvider.latestMeasurements;

        debugPrint('Latest measurements: $latestMeasurements');

        // Calculate changes using the full progress logs
        final weightChange = _calculateChange(
          latestMeasurements?['weight'],
          progressLogs,
        );

        final bodyFatChange = _calculateChange(
          latestMeasurements?['bodyFat'],
          progressLogs,
        );

        final muscleMassChange = _calculateChange(
          latestMeasurements?['muscleMass'],
          progressLogs,
        );

        final userData = userProvider.userData;

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

        final heightUnit = userData?['heightUnit'] ?? 'cm';
        final weightUnit = userData?['weightUnit'] ?? 'kg';
        final heightToPass = (heightUnit == 'cm') ? (userData?['height'] ?? 170.0).toDouble() : (userData?['height'] ?? 170.0).toDouble() / 30.48;
        final weightToPass = (weightUnit == 'kg') ? (userData?['weight'] ?? 70.0).toDouble() : (userData?['weight'] ?? 70.0).toDouble() * 2.20462;


        final heightToPassForTrainer = (heightUnit == 'cm') ? (widget.passedHeight ?? 170.0).toDouble() : (widget.passedHeight ?? 170.0).toDouble() / 30.48;
        final weightToPassForTrainer = (weightUnit == 'kg') ? (widget.passedWeight ?? 70.0).toDouble() : (widget.passedWeight ?? 70.0).toDouble() * 2.20462;

        final myIsWebOrDektop = isWebOrDesktopCached;

        return Stack(
          children: [
            Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: AppBar(
                title: Text(
                  widget.isEnteredByTrainer ? 'Client Progress' : 'My Progress',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                  ),
                ),
                centerTitle: (myIsWebOrDektop && !widget.isEnteredByTrainer) ? false : true,
                actions: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProgressHistoryPage(
                                  isEnteredByTrainer: widget.isEnteredByTrainer,
                                  passedClientForTrainer:
                                      widget.passedClientForTrainer,
                                  passedConsentSettingsForTrainer:
                                      consentSettings,
                                  passedLogs: progressLogs,
                                )),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.brightness == Brightness.light ? Colors.black : Colors.white, width: 1),
                      ),
                      child: Text(
                        l10n.history,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
                backgroundColor: theme.scaffoldBackgroundColor,
                leading: (myIsWebOrDektop && !widget.isEnteredByTrainer) ? const SizedBox.shrink() : Container(
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
              ),
              body: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, top: 16),
                    child: CustomTopSelector(
                        options: _options,
                        selectedIndex: selectedIndex,
                        onOptionSelected: onOptionSelected),
                  ),
                  if (selectedIndex == 0) ...[
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.passedConsentSettingsForTrainer != null) ...[
                                // Check measurements consent
                                if (widget.passedConsentSettingsForTrainer!['measurements'] == true) ...[
                                  _buildProgressSummary(
                                    weight:
                                        (_toDouble(latestMeasurements?['weight'])
                                                ?.toStringAsFixed(1) ??
                                            '--'),
                                    weightChange: weightChange,
                                    bodyFat:
                                        (_toDouble(latestMeasurements?['bodyFat'])
                                                ?.toStringAsFixed(1) ??
                                            '--'),
                                    bodyFatChange: bodyFatChange,
                                    muscleMass:
                                        (latestMeasurements?['muscleMass']
                                                    ?.toStringAsFixed(1) ??
                                                '--'),
                                    muscleMassChange: muscleMassChange,
                                    latestMeasurements: latestMeasurements,
                                  ),
                                  const SizedBox(height: 24),
                                  _buildWeightChart(),
                                  const SizedBox(height: 24),
                                  _buildMeasurements(),
                                ] else
                                  _buildAccessNotGrantedCard(
                                    l10n.measurements_access_not_granted,
                                    l10n.the_client_has_not_granted_access_to_view_their_measurements_data,
                                    Icons.straighten
                                  ),
                                const SizedBox(height: 24),
                                // Check progress photos consent
                                if (widget.passedConsentSettingsForTrainer!['progressPhotos'] == true)
                                  _buildPhotoGallery()
                                else
                                  _buildAccessNotGrantedCard(
                                    l10n.progress_photos_access_not_granted,
                                    l10n.the_client_has_not_granted_access_to_view_their_progress_photos,
                                    Icons.photo_library
                                  ),
                              ] else ...[
                                // If no consent settings passed, show everything as normal
                                _buildProgressSummary(
                                  weight:
                                      (_toDouble(latestMeasurements?['weight'])
                                              ?.toStringAsFixed(1) ??
                                          '--'),
                                  weightChange: weightChange,
                                  bodyFat:
                                      (_toDouble(latestMeasurements?['bodyFat'])
                                              ?.toStringAsFixed(1) ??
                                          '--'),
                                  bodyFatChange: bodyFatChange,
                                  muscleMass:
                                      (latestMeasurements?['muscleMass']
                                                  ?.toStringAsFixed(1) ??
                                          '--'),
                                  muscleMassChange: muscleMassChange,
                                  latestMeasurements: latestMeasurements,
                                ),
                                const SizedBox(height: 24),
                                _buildWeightChart(),
                                const SizedBox(height: 24),
                                _buildMeasurements(),
                                const SizedBox(height: 24),
                                _buildPhotoGallery(),
                              ],
                              const SizedBox(height: 24),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else if (selectedIndex == 1) ...[
                    Expanded(
                      child: _buildWorkoutAnalysis(),
                    ),
                  ] else if (selectedIndex == 2) ...[
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAchievements(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 16),
                      child: GestureDetector(
                        onTap: () {
                          if (widget.isEnteredByTrainer) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LogProgressPage(
                                  initialHeight: heightToPassForTrainer,
                                  initialWeight: weightToPassForTrainer,
                                  initialHeightUnit: heightUnit,
                                  initialWeightUnit: weightUnit,
                                  isEnteredByTrainer: true,
                                  passedClientForTrainer:
                                      widget.passedClientForTrainer,
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LogProgressPage(
                                  initialHeightUnit: heightUnit,
                                  initialWeightUnit: weightUnit,
                                  initialHeight: heightToPass,
                                  initialWeight: weightToPass,
                                  isEnteredByTrainer: false,
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          //padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: myBlue30,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 32),
                            decoration: BoxDecoration(
                              color: myBlue60,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  l10n.log_progress,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.none,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    //const SizedBox(height: 100),
                  ],
                ),
              ],
            )
          ],
        );
      },
    );
  }

  Widget _buildProgressSummary({
    required String weight,
    required double weightChange,
    required String bodyFat,
    required double bodyFatChange,
    required String muscleMass,
    required double muscleMassChange,
    required Map<String, dynamic>? latestMeasurements,
  }) {
    final theme = Theme.of(context);
    final currentWeight = _toDouble(latestMeasurements?['weight']);
    final height = _toDouble(latestMeasurements?['height']);
    final bmi = (currentWeight != null && height != null)
        ? _calculateBMI(currentWeight, height)
        : null;
    final l10n = AppLocalizations.of(context)!;

    // Calculate previous BMI for change
    final previousWeight =
        currentWeight != null ? currentWeight - weightChange : null;
    final previousBMI = (previousWeight != null && height != null)
        ? _calculateBMI(previousWeight, height)
        : null;
    final bmiChange =
        (bmi != null && previousBMI != null) ? bmi - previousBMI : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.progress_summary,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProgressItem(
                  icon: Icons.monitor_weight,
                  label: l10n.weight,
                  value: '$weight kg',
                  change: _formatChange(weightChange),
                  isPositive: weightChange <= 0,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressItem(
                  icon: Icons.speed,
                  label: l10n.body_fat,
                  value: '$bodyFat%',
                  change: '${_formatChange(bodyFatChange)}%',
                  isPositive: bodyFatChange <= 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProgressItem(
                  icon: Icons.fitness_center,
                  label: l10n.muscle_mass_title,
                  value: '$muscleMass kg',
                  change: _formatChange(muscleMassChange),
                  isPositive: muscleMassChange >= 0,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressItem(
                  icon: Icons.monitor_heart_outlined,
                  label: l10n.bmi,
                  value: bmi?.toStringAsFixed(1) ?? '--',
                  change: _formatChange(bmiChange),
                  isPositive: bmiChange <= 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem({
    required IconData icon,
    required String label,
    required String value,
    required String change,
    required bool isPositive,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light ? myGrey10 : myGrey90,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: theme.brightness == Brightness.light ? const Color(0xFF1E293B) : Colors.white),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: theme.brightness == Brightness.light ? Colors.grey[600] : Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: isPositive ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 2),
              Text(
                change,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChart() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final progressLogs = userProvider.progressLogs ?? [];
        final theme = Theme.of(context);
        final l10n = AppLocalizations.of(context)!;

        if (progressLogs.isEmpty) {
          return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.brightness == Brightness.light 
                      ? Colors.grey.withOpacity(0.1)
                      : Colors.black.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  l10n.no_weight_data_available,
                  style: TextStyle(
                    color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                  ),
                ),
              ));
        }

        // Sort logs by date and prepare data points
        final weightData = progressLogs
            .map((log) {
              final weight = _toDouble(log['weight']);
              final date = (log['date'] as Timestamp).toDate();
              return {'weight': weight, 'date': date};
            })
            .where((data) => data['weight'] != null)
            .toList()
          ..sort((a, b) =>
              (a['date'] as DateTime).compareTo(b['date'] as DateTime));

        // Create spot data for the chart
        final spots = weightData.asMap().entries.map((entry) {
          final weight = entry.value['weight'] as double;
          return FlSpot(entry.key.toDouble(), weight);
        }).toList();

        // Find min and max values for Y axis
        final weights =
            weightData.map((data) => data['weight'] as double).toList();
        final minY = (weights.reduce(min) - 1).floorToDouble();
        final maxY = (weights.reduce(max) + 1).ceilToDouble();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.weight_progress,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.white,
                        tooltipRoundedRadius: 8,
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipBorder: BorderSide(
                          color: myGrey20,
                          width: 1,
                        ),
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((LineBarSpot touchedSpot) {
                            return LineTooltipItem(
                              '${touchedSpot.y.toStringAsFixed(1)} kg',
                              GoogleFonts.plusJakartaSans(
                                color: myBlue60,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 2,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: myGrey20,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= weightData.length ||
                                value.toInt() < 0) {
                              return const SizedBox();
                            }
                            final date =
                                weightData[value.toInt()]['date'] as DateTime;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MMM d').format(date),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: myGrey60,
                                ),
                              ),
                            );
                          },
                          interval: 1,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toStringAsFixed(0),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: myGrey60,
                              ),
                            );
                          },
                          interval: 2,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (weightData.length - 1).toDouble(),
                    minY: minY,
                    maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: myBlue60,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: myBlue60,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: myBlue60.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMeasurements() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final progressLogs = userProvider.progressLogs ?? [];
        if (progressLogs.isEmpty) {
          return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child:
                  Center(child: Text(l10n.no_measurement_data_available, style: GoogleFonts.plusJakartaSans(color: theme.brightness == Brightness.light ? myGrey60 : Colors.white,),)));
        }

        // Get latest and previous measurements
        final latestLog = progressLogs.first;
        final previousLog = progressLogs.length > 1 ? progressLogs[1] : null;

        // Get measurements maps
        final latestMeasurements =
            latestLog['measurements'] as Map<String, dynamic>?;
        final previousMeasurements =
            previousLog?['measurements'] as Map<String, dynamic>?;

        // Calculate changes for each measurement
        Map<String, Map<String, String>> measurementData = {
          'Chest': _getMeasurementData(
              'chest', latestMeasurements, previousMeasurements),
          'Waist': _getMeasurementData(
              'waist', latestMeasurements, previousMeasurements),
          'Hips': _getMeasurementData(
              'hips', latestMeasurements, previousMeasurements),
          'Biceps': _getMeasurementData(
              'biceps', latestMeasurements, previousMeasurements),
          'Thighs': _getMeasurementData(
              'thighs', latestMeasurements, previousMeasurements),
          'Calves': _getMeasurementData(
              'calves', latestMeasurements, previousMeasurements),
        };


        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.body_measurements,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ...measurementData.entries.map((entry) {
                final data = entry.value;
                return _buildMeasurementItem(
                  entry.key,
                  data['current'] ?? '--',
                  data['change'] ?? '--',
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // Helper method to get measurement data
  Map<String, String> _getMeasurementData(
    String measurement,
    Map<String, dynamic>? latest,
    Map<String, dynamic>? previous,
  ) {
    final currentValue = _toDouble(latest?[measurement]);
    final previousValue = _toDouble(previous?[measurement]);

    if (currentValue == null) {
      return {'current': '--', 'change': '--'};
    }

    final change = previousValue != null ? currentValue - previousValue : 0.0;
    final sign = change >= 0 ? '+' : '';

    return {
      'current': '${currentValue.toStringAsFixed(1)} cm',
      'change': '$sign${change.toStringAsFixed(1)} cm',
    };
  }

  Widget _buildMeasurementItem(String label, String value, String change) {
    final theme = Theme.of(context);
    final isPositive = !change.startsWith('-');
    final showChange = change != '--';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Label
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: theme.brightness == Brightness.light ? myGrey60 : Colors.white,
              ),
            ),
          ),
          // Value
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Change indicator
          if (showChange)
            Expanded(
              flex: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 12,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      change,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final progressLogs = userProvider.progressLogs ?? [];
        if (progressLogs.isEmpty) {
          return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child:
                  Center(child: Text(l10n.no_progress_photos_available, style: GoogleFonts.plusJakartaSans(color: theme.brightness == Brightness.light ? myGrey60 : Colors.white,))));
        }
        

        // Get logs with photos
        final logsWithPhotos = progressLogs.where((log) {
          final photos = log['progressPhotos'] as Map<String, dynamic>?;
          return photos != null && photos.isNotEmpty;
        }).toList();

        if (logsWithPhotos.isEmpty) {
          return const SizedBox.shrink();
        }

        // Get only the latest log with photos
        final latestLog = logsWithPhotos.first;
        final latestPhotos =
            latestLog['progressPhotos'] as Map<String, dynamic>;
        final latestDate = (latestLog['date'] as Timestamp).toDate();


        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.progress_photos,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PhotoComparisonPage(
                            progressLogs: logsWithPhotos,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.compare,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: myBlue60,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: myBlue60,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('MMM d, yyyy').format(latestDate),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: theme.brightness == Brightness.light ? myGrey60 : Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (latestPhotos['frontPhoto'] != null)
                        _buildPhotoThumbnail(
                          latestPhotos['frontPhoto'],
                          l10n.front,
                          latestPhotos,
                          latestDate,
                        ),
                      if (latestPhotos['backPhoto'] != null) ...[
                        const SizedBox(width: 8),
                        _buildPhotoThumbnail(
                          latestPhotos['backPhoto'],
                          l10n.back,
                          latestPhotos,
                          latestDate,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (latestPhotos['leftSidePhoto'] != null) ...[
                        const SizedBox(width: 8),
                        _buildPhotoThumbnail(
                          latestPhotos['leftSidePhoto'],
                          l10n.left_side,
                          latestPhotos,
                          latestDate,
                        ),
                      ],
                      if (latestPhotos['rightSidePhoto'] != null) ...[
                        const SizedBox(width: 8),
                        _buildPhotoThumbnail(
                          latestPhotos['rightSidePhoto'],
                          l10n.right_side,
                          latestPhotos,
                          latestDate,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoThumbnail(
    String photoUrl,
    String label,
    Map<String, dynamic> allPhotos,
    DateTime date,
  ) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        // Show full screen gallery
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProgressPhotoViewer(
              photos: allPhotos,
              date: date,
              initialView: label.toLowerCase(),
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 120,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(photoUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: theme.brightness == Brightness.light ? myGrey60 : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.light 
              ? Colors.grey.withOpacity(0.1)
              : Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recent_achievements,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildAchievementItem(
            icon: Icons.emoji_events,
            title: 'Weight Loss Goal',
            subtitle: 'Lost 5kg in 2 months',
            date: 'Dec 1, 2024',
          ),
          _buildAchievementItem(
            icon: Icons.fitness_center,
            title: 'Strength Milestone',
            subtitle: 'Bench Press 80kg',
            date: 'Nov 28, 2024',
          ),
          _buildAchievementItem(
            icon: Icons.timer,
            title: 'Consistency',
            subtitle: '20 workouts completed',
            date: 'Nov 15, 2024',
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String date,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light 
                ? const Color(0xFF1E293B).withOpacity(0.1)
                : myGrey70,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon, 
              color: theme.brightness == Brightness.light 
                ? const Color(0xFF1E293B)
                : Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: theme.brightness == Brightness.light ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Text(
            date,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: theme.brightness == Brightness.light ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutHistoryCard() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutHistoryPage(
              isEnteredByTrainer: widget.isEnteredByTrainer,
              passedClientForTrainer: widget.passedClientForTrainer,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light 
                  ? const Color(0xFF1E293B).withOpacity(0.1)
                  : myGrey70,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.history,
                color: theme.brightness == Brightness.light 
                  ? const Color(0xFF1E293B)
                  : Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.track_workout_history,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.view_detailed_workout_metrics_and_analytics,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: theme.brightness == Brightness.light ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.brightness == Brightness.light ? Colors.grey[400] : Colors.grey[500],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutAnalysis() {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<QuerySnapshot>(
      future: _workoutHistoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: myBlue60));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              l10n.no_workout_history_available,
              style: GoogleFonts.plusJakartaSans(),
            ),
          );
        }

        final workoutHistory = snapshot.data!.docs;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWorkoutHistoryCard(),
                _buildWorkoutSummaryCard(workoutHistory),
                const SizedBox(height: 24),
                _buildWorkoutDurationChart(workoutHistory),
                const SizedBox(height: 24),
                _buildExerciseAnalysis(workoutHistory),
                const SizedBox(height: 24),
                _buildBookmarkedExercisesSection(),
                const SizedBox(height: 24),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkoutSummaryCard(List<QueryDocumentSnapshot> workoutHistory) {
    final l10n = AppLocalizations.of(context)!;
    final totalWorkouts = workoutHistory.length;
    final thisMonth = workoutHistory.where((doc) {
      final completedAt = (doc['completedAt'] as Timestamp).toDate();
      final now = DateTime.now();
      return completedAt.month == now.month && completedAt.year == now.year;
    }).length;

    final totalDuration = workoutHistory.fold<int>(
      0,
      (sum, doc) => sum + (doc['totalDuration'] as int? ?? 0),
    );

    final averageDuration = totalWorkouts > 0
        ? Duration(seconds: totalDuration ~/ totalWorkouts)
        : Duration.zero;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.workout_summary,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  l10n.total_workouts,
                  totalWorkouts.toString(),
                  Icons.fitness_center,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  l10n.this_month,
                  thisMonth.toString(),
                  Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  l10n.average_duration,
                  '${averageDuration.inMinutes}min',
                  Icons.timer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: myGrey10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: myBlue60),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: myGrey60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutDurationChart(
      List<QueryDocumentSnapshot> workoutHistory) {
    final l10n = AppLocalizations.of(context)!;
    // Get last 7 workouts
    final recentWorkouts = workoutHistory.take(7).toList().reversed.toList();

    final spots = recentWorkouts.asMap().entries.map((entry) {
      final workout = entry.value;
      final duration = (workout['totalDuration'] as int?) ?? 0;
      return FlSpot(entry.key.toDouble(), duration / 60); // Convert to minutes
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recent_workout_durations,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 15,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: myGrey20,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= recentWorkouts.length) {
                          return const SizedBox();
                        }
                        final date = (recentWorkouts[value.toInt()]
                                ['completedAt'] as Timestamp)
                            .toDate();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('MMM d').format(date),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: myGrey60,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}m',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: myGrey60,
                          ),
                        );
                      },
                      interval: 15,
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: myBlue60,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: myBlue60,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: myBlue60.withOpacity(0.1),
                    ),
                  ),
                ],
                maxY: spots.map((spot) => spot.y).reduce(max) + 10,
                minY: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseAnalysis(List<QueryDocumentSnapshot> workoutHistory) {
    final l10n = AppLocalizations.of(context)!;
    // Collect exercise data across all workouts
    final exerciseStats = <String, Map<String, dynamic>>{};

    for (var workout in workoutHistory) {
      final phases = workout['phases'] as List<dynamic>;
      for (var phase in phases) {
        final exercises = phase['exercises'] as List<dynamic>;
        for (var exercise in exercises) {
          final name = exercise['name'] as String;
          final duration = exercise['duration'] as int;
          final isCompleted = exercise['isCompleted'] as bool;
          final sets = exercise['sets'] as List<dynamic>;

          if (!exerciseStats.containsKey(name)) {
            exerciseStats[name] = {
              'totalDuration': 0,
              'completedCount': 0,
              'totalAppearances': 0,
              'maxWeight': 0.0,
              'maxReps': 0,
              'totalWeight': 0.0,
              'totalReps': 0,
              'weightCount': 0, // Count of valid weight entries
              'repsCount': 0, // Count of valid reps entries
            };
          }

          // Process each set's actual values
          for (var set in sets) {
            final actual = set['actual'] as Map<String, dynamic>;
            if (set['isCompleted'] == true) {
              // Process weight
              final weightStr = actual['weight'] as String?;
              if (weightStr != null && weightStr.isNotEmpty) {
                final weight = double.tryParse(weightStr) ?? 0.0;
                exerciseStats[name]!['maxWeight'] =
                    max(exerciseStats[name]!['maxWeight'] as double, weight);
                exerciseStats[name]!['totalWeight'] += weight;
                exerciseStats[name]!['weightCount']++;
              }

              // Process reps
              final repsStr = actual['reps'] as String?;
              if (repsStr != null && repsStr.isNotEmpty) {
                final reps = int.tryParse(repsStr) ?? 0;
                exerciseStats[name]!['maxReps'] =
                    max(exerciseStats[name]!['maxReps'] as int, reps);
                exerciseStats[name]!['totalReps'] += reps;
                exerciseStats[name]!['repsCount']++;
              }
            }
          }

          exerciseStats[name]!['totalDuration'] += duration;
          if (isCompleted) exerciseStats[name]!['completedCount']++;
          exerciseStats[name]!['totalAppearances']++;
        }
      }
    }

    // Sort exercises by completion rate
    final sortedExercises = exerciseStats.entries.toList()
      ..sort((a, b) {
        final aCompletionRate =
            a.value['completedCount'] / a.value['totalAppearances'];
        final bCompletionRate =
            b.value['completedCount'] / b.value['totalAppearances'];
        return bCompletionRate.compareTo(aCompletionRate);
      });

    return Container(
      //padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        //color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.exercise_analysis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedExercises.take(5).map((entry) {
            final name = entry.key;
            final stats = entry.value;
            final completionRate =
                (stats['completedCount'] / stats['totalAppearances'] * 100)
                    .toStringAsFixed(0);
            final avgDuration =
                (stats['totalDuration'] / stats['totalAppearances'] / 60)
                    .toStringAsFixed(1);

            // Calculate averages for weight and reps
            final avgWeight = stats['weightCount'] > 0
                ? (stats['totalWeight'] / stats['weightCount'])
                    .toStringAsFixed(1)
                : '0';
            final avgReps = stats['repsCount'] > 0
                ? (stats['totalReps'] / stats['repsCount']).toStringAsFixed(1)
                : '0';
            final maxWeight = stats['maxWeight'].toStringAsFixed(1);
            final maxReps = stats['maxReps'].toString();

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$completionRate% completed',
                          style: GoogleFonts.plusJakartaSans(
                            color: myGrey60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: stats['completedCount'] /
                                  stats['totalAppearances'],
                              backgroundColor: myGrey20,
                              color: myBlue60,
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '~$avgDuration min',
                          style: GoogleFonts.plusJakartaSans(
                            color: myGrey60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem(
                          label: 'Avg Weight',
                          value: '$avgWeight kg',
                        ),
                        _buildStatItem(
                          label: 'Max Weight',
                          value: '$maxWeight kg',
                        ),
                        _buildStatItem(
                          label: 'Avg Reps',
                          value: avgReps,
                        ),
                        _buildStatItem(
                          label: 'Max Reps',
                          value: maxReps,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: myGrey60,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBookmarkedExercisesSection() {
    final l10n = AppLocalizations.of(context)!;
    if (_bookmarkedExercises.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.bookmark_border, size: 48, color: myGrey60),
              const SizedBox(height: 8),
              Text(
                l10n.no_bookmarked_exercises,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: myGrey60,
                ),
              ),
            ],
          ),
        ),
      );
    }
    

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.bookmarked_exercises,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.bookmark,
                color: myBlue60,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _bookmarkedExercises.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final exercise = _bookmarkedExercises[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: myBlue60.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: myBlue60,
                    size: 20,
                  ),
                ),
                title: Text(
                  exercise['name'],
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${exercise['workoutName']}\n${exercise['phaseName']}',
                  style: GoogleFonts.plusJakartaSans(
                    color: myGrey60,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccessNotGrantedCard(String title, String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: myGrey60,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: myGrey60,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: myGrey60,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
