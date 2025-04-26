import 'package:naturafit/models/achievements/client_achievements.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ClientAchievementsPage extends StatelessWidget {
  const ClientAchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final unlockedAchievements = userProvider.unlockedAchievements ?? [];
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: myGrey10,
      appBar: AppBar(
        title: Text(
          l10n.achievements,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: myGrey10,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.chevron_left, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressSection(unlockedAchievements),
              const SizedBox(height: 24),
              ...AchievementDifficulty.values.map((difficulty) {
                return _buildDifficultySection(
                  context,
                  difficulty,
                  unlockedAchievements,
                );
              }).toList(),
              const SizedBox(height: 24),
              _buildAchievementItem(
                icon: Icons.fitness_center,
                title: l10n.strength_milestone,
                subtitle: 'Bench Press 80kg',
                date: 'Nov 28, 2024',
              ),
              _buildAchievementItem(
                icon: Icons.timer,
                title: l10n.consistency,
                subtitle: l10n.workouts_completed(20),
                date: 'Nov 15, 2024',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(List<String> unlockedAchievements) {
    final totalAchievements = ClientAchievements.getAllAchievements().length;
    final progress = unlockedAchievements.length / totalAchievements;
    

    return Container(
      decoration: BoxDecoration(
        color: myBlue30,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Card(
        elevation: 1,
        color: myBlue60,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${unlockedAchievements.length}/$totalAchievements',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: myBlue40.withOpacity(0.6),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultySection(
    BuildContext context,
    AchievementDifficulty difficulty,
    List<String> unlockedAchievements,
  ) {
    final achievements = ClientAchievements.getAllAchievements()
        .where((a) => a.difficulty == difficulty)
        .toList();

    Color difficultyColor;
    String difficultyText;
    switch (difficulty) {
      case AchievementDifficulty.easy:
        difficultyColor = myGreen50;
        difficultyText = 'Easy';
        break;
      case AchievementDifficulty.medium:
        difficultyColor = myYellow50;
        difficultyText = 'Medium';
        break;
      case AchievementDifficulty.hard:
        difficultyColor = myRed50;
        difficultyText = 'Hard';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: difficultyColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              difficultyText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...achievements.map((achievement) {
          final isUnlocked = unlockedAchievements.contains(achievement.id);
          return _buildAchievementCard(achievement, isUnlocked, difficultyColor);
        }).toList(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAchievementCard(
    Achievement achievement,
    bool isUnlocked,
    Color difficultyColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isUnlocked ? Colors.white : Colors.white.withOpacity(0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: difficultyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    achievement.icon,
                    color: difficultyColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isUnlocked ? Colors.black : myGrey60,
                        ),
                      ),
                      Text(
                        achievement.description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: isUnlocked ? myGrey60 : myGrey40,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUnlocked)
                  const Icon(
                    Icons.check_circle,
                    color: myGreen50,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String date,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  date,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 