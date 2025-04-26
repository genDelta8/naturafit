import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/views/client_side/client_workout/completed_workout_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class WorkoutHistoryPage extends StatefulWidget {
  final bool isEnteredByTrainer;
  final Map<String, dynamic>? passedClientForTrainer;

  const WorkoutHistoryPage({
    super.key,
    this.isEnteredByTrainer = false,
    this.passedClientForTrainer,
  });

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  late final Stream<QuerySnapshot> _workoutHistoryStream;

  @override
  void initState() {
    super.initState();
    final clientId = widget.passedClientForTrainer?['clientId'];
    final userId = widget.isEnteredByTrainer && clientId != null
        ? clientId
        : context.read<UserProvider>().userData?['userId'];

    _workoutHistoryStream = FirebaseFirestore.instance
        .collection('workout_history')
        .doc('clients')
        .collection(userId ?? '')
        .orderBy('completedAt', descending: true)
        .snapshots();
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Workout History',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.chevron_left,
              color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _workoutHistoryStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: myBlue60));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center_outlined,
                    size: 64,
                    color: theme.brightness == Brightness.light ? myGrey40 : myGrey60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No workout history found',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final workout = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final completedAt = (workout['completedAt'] as Timestamp).toDate();
              
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CompletedWorkoutDetailPage(
                        workoutData: workout,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MMM d, yyyy').format(completedAt),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: theme.brightness == Brightness.light ? myGrey60 : Colors.grey[400],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: myBlue60.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                workout['finishDifficulty'] ?? 'Level 3',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: myBlue60,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          workout['planName'] ?? 'Unnamed Workout',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: theme.brightness == Brightness.light ? myGrey60 : Colors.grey[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(workout['totalDuration'] ?? 0),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: theme.brightness == Brightness.light ? myGrey60 : Colors.grey[400],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: theme.brightness == Brightness.light ? myGrey60 : Colors.grey[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Day ${workout['dayNumber'] + 1}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: theme.brightness == Brightness.light ? myGrey60 : Colors.grey[400],
                              ),
                            ),
                          ],
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
    );
  }
} 