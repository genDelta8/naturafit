import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/widgets/popup_video_player.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Exercise {
  final String name;
  final String sets;
  final String reps;
  final String? notes;
  final String? weight;
  final String? videoUrl;
  final List<String>? imageUrls;

  Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    this.notes,
    this.weight,
    this.videoUrl,
    this.imageUrls,
  });
}

class ExerciseCard extends StatefulWidget {
  final Exercise exercise;

  const ExerciseCard({super.key, required this.exercise});

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

// Copy the entire _ExerciseCardState class here
// ... (copy everything from the _ExerciseCardState class including _buildDetailItem) 


class _ExerciseCardState extends State<ExerciseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showNotes = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildExerciseDetail(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: myGrey20,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: myGrey60,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    Future<File> urlToFile(String imageUrl) async {
      final response = await http.get(Uri.parse(imageUrl));
      final documentDirectory = await getApplicationDocumentsDirectory();
      final file = File('${documentDirectory.path}/${DateTime.now().millisecondsSinceEpoch}.mp4');
      file.writeAsBytesSync(response.bodyBytes);
      return file;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
            if (_isExpanded) {
              _controller.forward();
            } else {
              _controller.reverse();
            }
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: myBlue20,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: myBlue60,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exercise.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildExerciseDetail('${widget.exercise.sets} sets'),
                            const SizedBox(width: 8),
                            _buildExerciseDetail('${widget.exercise.reps} reps'),
                            if (widget.exercise.weight != null && widget.exercise.weight!.trim().isNotEmpty) ...[
                              const SizedBox(width: 8),
                              _buildExerciseDetail(widget.exercise.weight!),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      if (widget.exercise.videoUrl != null)
                        IconButton(
                          icon: const Icon(Icons.videocam_outlined),
                          color: const Color.fromARGB(255, 0, 102, 255),
                          onPressed: () {
                            if (widget.exercise.videoUrl != null) {
                              PopupVideoPlayer.show(
                                context,
                                futureVideoFile: urlToFile(widget.exercise.videoUrl!),
                              );
                            }
                          },
                        ),
                      if (widget.exercise.notes != null)
                        IconButton(
                          icon: Icon(_showNotes
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down),
                          color: const Color.fromARGB(255, 0, 102, 255),
                          onPressed: () {
                            setState(() {
                              _showNotes = !_showNotes;
                            });
                            if (_showNotes) {
                              _controller.forward();
                            } else {
                              _controller.reverse();
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ),
              
              SizeTransition(
                sizeFactor: _animation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: myGrey20),
                    const SizedBox(height: 16),
                    
                    if (widget.exercise.imageUrls != null && 
                        widget.exercise.imageUrls!.isNotEmpty) ...[
                      FadeTransition(
                        opacity: _animation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.reference_images,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: widget.exercise.imageUrls!.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: NetworkImage(widget.exercise.imageUrls![index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    FadeTransition(
                      opacity: _animation,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.exercise.sets.trim().isNotEmpty)
                                  _buildDetailItem(
                                    'Sets',
                                    widget.exercise.sets,
                                    Icons.repeat,
                                  ),
                                if (widget.exercise.reps.trim().isNotEmpty) ...[
                                  if (widget.exercise.sets.trim().isNotEmpty)
                                    const SizedBox(height: 8),
                                  _buildDetailItem(
                                    'Reps',
                                    widget.exercise.reps,
                                    Icons.fitness_center,
                                  ),
                                ],
                                if (widget.exercise.weight != null && widget.exercise.weight!.trim().isNotEmpty) ...[
                                  if (widget.exercise.sets.trim().isNotEmpty || widget.exercise.reps.trim().isNotEmpty)
                                    const SizedBox(height: 8),
                                  _buildDetailItem(
                                    'Weight',
                                    widget.exercise.weight!,
                                    Icons.monitor_weight_outlined,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (widget.exercise.notes != null) ...[
                      const SizedBox(height: 16),
                      FadeTransition(
                        opacity: _animation,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: myGrey10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: myGrey60,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.exercise.notes!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: myGrey60,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildDetailItem(String label, String value, IconData icon) {
    final l10n = AppLocalizations.of(context)!;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: myBlue20,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: myBlue60,
          ),
        ),
        const SizedBox(width: 8),
        Column(
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
        ),
      ],
    );
  }
}

