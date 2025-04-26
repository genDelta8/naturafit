import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
class MealPlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final VoidCallback? onTap;
  final bool showViewDetails;

  const MealPlanCard({
    Key? key,
    required this.plan,
    this.onTap,
    this.showViewDetails = true,
  }) : super(key: key);

  // Helper function to check if a value is meaningful
  bool hasMeaningfulValue(dynamic value) {
    return value != null &&
        value.toString().isNotEmpty &&
        value.toString() != 'N/A' &&
        value.toString() != '';
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'current':
        return const Color(0xFF2196F3); // Bright Blue
      case 'active':
      case 'confirmed':
        return const Color(0xFF4CAF50); // Vibrant Green
      case 'pending':
        return const Color(0xFFFFC107); // Warm Yellow
      case 'template':
        return const Color(0xFF9C27B0); // Rich Purple
      default:
        return const Color(0xFF9E9E9E); // Neutral Grey
    }
  }

  Widget _buildPlanDetail(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light ? myGrey20 : myGrey80,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: theme.brightness == Brightness.light ? myGrey70 : myGrey30,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacroIndicator(String label, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? myBlue70.withOpacity(0.1)
            : myBlue40.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value%',
        style: GoogleFonts.plusJakartaSans(
          color: theme.brightness == Brightness.light ? myBlue70 : myBlue40,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  String _getLocalizedStatus(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'current':
        return l10n.status_current;
      case 'active':
        return l10n.status_active;
      case 'confirmed':
        return l10n.status_confirmed;
      case 'pending':
        return l10n.status_pending;
      case 'template':
        return l10n.status_template;
      case 'completed':
        return l10n.status_completed;
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = plan['status'] ?? 'active';
    final statusColor = _getStatusColor(status);
    final macros = plan['macros'] as Map<String, dynamic>?;
    final l10n = AppLocalizations.of(context)!;

    

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 24),
        elevation: 1,
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light ? myGrey70 : myGrey90,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(
                  bottom: BorderSide(
                    color: theme.brightness == Brightness.light
                        ? myGrey30
                        : myGrey80,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      plan['planName'] == '' ? l10n.meal_plan : plan['planName'],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        color: theme.brightness == Brightness.light
                            ? myGrey10
                            : Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getLocalizedStatus(status, l10n),
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasMeaningfulValue(
                      plan['clientFullName'] ?? plan['clientUsername']))
                    _buildPlanDetail(
                      Icons.person_outline,
                      l10n.client_label,
                      plan['clientFullName'] ?? plan['clientUsername']!,
                      theme,
                    ),
                  if (hasMeaningfulValue(plan['duration'])) ...[
                    const SizedBox(height: 12),
                    _buildPlanDetail(
                      Icons.calendar_today_outlined,
                      l10n.duration_label,
                      plan['duration']!,
                      theme,
                    ),
                  ],
                  if (hasMeaningfulValue(plan['dietType'])) ...[
                    const SizedBox(height: 12),
                    _buildPlanDetail(
                      Icons.restaurant_menu_outlined,
                      l10n.diet_type_label,
                      plan['dietType']!,
                      theme,
                    ),
                  ],
                  if (macros != null &&
                      hasMeaningfulValue(macros['protein']) &&
                      hasMeaningfulValue(macros['carbs']) &&
                      hasMeaningfulValue(macros['fats'])) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.light
                                ? myGrey20
                                : myGrey80,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.pie_chart_outline,
                            size: 14,
                            color: theme.brightness == Brightness.light
                                ? myGrey70
                                : myGrey30,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.macros,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: theme.brightness == Brightness.light
                                      ? myGrey60
                                      : myGrey10,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _buildMacroIndicator(
                                      'P', macros['protein'] ?? '0', theme),
                                  const SizedBox(width: 8),
                                  _buildMacroIndicator(
                                      'C', macros['carbs'] ?? '0', theme),
                                  const SizedBox(width: 8),
                                  _buildMacroIndicator(
                                      'F', macros['fats'] ?? '0', theme),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (showViewDetails)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.light
                      ? myGrey20
                      : myGrey80,
                  border: Border(
                    top: BorderSide(
                      color: theme.brightness == Brightness.light
                          ? myGrey30
                          : myGrey70,
                    ),
                  ),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      l10n.view_details,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: theme.brightness == Brightness.light
                          ? myGrey60
                          : myGrey40,
                      size: 18,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
} 