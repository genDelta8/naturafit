import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/views/trainer_side/assessment_form_page.dart';
import 'package:naturafit/views/trainer_side/trainer_profile_page.dart';
import 'package:naturafit/widgets/custom_user_profile_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TrainerDetailPage extends StatefulWidget {
  final Map<String, dynamic> trainer;

  const TrainerDetailPage({
    Key? key,
    required this.trainer,
  }) : super(key: key);

  @override
  State<TrainerDetailPage> createState() => _TrainerDetailPageState();
}

class _TrainerDetailPageState extends State<TrainerDetailPage> {
  Map<String, dynamic>? _trainerData;
  bool _isLoading = true;
   Map<String, dynamic>? _latestAssessmentForm;

  @override
  void initState() {
    super.initState();
    _fetchTrainerData();
    _fetchLatestAssessmentForm();
  }

  Future<void> _fetchLatestAssessmentForm() async {
    debugPrint('Fetching latest assessment form for trainer: ${widget.trainer['professionalId']}');
    try {
      final userData = context.read<UserProvider>().userData;
      if (userData == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('assessment_forms')
          .doc(userData['userId'])
          .collection('all_forms')
          .where('trainerId', isEqualTo: widget.trainer['professionalId'])
          .orderBy('completedDate', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _latestAssessmentForm = querySnapshot.docs.first.data();
          debugPrint('Latest assessment form found: ${_latestAssessmentForm?['status']}');
        });
      } else {
        debugPrint('No assessment forms found for this client');
      }
    } catch (e) {
      debugPrint('Error fetching latest assessment form: $e');
    }
  }

  Future<void> _fetchTrainerData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.trainer['professionalId'])
          .get();

      if (doc.exists) {
        setState(() {
          _trainerData = doc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching trainer data: $e');
    }
    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildInfoRow(String label, String? value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: theme.brightness == Brightness.light
                  ? Colors.grey[600]
                  : Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label == 'Phone'
                ? _formatPhoneNumber(value ?? 'N/A')
                : value ?? 'N/A',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: theme.brightness == Brightness.light
                  ? Colors.black87
                  : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {
        debugPrint('Navigating to trainer profile page');
        debugPrint('_trainerData: $_trainerData');
        debugPrint('widget.trainer: ${widget.trainer}');
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => TrainerProfilePage(
                    passedTrainer: _trainerData,
                    isEnteredByClient: true,
                    passedWidgetTrainer: widget.trainer,
                  )),
        );
      },
      child: Card(
        elevation: 0,
        color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CustomUserProfileImage(
                imageUrl: widget.trainer['professionalProfileImageUrl'],
                name: widget.trainer['professionalFullName'],
                size: 48,
                borderRadius: 12,
                backgroundColor:
                    theme.brightness == Brightness.dark ? myGrey70 : myGrey30,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.trainer['professionalFullName'],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: theme.brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: myBlue60.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.trainer,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: myBlue60,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentFormCard() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final userData = context.read<UserProvider>().userData;
    final clientId = userData?['userId'];
    final clientName = userData?['fullName'];

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _latestAssessmentForm?['status'] == 'completed'
              ? myTeal40
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssessmentFormPage(
                clientId: clientId,
                clientName: clientName,
                isEnteredByTrainer: true,
                existingForm: _latestAssessmentForm,
                dontShowRequestButton: true,
              ),
            ),
          ).then((_) {
            // Refresh the form data when returning from AssessmentFormPage
            _fetchLatestAssessmentForm();
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _latestAssessmentForm?['status'] == 'completed'
                      ? myTeal40.withOpacity(0.1)
                      : theme.brightness == Brightness.light
                          ? myBlue60.withOpacity(0.1)
                          : myGrey80,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  color: _latestAssessmentForm?['status'] == 'completed'
                      ? myTeal40
                      : theme.brightness == Brightness.light
                          ? myBlue60
                          : myGrey40,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.assessment_form,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      l10n.assessment_form_subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.brightness == Brightness.light
                            ? myGrey60
                            : myGrey40,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: _latestAssessmentForm?['status'] == 'completed'
                    ? myTeal40
                    : theme.brightness == Brightness.light
                        ? myBlue60
                        : myGrey40,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
                color: theme.brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
                width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.chevron_left,
                color: theme.brightness == Brightness.light
                    ? Colors.black
                    : Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          l10n.trainer_details,
          style: GoogleFonts.plusJakartaSans(
            color: theme.brightness == Brightness.light
                ? Colors.black
                : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: myBlue60))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProfileSection(),
                const SizedBox(height: 16),
                if (_latestAssessmentForm != null) ...[
                  _buildAssessmentFormCard(),
                  const SizedBox(height: 16),
                ],
                if (_trainerData != null) ...[
                  _buildInfoSection(
                    l10n.contact_information,
                    [
                      _buildInfoRow(l10n.email, _trainerData!['email']),
                      _buildInfoRow(l10n.phone, _trainerData!['phone']),
                      _buildInfoRow(l10n.location, _trainerData!['location']),
                    ],
                  ),
                  const SizedBox(height: 16),
                  /*
                  _buildInfoSection(
                    l10n.professional_information,
                    [
                      _buildInfoRow(
                          l10n.specialization, _trainerData!['specialization']),
                      _buildInfoRow(
                          l10n.experience, _trainerData!['yearsOfExperience']),
                      _buildInfoRow(
                          l10n.certifications, _trainerData!['certifications']),
                    ],
                  ),
                  */
                  /*
                  const SizedBox(height: 16),
                  _buildAvailableHoursInfo(_trainerData!['availableHours']),
                  */
                ],
              ],
            ),
    );
  }


  // Add this helper method to format available hours
  Widget _buildAvailableHoursInfo(Map<String, dynamic>? availableHours) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    if (availableHours == null || availableHours.isEmpty) {
      return _buildInfoSection(
        l10n.availability,
        [
          Text(
            l10n.no_availability_set,
            style: GoogleFonts.plusJakartaSans(
              color: myGrey60,
            ),
          ),
        ],
      );
    }

    final orderedDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // Handle both direct map and nested map cases
    final hoursData = availableHours['availableHours'] ?? availableHours;

    return _buildInfoSection(
      l10n.availability,
      [
        ...orderedDays.map((day) {
          final slots = (hoursData[day] as List?)?.cast<Map<String, dynamic>>() ?? [];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    _getDayName(day),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: slots.isEmpty
                    ? Text(
                        l10n.not_available,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: slots.map<Widget>((slot) {
                          final startTime = formatTimeString(slot['start'].toString());
                          final endTime = formatTimeString(slot['end'].toString());
                          return Text(
                            '$startTime - $endTime',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.brightness == Brightness.light ? myGrey60 : Colors.white70,
                            ),
                          );
                        }).toList(),
                      ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  String formatTimeString(String timeStr) {
    // Split the time string into hours and minutes
    final parts = timeStr.split(':');
    if (parts.length != 2) return timeStr;

    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;

    // Create a DateTime object for today with the given hours and minutes
    final time = DateTime(2024, 1, 1, hours, minutes);

    // Get user's time format preference
    final userData = context.read<UserProvider>().userData;
    final is24Hour = userData?['timeFormat'] == '24-hour';

    // Format the time based on preference
    final timeFormat = is24Hour ? 'HH:mm' : 'h:mm a';
    return DateFormat(timeFormat).format(time);
  }

  String _getDayName(String shortDay) {
    final l10n = AppLocalizations.of(context)!;
    switch (shortDay) {
      case 'Mon': return l10n.monday;
      case 'Tue': return l10n.tuesday;
      case 'Wed': return l10n.wednesday;
      case 'Thu': return l10n.thursday;
      case 'Fri': return l10n.friday;
      case 'Sat': return l10n.saturday;
      case 'Sun': return l10n.sunday;
      default: return shortDay;
    }
  }

  // Add this helper method to format phone numbers
  String _formatPhoneNumber(String phone) {
    if (phone.isEmpty) {
      return 'N/A';
    }
    // Handle country code format (XX|+XX|XXXXXXXX)
    if (phone.contains('|')) {
      // Split by pipe character
      List<String> parts = phone.split('|');
      if (parts.length == 3) {
        String countryCode =
            parts[1].substring(1); // Remove the + from second part
        String number = parts[2];

        // Format as (+XX) XXXXXXXXX
        return '(+$countryCode) $number';
      }
    }

    // If no special format, just return as is with spaces every 3 digits
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    List<String> parts = [];
    String temp = cleaned;
    while (temp.length > 3) {
      parts.add(temp.substring(0, 3));
      temp = temp.substring(3);
    }
    if (temp.isNotEmpty) {
      parts.add(temp);
    }

    return parts.join(' ');
  }
}
