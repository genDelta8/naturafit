class FeedbackModel {
  final String userId;
  final List<String> areas;
  final String message;
  final DateTime timestamp;

  FeedbackModel({
    required this.userId,
    required this.areas,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'areas': areas,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
} 