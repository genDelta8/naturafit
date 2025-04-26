import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_search_bar.dart';
import 'package:naturafit/widgets/custom_selectable_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TrainerSpecializationsPage extends StatefulWidget {
  final List<String> initialSpecializations;
  
  const TrainerSpecializationsPage({
    super.key,
    required this.initialSpecializations,
  });

  @override
  State<TrainerSpecializationsPage> createState() => _TrainerSpecializationsPageState();
}

class _TrainerSpecializationsPageState extends State<TrainerSpecializationsPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customSpecController = TextEditingController();
  String _selectedCategory = 'General'; // Default category
  bool _showSearchBar = false;
  final List<String> _selectedSpecializations = [];
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _selectedSpecializations.addAll(widget.initialSpecializations);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customSpecController.dispose();
    super.dispose();
  }


  void _checkForChanges() {
    final initialSet = Set<String>.from(widget.initialSpecializations);
    final currentSet = Set<String>.from(_selectedSpecializations);
    
    setState(() {
      _hasUnsavedChanges = !setEquals(initialSet, currentSet);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    setState(() {
      _selectedCategory = l10n.general;
    });
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
          l10n.specializations,
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
                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(color: myBlue60),
                      ),
                    );

                    // Update specializations in Firebase
                    if (context.mounted) {
                      await FirebaseService().updateUser({
                        'specializations': _selectedSpecializations,
                      }, context);
                    }

                    // Update UserProvider
                    if (context.mounted) {
                      final userProvider = context.read<UserProvider>();
                      final currentData = Map<String, dynamic>.from(userProvider.userData ?? {});
                      currentData['specializations'] = _selectedSpecializations;
                      userProvider.setUserData(currentData);

                      Navigator.pop(context); // Close loading dialog
                      Navigator.pop(context); // Return to settings page
                    }
                  } catch (e) {
                    // Close loading indicator if open
                    if (context.mounted && Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }

                    // Show error dialog
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
      body: _buildSpecializationsStep(),
    );
  }

  Widget _buildSpecializationsStep() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);



    // Add this map to store categories and their specializations
  final Map<String, List<String>> specializationCategories = {
    l10n.general: [
      l10n.weight_loss_coaching,
      l10n.strength_training,
      l10n.cardiovascular_endurance,
      l10n.core_stability_training,
      l10n.functional_fitness_training,
      l10n.general_fitness_for_beginners,
      l10n.body_recomposition,
      l10n.metabolic_conditioning,
      l10n.low_impact_fitness,
      l10n.circuit_training,
    ],
    l10n.advanced: [
      l10n.high_intensity_interval_training,
      l10n.crossfit_coaching,
      l10n.powerlifting,
      l10n.olympic_lifting,
      l10n.strongman_training,
      l10n.kettlebell_training,
      l10n.suspension_training,
      l10n.plyometrics_and_explosive_movements,
      l10n.hybrid_training,
      l10n.agility_and_speed_training,
    ],
    l10n.sports: [
      l10n.sports_specific_conditioning,
      l10n.marathon_training,
      l10n.triathlon_training,
      l10n.cycling_and_spin_training,
      l10n.swimming_and_aquatic_training,
      l10n.golf_fitness,
      l10n.tennis_fitness,
      l10n.soccer_conditioning,
      l10n.basketball_training,
      l10n.martial_arts_fitness,
    ],
    l10n.recovery: [
      l10n.pre_and_post_natal_fitness,
      l10n.senior_fitness,
      l10n.youth_fitness,
      l10n.post_rehabilitation_training,
      l10n.joint_pain_management,
      l10n.chronic_disease_management,
      l10n.injury_prevention,
      l10n.mobility_and_flexibility_training,
      l10n.stress_management_programs,
      l10n.restorative_fitness,
    ],
    l10n.transformation: [
      l10n.bodybuilding,
      l10n.physique_and_aesthetic_coaching,
      l10n.bikini_competition_preparation,
      l10n.muscle_gain_programs,
      l10n.lean_bulk_planning,
      l10n.contest_preparation_coaching,
      l10n.weight_gain_assistance,
      l10n.advanced_sculpting_programs,
      l10n.maintenance_coaching,
      l10n.body_dysmorphia_awareness_training,
    ],
    l10n.mind_body: [
      l10n.yoga,
      l10n.pilates,
      l10n.tai_chi_fitness,
      l10n.mindfulness_based_fitness,
      l10n.meditation_integration,
      l10n.breathing_techniques,
      l10n.body_mind_centering,
      l10n.qigong_for_fitness,
      l10n.barre_workouts,
      l10n.dance_fitness,
    ],
    l10n.lifestyle: [
      l10n.corporate_fitness_programs,
      l10n.family_fitness,
      l10n.outdoor_adventure_fitness,
      l10n.hiking_and_trail_fitness,
      l10n.fitness_for_gamers,
      l10n.military_and_tactical_fitness,
      l10n.emergency_services_fitness,
      l10n.fitness_for_travelers,
      l10n.minimalist_fitness_bodyweight,
      l10n.home_workouts,
    ],
    l10n.diet_and_nutrition: [
      l10n.nutrition_planning,
      l10n.plant_based_nutrition_coaching,
      l10n.ketogenic_diet_support,
      l10n.paleo_diet_fitness_programs,
      l10n.intermittent_fasting_guidance,
      l10n.sports_nutrition_coaching,
      l10n.weight_loss_meal_planning,
      l10n.lean_mass_nutrition,
      l10n.food_intolerance_management,
      l10n.gut_health_and_fitness,
    ],
    l10n.specialty: [
      l10n.lgbtq_inclusive_fitness,
      l10n.adaptive_fitness_for_disabilities,
      l10n.neurodivergent_fitness_programs,
      l10n.fitness_for_cancer_survivors,
      l10n.arthritis_friendly_training,
      l10n.fibromyalgia_specific_workouts,
      l10n.cardiac_rehabilitation_programs,
      l10n.diabetes_specific_fitness,
      l10n.autoimmune_disorder_friendly_fitness,
      l10n.hormonal_balance_training,
    ],
    l10n.technology: [
      l10n.wearable_tech_integration,
      l10n.online_personal_training,
      l10n.app_based_fitness_guidance,
      l10n.virtual_reality_fitness_programs,
      l10n.fitness_gamification_coaching,
      l10n.ai_driven_workouts,
      l10n.biofeedback_coaching,
      l10n.genetic_fitness_planning,
      l10n.data_driven_fitness_programs,
      l10n.fitness_equipment_mastery,
    ],
  };




    List<String> filteredSpecs = [];
    if (_searchController.text.isEmpty) {
      filteredSpecs = specializationCategories[_selectedCategory] ?? [];
    } else {
      filteredSpecs = specializationCategories.values
          .expand((specs) => specs)
          .where((spec) =>
              spec.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.specializations,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                ),
              ),
              const SizedBox(height: 16),
          
              
              
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: [
                            const SizedBox(width: 8),
                            ...specializationCategories.keys.map((category) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _selectedCategory == category
                                          ? myGrey30
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: _selectedCategory == category
                                            ? myGrey90
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: _selectedCategory == category
                                              ? Colors.transparent
                                              : theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      child: Text(
                                        category,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: _selectedCategory == category
                                              ? Colors.white
                                              : theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ]),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showSearchBar = !_showSearchBar;
                              if (!_showSearchBar) {
                                _searchController.clear();
                              }
                            });
                          },
                          child: Icon(
                            Icons.search,
                            color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          
              const SizedBox(height: 8),
          
              if (_showSearchBar)
                CustomSearchBar(
                  controller: _searchController,
                  hintText: l10n.search_specializations,
                  onChanged: (value) => setState(() {}),
                ),
          
              const SizedBox(height: 8),
              CustomSelectableList(
                items: _searchController.text.isEmpty 
                  ? specializationCategories[_selectedCategory] ?? []
                  : specializationCategories.values
                      .expand((specs) => specs)
                      .where((spec) => 
                        spec.toLowerCase().contains(_searchController.text.toLowerCase()))
                      .toList(),
                selectedItems: _selectedSpecializations,
                onItemSelected: (item) {
                  setState(() {
                    _selectedSpecializations.add(item);
                  });
                  _checkForChanges();
                },
                onItemDeselected: (item) {
                  setState(() {
                    _selectedSpecializations.remove(item);
                  });
                  _checkForChanges();
                },
              ),
          
              const SizedBox(height: 0),
          
              Row(
                children: [
                  Expanded(
                    child: CustomFocusTextField(
                      label: '',
                      hintText: l10n.enter_custom_specialization,
                      controller: _customSpecController,
                      prefixIcon: Icons.category_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_customSpecController.text.isNotEmpty) {
                        setState(() {
                          _selectedSpecializations.add(_customSpecController.text);
                          _customSpecController.clear();
                        });
                        _checkForChanges();
                      }
                    },
                    child: Text(l10n.add),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: myBlue60,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
          
              //const SizedBox(height: 16),
          
              if (_selectedSpecializations.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.selected,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedSpecializations.map((spec) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.light ? myGrey20 : myGrey80,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  spec,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: theme.brightness == Brightness.light ? myGrey70 : myGrey30,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedSpecializations.remove(spec);
                                    });
                                    _checkForChanges();
                                  },
                                  child: Icon(
                                    Icons.close,
                                    size: 18,
                                    color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 