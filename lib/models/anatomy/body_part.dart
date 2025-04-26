import 'package:flutter/material.dart';

class BodyPart {
  final Path path;
  final double rotation;
  final Offset pivot;
  
  BodyPart({
    required this.path,
    this.rotation = 0.0,
    required this.pivot,
  });
} 