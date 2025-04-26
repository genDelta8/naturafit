import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProgressDetailPage extends StatelessWidget {
  final Map<String, dynamic> progressData;
  final Map<String, dynamic>? passedConsentSettingsForTrainer;

  const ProgressDetailPage({
    super.key,
    required this.progressData,
    this.passedConsentSettingsForTrainer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final date = (progressData['date'] as Timestamp).toDate();
    final measurements = progressData['measurements'] as Map<String, dynamic>?;
    final progressPhotos = progressData['progressPhotos'] as Map<String, dynamic>?;

    

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.progress_details,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (passedConsentSettingsForTrainer != null) ...[
              if (passedConsentSettingsForTrainer!['measurements'] == true) ...[
                _buildSection(
                  title: 'Basic Measurements',
                  child: _buildBasicMeasurements(),
                ),
                if (measurements != null && measurements.isNotEmpty)
                  _buildSection(
                    title: 'Body Measurements',
                    child: _buildBodyMeasurements(measurements),
                  ),
              ] else
                _buildAccessNotGrantedCard(
                  l10n.measurements_access_denied,
                  l10n.measurements_access_message,
                  Icons.straighten,
                ),
              
              const SizedBox(height: 16),
              
              if (passedConsentSettingsForTrainer!['progressPhotos'] == true) ...[
                if (progressPhotos != null && progressPhotos.isNotEmpty)
                  _buildSection(
                    title: 'Progress Photos',
                    child: _buildProgressPhotos(progressPhotos),
                  ),
              ] else
                _buildAccessNotGrantedCard(
                  l10n.photos_access_denied,
                  l10n.photos_access_message,
                  Icons.photo_library,
                ),
            ] else ...[
              _buildSection(
                title: 'Basic Measurements',
                child: _buildBasicMeasurements(),
              ),
              if (measurements != null && measurements.isNotEmpty)
                _buildSection(
                  title: 'Body Measurements',
                  child: _buildBodyMeasurements(measurements),
                ),
              if (progressPhotos != null && progressPhotos.isNotEmpty)
                _buildSection(
                  title: 'Progress Photos',
                  child: _buildProgressPhotos(progressPhotos),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                ),
              ),
            ),
            child,
          ],
        );
      }
    );
  }

  Widget _buildMeasurementRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light ? myGrey20 : myGrey70,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: theme.brightness == Brightness.light ? myGrey90 : Colors.white
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: theme.brightness == Brightness.light ? myGrey70 : Colors.grey[400],
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildPhotoCard(String title, String imageUrl) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.brightness == Brightness.light ? myGrey70 : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 150,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: myGrey20,
                  child: const Center(
                    child: CircularProgressIndicator(color: myGrey30),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: myGrey20,
                  child: const Icon(
                    Icons.person_outline,
                    color: myGrey60,
                  ),
                ),
              ),
              
            ),
          ],
        );
      }
    );
  }

  Widget _buildAccessNotGrantedCard(String title, String message, IconData icon) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: theme.brightness == Brightness.light ? myGrey60 : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.brightness == Brightness.light ? myGrey60 : Colors.grey[300],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: theme.brightness == Brightness.light ? myGrey60 : Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildBasicMeasurements() {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildMeasurementRow(
                icon: Icons.monitor_weight,
                label: 'Weight',
                value: '${double.parse(progressData['weight'].toString()).toStringAsFixed(1)} kg',
              ),
              const SizedBox(height: 16),
              _buildMeasurementRow(
                icon: Icons.height,
                label: 'Height',
                value: '${double.parse(progressData['height'].toString()).toStringAsFixed(1)} cm',
              ),
              if (progressData['bodyFat'] != null) ...[
                const SizedBox(height: 16),
                _buildMeasurementRow(
                  icon: Icons.speed,
                  label: 'Body Fat',
                  value: '${progressData['bodyFat']}%',
                ),
              ],
              if (progressData['muscleMass'] != null) ...[
                const SizedBox(height: 16),
                _buildMeasurementRow(
                  icon: Icons.fitness_center,
                  label: 'Muscle Mass',
                  value: '${progressData['muscleMass']} kg',
                ),
              ],
            ],
          ),
        );
      }
    );
  }

  Widget _buildBodyMeasurements(Map<String, dynamic> measurements) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (measurements['chest'] != null)
                _buildMeasurementRow(
                  icon: Icons.accessibility_new,
                  label: 'Chest',
                  value: '${measurements['chest']} cm',
                ),
              if (measurements['waist'] != null) ...[
                const SizedBox(height: 16),
                _buildMeasurementRow(
                  icon: Icons.straighten,
                  label: 'Waist',
                  value: '${measurements['waist']} cm',
                ),
              ],
              if (measurements['hips'] != null) ...[
                const SizedBox(height: 16),
                _buildMeasurementRow(
                  icon: Icons.height,
                  label: 'Hips',
                  value: '${measurements['hips']} cm',
                ),
              ],
              if (measurements['biceps'] != null) ...[
                const SizedBox(height: 16),
                _buildMeasurementRow(
                  icon: Icons.fitness_center,
                  label: 'Biceps',
                  value: '${measurements['biceps']} cm',
                ),
              ],
              if (measurements['thighs'] != null) ...[
                const SizedBox(height: 16),
                _buildMeasurementRow(
                  icon: Icons.directions_run,
                  label: 'Thighs',
                  value: '${measurements['thighs']} cm',
                ),
              ],
              if (measurements['calves'] != null) ...[
                const SizedBox(height: 16),
                _buildMeasurementRow(
                  icon: Icons.directions_walk,
                  label: 'Calves',
                  value: '${measurements['calves']} cm',
                ),
              ],
            ],
          ),
        );
      }
    );
  }

  Widget _buildProgressPhotos(Map<String, dynamic> progressPhotos) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (progressPhotos['frontPhoto'] != null)
                _buildPhotoCard('Front View', progressPhotos['frontPhoto']),
              if (progressPhotos['backPhoto'] != null)
                _buildPhotoCard('Back View', progressPhotos['backPhoto']),
              if (progressPhotos['leftSidePhoto'] != null)
                _buildPhotoCard('Left Side', progressPhotos['leftSidePhoto']),
              if (progressPhotos['rightSidePhoto'] != null)
                _buildPhotoCard('Right Side', progressPhotos['rightSidePhoto']),
            ],
          ),
        );
      }
    );
  }
} 