import 'package:flutter/material.dart';

class EcosystemBackground {
  final Color top;
  final Color bottom;

  const EcosystemBackground({required this.top, required this.bottom});
}

class Ecosystem {
  final String slug;
  final String title;
  final String type; 
  final double lat;
  final double lng;
  final String modelPath;
  final String description;
  final String fact;
  final EcosystemBackground background;
  final double cameraDistance;
  
  final String spritePath;
  final int spriteTotalFrames;
  final int spriteColumns;
  final int spriteRows;

  const Ecosystem({
    required this.slug,
    required this.title,
    required this.type,
    required this.lat,
    required this.lng,
    required this.modelPath,
    required this.description,
    required this.fact,
    required this.background,
    required this.cameraDistance,
    required this.spritePath,
    required this.spriteTotalFrames,
    required this.spriteColumns,
    required this.spriteRows,
  });
}