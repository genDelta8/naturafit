import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/views/client_side/client_meal/client_meal_plans_page.dart';
import 'package:naturafit/views/client_side/client_meal/meal_detail_page.dart';
import 'package:naturafit/views/client_side/client_meal_plan_details_page.dart';
import 'package:naturafit/views/web/web_client_side.dart';
import 'package:naturafit/widgets/meal_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Meal {
  final String name;
  final String calories;
  final String? protein;
  final String? carbs;
  final String? fats;

  Meal({
    required this.name,
    required this.calories,
    this.protein,
    this.carbs,
    this.fats,
  });
}

class DailyMeals {
  final String dayName;
  final List<Meal> meals;
  final int dayNumber;

  DailyMeals({
    required this.dayName,
    required this.meals,
    required this.dayNumber,
  });
}

class MealCard extends StatelessWidget {
  final Meal meal;
  final String mealTime;
  final Map<String, dynamic> originalMeal;

  const MealCard({
    super.key,
    required this.meal,
    required this.mealTime,
    required this.originalMeal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MealDetailPage(meal: originalMeal)),
        );
      },
      child: Card(
        color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: myBlue20,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getMealTypeIcon(mealTime),
                          color: myBlue60,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mealTime,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: theme.brightness == Brightness.light ? Colors.grey[600] : Colors.grey[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            meal.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                              color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildNutritionDetail(meal.calories, ' kcal', context),
                    const SizedBox(width: 8),
                    if (meal.protein != null)
                      _buildNutritionDetail(meal.protein!, 'g protein', context),
                    if (meal.carbs != null) ...[
                      const SizedBox(width: 8),
                      _buildNutritionDetail(meal.carbs!, 'g carbs', context),
                    ],
                    if (meal.fats != null) ...[
                      const SizedBox(width: 8),
                      _buildNutritionDetail(meal.fats!, 'g fats', context),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionDetail(String value, String unit, BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light ? myGrey20 : myGrey70,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$value$unit',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: theme.brightness == Brightness.light ? myGrey60 : myGrey30,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

IconData _getMealTypeIcon(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return Icons.breakfast_dining;
      case 'Morning Snack':
        return Icons.apple;
      case 'Lunch':
        return Icons.lunch_dining;
      case 'Afternoon Snack':
        return Icons.cookie;
      case 'Dinner':
        return Icons.dinner_dining;
      case 'Evening Snack':
        return Icons.night_shelter;
      default:
        return Icons.restaurant;
    }
  }

class CurrentMealPlanPage extends StatefulWidget {
  const CurrentMealPlanPage({super.key});

  @override
  State<CurrentMealPlanPage> createState() => _CurrentMealPlanPageState();
}

class _CurrentMealPlanPageState extends State<CurrentMealPlanPage> {
  late int _selectedDayNumber;
  String _selectedDay = 'Monday';
  Map<String, dynamic>? currentPlan;
  bool isLoading = true;
  final Set<String> _expandedMealIds = {};

  @override
  void initState() {
    super.initState();
    _selectedDayNumber = 1;
    _loadCurrentPlan();
  }

  Future<void> _loadCurrentPlan() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final mealPlans = userProvider.mealPlans ?? [];
    
    final currentPlanData = mealPlans.firstWhere(
      (plan) => plan['status'] == 'current',
      orElse: () => {},
    );

    setState(() {
      currentPlan = currentPlanData;
      isLoading = false;
    });
  }

  navigateToAncestor() {
    final myIsWebOrDektop = isWebOrDesktopCached;
    final webClientState = context.findAncestorStateOfType<WebClientSideState>();
    if (webClientState != null && myIsWebOrDektop) {
      webClientState.setState(() {
        webClientState.setCurrentPage(const ClientMealPlansPage(), 'ClientMealPlansPage');
      });
    }
    else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ClientMealPlansPage()),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: myBlue60),
        ),
      );
    }

    if (currentPlan == null || currentPlan!.isEmpty) {
      return Scaffold(
        backgroundColor: myGrey10,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            l10n.current_meal_plan,
            style: GoogleFonts.plusJakartaSans(
              color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          //backgroundColor: myGrey80,
          elevation: 0,
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                //color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: IconButton(
                icon: const Icon(Icons.restaurant_menu),
                color: Colors.black,
                onPressed: () => navigateToAncestor(),
              ),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_menu_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
            l10n.no_current_meal_plan,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.check_meal_plans,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => navigateToAncestor(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: myBlue60,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.view_meal_plans,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      );
    }

    // Rest of the existing build method with real data
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: false,
        title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentPlan!['planName'] == '' ? 'Meal Plan' : (currentPlan!['planName'] ?? 'Meal Plan'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                          ),
                        ),
                        Text(
                          l10n.created_by_trainer(currentPlan!['trainerName'] ?? 'Professional'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: Colors.grey[600],
                            letterSpacing: -0.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
        actions: [
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                //color: theme.brightness == Brightness.light ? myGrey10 : myGrey80,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.brightness == Brightness.light ? Colors.black : Colors.white, width: 1),
              ),
              child: IconButton(
                icon: const Icon(Icons.restaurant_menu),
                color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                onPressed: () => navigateToAncestor(),
              ),
            ),
          ],
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            height: 110,
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: myGrey80,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                    
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(l10n.daily_calories, 
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: myGrey10, fontWeight: FontWeight.w500),),
                        const Icon(Icons.local_fire_department_outlined, color: myGrey10, size: 20,),
                      ],
                    ),
                    Text('${calculateDailyTotals()['calories']} kcal', 
                    style: GoogleFonts.plusJakartaSans(fontSize: 24, color: myYellow40, fontWeight: FontWeight.w600),),
                  
                    
                  const Spacer(),
                    
                  GestureDetector(
                    onTap: () {
                      debugPrint('Daily Calories');
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ClientMealPlanDetailsPage(planData: currentPlan!)));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: myBlue60,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(l10n.learn_more, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700),),
                    ),
                  ),
                  
                  ],
                ),
                    
                    
                    
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text('Protein ', style: GoogleFonts.plusJakartaSans(fontSize: 16, color: myBlue50, fontWeight: FontWeight.w500),),
                        Text('${calculateDailyTotals()['protein']}g', style: GoogleFonts.plusJakartaSans(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500),),
                      ],
                    ),
                    
                    Row(
                      children: [
                        Text('Carbs ', style: GoogleFonts.plusJakartaSans(fontSize: 16, color: myRed40, fontWeight: FontWeight.w500),),
                        Text('${calculateDailyTotals()['carbs']}g', style: GoogleFonts.plusJakartaSans(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500),),
                      ],
                    ),
                    
                    Row(
                      children: [
                        Text('Fats ', style: GoogleFonts.plusJakartaSans(fontSize: 16, color: myTeal30, fontWeight: FontWeight.w500),),
                        Text('${calculateDailyTotals()['fats']}g', style: GoogleFonts.plusJakartaSans(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500),),
                      ],
                    ),
                    
                    
                  ],
                ),
              ],
            ),
          ),

