import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Palette taken from the reference.
abstract final class AppColors {
  static const Color green = Color(0xFF538A60);
  static const Color cream = Color(0xFFE9E0A6);
  static const Color creamBody = Color(0xD9E9E0A6); // cream @ 85%
  static const Color white = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF000000);
  static const Color translucent = Color(0x2EFFFFFF); // white @ 18%
  static const Color inactiveGrey = Color(0xFFA9B3AD);
  static const Color inactiveBadge = Color(0xFFA8C2AE);
  static const Color iconOutline = Color(0x73E9E0A6); // cream @ 45%
  static const Color plantShadow = Color(0x660E2A17); // deep green-black @ 40%
  static const Color plantShadowOnWhite = Color(0x2E0E2A17); // @ 18%
}

/// Corner radii at the 390pt design baseline (multiply by scale).
abstract final class AppRadii {
  static const double phone = 40;
  static const double header = 56;
  static const double card = 28;
  static const double addButton = 18;
  static const double chip = 12;
  static const double rail = 28;
}

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 250);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
}

/// Gesture spring from the brief: mass 1, stiffness 180, damping 18.
const SpringDescription kSpring =
    SpringDescription(mass: 1, stiffness: 180, damping: 18);

/// A [Curve] backed by [kSpring], for `animateTo` style APIs.
class SpringCurve extends Curve {
  const SpringCurve({this.seconds = 0.6});

  /// How many seconds of the simulation the curve spans.
  final double seconds;

  @override
  double transformInternal(double t) =>
      SpringSimulation(kSpring, 0, 1, 0).x(t * seconds);
}

abstract final class AppText {
  /// Inter, bundled under assets/fonts (SIL OFL 1.1), so the app renders
  /// identically offline and in tests.
  static const String family = 'Inter';

  static TextStyle heroTitle(double s) => TextStyle(
        fontFamily: AppText.family,
        fontSize: 62 * s,
        fontWeight: FontWeight.w800,
        height: 0.95,
        letterSpacing: -1.2 * s,
        color: AppColors.cream,
      );

  static TextStyle miniTitle(double s) => TextStyle(
        fontFamily: AppText.family,
        fontSize: 18 * s,
        fontWeight: FontWeight.w700,
        color: AppColors.cream,
      );

  static TextStyle wordmark(double s) => TextStyle(
        fontFamily: AppText.family,
        fontSize: 20 * s,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: AppColors.white,
      );

  static TextStyle cardTitle(double s) => TextStyle(
        fontFamily: AppText.family,
        fontSize: 18 * s,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AppColors.cream,
      );

  static TextStyle tab(double s) => TextStyle(
        fontFamily: AppText.family,
        fontSize: 22 * s,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  static TextStyle badge(double s) => TextStyle(
        fontFamily: AppText.family,
        fontSize: 10.5 * s,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      );

  static TextStyle bagBadge(double s) => TextStyle(
        fontFamily: AppText.family,
        fontSize: 10 * s,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      );

  static TextStyle body(double s) => TextStyle(
        fontFamily: AppText.family,
        fontSize: 15 * s,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.creamBody,
      );

  static TextStyle detailTitle(double s) => TextStyle(
        fontFamily: AppText.family,
        fontSize: 30 * s,
        fontWeight: FontWeight.w800,
        height: 1.08,
        color: AppColors.cream,
      );

  static TextStyle back(double s) => TextStyle(
        fontFamily: AppText.family,
        fontSize: 17 * s,
        fontWeight: FontWeight.w500,
        color: AppColors.cream,
      );

  static TextStyle sheetLabel(double s) => TextStyle(
        fontFamily: AppText.family,
        fontSize: 13 * s,
        fontWeight: FontWeight.w500,
        color: AppColors.creamBody,
      );
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: false,
    fontFamily: AppText.family,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.white,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    colorScheme: const ColorScheme.light(
      primary: AppColors.green,
      secondary: AppColors.cream,
    ),
  );
  return base.copyWith(
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      actionTextColor: AppColors.cream,
      contentTextStyle: const TextStyle(
        fontFamily: AppText.family,
        color: AppColors.white,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
