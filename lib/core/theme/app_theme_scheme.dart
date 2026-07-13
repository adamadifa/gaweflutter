import 'package:flutter/material.dart';

class AppThemeScheme {
  static const Color greenPrimary = Color(0xFF32745e);
  static const Color greenLight = Color(0xFF58907D);
  static const Color greenBg = Color(0xFFF0FDF9);

  static const Color bluePrimary = Color(0xFF0D47A1);
  static const Color blueLight = Color(0xFF1976D2);
  static const Color blueBg = Color(0xFFEFF6FF);

  static const Color redPrimary = Color(0xFFB71C1C);
  static const Color redLight = Color(0xFFD32F2F);
  static const Color redBg = Color(0xFFFEF2F2);

  static const Color purplePrimary = Color(0xFF4A148C);
  static const Color purpleLight = Color(0xFF7B1FA2);
  static const Color purpleBg = Color(0xFFFAF5FF);

  static const Color orangePrimary = Color(0xFFE65100);
  static const Color orangeLight = Color(0xFFF57C00);
  static const Color orangeBg = Color(0xFFFFF8F1);

  static const Color rosePrimary = Color(0xFFCE8291);
  static const Color roseLight = Color(0xFFEF95A6);
  static const Color roseBg = Color(0xFFFFF5F7);

  static Color getPrimary(String? scheme) {
    switch (scheme?.toLowerCase()) {
      case 'blue': return bluePrimary;
      case 'red': return redPrimary;
      case 'purple': return purplePrimary;
      case 'orange': return orangePrimary;
      case 'rose': return rosePrimary;
      default: return greenPrimary;
    }
  }

  static Color getLight(String? scheme) {
    switch (scheme?.toLowerCase()) {
      case 'blue': return blueLight;
      case 'red': return redLight;
      case 'purple': return purpleLight;
      case 'orange': return orangeLight;
      case 'rose': return roseLight;
      default: return greenLight;
    }
  }

  static Color getBg(String? scheme) {
    switch (scheme?.toLowerCase()) {
      case 'blue': return blueBg;
      case 'red': return redBg;
      case 'purple': return purpleBg;
      case 'orange': return orangeBg;
      case 'rose': return roseBg;
      default: return greenBg;
    }
  }
}
