import 'package:flutter/material.dart';

class ExerciseSet {
  final TextEditingController repsController;
  final TextEditingController weightController;
  final TextEditingController restController;

  ExerciseSet({
    String? reps = '12',
    String? weight = '20',
    String? rest = '60s',
  })  : repsController = TextEditingController(text: reps),
        weightController = TextEditingController(text: weight),
        restController = TextEditingController(text: rest);

  void dispose() {
    repsController.dispose();
    weightController.dispose();
    restController.dispose();
  }

  Map<String, dynamic> toMap() {
    return {
      'reps': repsController.text,
      'weight': weightController.text,
      'rest': restController.text,
    };
  }
} 