/*
          Container(
            padding: const EdgeInsets.all(16),
            
            child: Column(
              children: [
                // Daily totals summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryCard(
                      "${calculateDailyTotals()['calories']}",
                      "Daily\nCalories",
                      myYellow50,
                    ),
                    _buildSummaryCard(
                      "${calculateDailyTotals()['protein']}g",
                      "Daily\nProtein",
                      myBlue50,
                    ),
                    _buildSummaryCard(
                      "${calculateDailyTotals()['carbs']}g",
                      "Daily\nCarbs",
                      myTeal50,
                    ),
                    _buildSummaryCard(
                      "${calculateDailyTotals()['fats']}g",
                      "Daily\nFats",
                      myPurple50,
                    ),
                  ],
                ),
                
              ],
            ),
          ),
          */


          _buildDaySelector(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
              children: [
                
                // Build meal cards using currentPlan data
                ...(_buildMealCardsForDay(_selectedDayNumber)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMealCardsForDay(int dayNumber) {
    final List<dynamic> mealDays = currentPlan!['mealDays'] ?? [];
    final dayData = mealDays.firstWhere(
      (day) => day['dayName'] == _getDayName(dayNumber),
      orElse: () => {'meals': []},
    );

    final List<dynamic> meals = dayData['meals'] ?? [];
    
    if (meals.isEmpty) {
      return _buildNoMealsWidget(dayNumber);
    }
    
    return meals.map<Widget>((meal) {
      final mealId = '${_getDayName(dayNumber)}_${meal['name']}_${meal['mealType']}';
      
      return CustomMealCard(
        meal: meal,
        weightUnit: Provider.of<UserProvider>(context, listen: false).userData?['weightUnit'] ?? 'kg',
        isExpanded: _expandedMealIds.contains(mealId),
        onToggleExpand: () {
          setState(() {
            if (_expandedMealIds.contains(mealId)) {
              _expandedMealIds.remove(mealId);
            } else {
              _expandedMealIds.add(mealId);
            }
          });
        },
      );
    }).toList();
  }

  String _getDayName(int dayNumber) {
    switch (dayNumber) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Monday';
    }
  }

  Widget _buildSummaryCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      width: 70,
      decoration: BoxDecoration(
        color: myGrey80,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: myGrey30,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget _buildDaySelector() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<dynamic> mealDays = currentPlan!['mealDays'] ?? [];
    final myIsWebOrDektop = isWebOrDesktopCached;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: myIsWebOrDektop ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          bool isSelected = (index + 1) == _selectedDayNumber;
          final dayData = mealDays.firstWhere(
            (day) => day['dayName'] == _getDayName(index + 1),
            orElse: () => {'meals': []},
          );
          final hasMeals = (dayData['meals'] as List?)?.isNotEmpty ?? false;
          
          return Padding(
            padding: myIsWebOrDektop ? const EdgeInsets.symmetric(horizontal: 4.0) : const EdgeInsets.all(0.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDayNumber = index + 1;
                });
              },
              child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? myBlue30 : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      width: 45,
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? myBlue60 : theme.brightness == Brightness.light ? Colors.white : myGrey90,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? myBlue60 : theme.brightness == Brightness.light ? myGrey20 : myGrey80, width: 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            days[index],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: isSelected ? Colors.white : theme.brightness == Brightness.light ? Colors.black : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasMeals ? (isSelected ? myBlue40 : theme.brightness == Brightness.light ? myGrey20 : myGrey80) : Colors.transparent,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.restaurant_menu,
                                size: 14,
                                color: isSelected ? Colors.white : theme.brightness == Brightness.light ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              
              
              
            ),
          );
        }),
      ),
    );
  }
  


  Map<String, num> calculateDailyTotals() {
    final List<dynamic> mealDays = currentPlan!['mealDays'] ?? [];
    final dayData = mealDays.firstWhere(
      (day) => day['dayName'] == _getDayName(_selectedDayNumber),
      orElse: () => {'meals': []},
    );

    final List<dynamic> meals = dayData['meals'] ?? [];
    
    num totalCalories = 0;
    num totalProtein = 0;
    num totalCarbs = 0;
    num totalFats = 0;

    for (var meal in meals) {
      totalCalories += (meal['calories'] ?? 0).toInt();
      totalProtein += (meal['protein'] ?? 0).toInt();
      totalCarbs += (meal['carbs'] ?? 0).toInt();
      totalFats += (meal['fats'] ?? 0).toInt();
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fats': totalFats,
    };
  }

  List<Widget> _buildNoMealsWidget(int dayNumber) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return [
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu_outlined,
              size: 48,
              color: theme.brightness == Brightness.light ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.no_meals_for_day(_getDayName(dayNumber)),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: theme.brightness == Brightness.light ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    ];
  }
}