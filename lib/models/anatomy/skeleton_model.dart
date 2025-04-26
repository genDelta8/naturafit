class AnatomyModel {
  final String modelPath;
  final List<String> animations;
  final Map<String, List<String>> muscleGroups;
  
  AnatomyModel({
    required this.modelPath,
    required this.animations,
    required this.muscleGroups,
  });
  
  static Map<String, List<String>> get squatMuscles => {
    'primary': ['quadriceps', 'gluteus_maximus', 'hamstrings'],
    'secondary': ['core', 'lower_back', 'calves'],
    'stabilizers': ['adductors', 'abductors'],
  };
} 