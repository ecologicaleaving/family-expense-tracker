import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Distinctive color palette - "Italian Brutalism"
/// Warm terracotta meets aged parchment with oxidized copper accents
class AppColors {
  AppColors._();

  // Primary palette
  static const terracotta = Color(0xFFC75B39);
  static const terracottaLight = Color(0xFFE8A089);
  static const terracottaDark = Color(0xFF8B3D25);

  // Background & Surface
  static const parchment = Color(0xFFF5EDE0);
  static const parchmentDark = Color(0xFFE8DED0);
  static const cream = Color(0xFFFAF7F2);

  // Accent - oxidized copper/teal
  static const copper = Color(0xFF2D7D7D);
  static const copperLight = Color(0xFF4AA3A3);

  // Ink colors
  static const ink = Color(0xFF1A1A1A);
  static const inkLight = Color(0xFF4A4A4A);
  static const inkFaded = Color(0xFF8A8A8A);

  // Highlight for amounts
  static const gold = Color(0xFFD4A84B);
  static const goldLight = Color(0xFFE8C878);

  // Semantic colors
  static const success = Color(0xFF4A7C59);
  static const warning = Color(0xFFD4A84B);
  static const error = Color(0xFFC75B39);

  // Category colors - warm, earthy palette
  static const categoryGrocery = Color(0xFF7B9E6E);
  static const categoryHome = Color(0xFFB8860B);
  static const categoryTransport = Color(0xFF6B8E9F);
  static const categoryBills = Color(0xFFC75B39);
  static const categoryRestaurant = Color(0xFFD4A84B);
  static const categoryHealth = Color(0xFF9B6B8E);
  static const categoryEntertainment = Color(0xFF7B6B9E);
  static const categoryClothing = Color(0xFF9E8B6B);

  // Dark theme
  static const darkSurface = Color(0xFF1A1815);
  static const darkCard = Color(0xFF2A2520);
  static const darkCardElevated = Color(0xFF3A352F);
}

/// Custom text theme with distinctive typography using Google Fonts
class AppTypography {
  AppTypography._();

  static TextTheme get lightTextTheme => TextTheme(
    // Display styles - elegant serif (Playfair Display)
    displayLarge: GoogleFonts.playfairDisplay(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      color: AppColors.ink,
    ),
    displayMedium: GoogleFonts.playfairDisplay(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      color: AppColors.ink,
    ),
    displaySmall: GoogleFonts.playfairDisplay(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      color: AppColors.ink,
    ),

    // Headlines
    headlineLarge: GoogleFonts.playfairDisplay(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    ),
    headlineMedium: GoogleFonts.playfairDisplay(
      fontSize: 28,
      fontWeight: FontWeight.w500,
      color: AppColors.ink,
    ),
    headlineSmall: GoogleFonts.playfairDisplay(
      fontSize: 24,
      fontWeight: FontWeight.w500,
      color: AppColors.ink,
    ),

    // Titles - geometric sans (DM Sans)
    titleLarge: GoogleFonts.dmSans(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      color: AppColors.ink,
    ),
    titleMedium: GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      color: AppColors.ink,
    ),
    titleSmall: GoogleFonts.dmSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: AppColors.ink,
    ),

    // Body text
    bodyLarge: GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      color: AppColors.ink,
    ),
    bodyMedium: GoogleFonts.dmSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: AppColors.ink,
    ),
    bodySmall: GoogleFonts.dmSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: AppColors.inkLight,
    ),

    // Labels
    labelLarge: GoogleFonts.dmSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: AppColors.ink,
    ),
    labelMedium: GoogleFonts.dmSans(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: AppColors.inkLight,
    ),
    labelSmall: GoogleFonts.dmSans(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: AppColors.inkFaded,
    ),
  );

  static TextTheme get darkTextTheme => TextTheme(
    displayLarge: lightTextTheme.displayLarge?.copyWith(color: AppColors.cream),
    displayMedium: lightTextTheme.displayMedium?.copyWith(color: AppColors.cream),
    displaySmall: lightTextTheme.displaySmall?.copyWith(color: AppColors.cream),
    headlineLarge: lightTextTheme.headlineLarge?.copyWith(color: AppColors.cream),
    headlineMedium: lightTextTheme.headlineMedium?.copyWith(color: AppColors.cream),
    headlineSmall: lightTextTheme.headlineSmall?.copyWith(color: AppColors.cream),
    titleLarge: lightTextTheme.titleLarge?.copyWith(color: AppColors.cream),
    titleMedium: lightTextTheme.titleMedium?.copyWith(color: AppColors.cream),
    titleSmall: lightTextTheme.titleSmall?.copyWith(color: AppColors.cream),
    bodyLarge: lightTextTheme.bodyLarge?.copyWith(color: AppColors.parchment),
    bodyMedium: lightTextTheme.bodyMedium?.copyWith(color: AppColors.parchment),
    bodySmall: lightTextTheme.bodySmall?.copyWith(color: AppColors.parchmentDark),
    labelLarge: lightTextTheme.labelLarge?.copyWith(color: AppColors.cream),
    labelMedium: lightTextTheme.labelMedium?.copyWith(color: AppColors.parchment),
    labelSmall: lightTextTheme.labelSmall?.copyWith(color: AppColors.parchmentDark),
  );

  /// Monospace style for amounts/numbers (JetBrains Mono)
  static TextStyle get amountStyle => GoogleFonts.jetBrainsMono(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static TextStyle get amountLarge => GoogleFonts.jetBrainsMono(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static TextStyle get amountSmall => GoogleFonts.jetBrainsMono(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
}

/// Budget Design Tokens - "Italian Brutalism" for Budget Dashboard
class BudgetDesignTokens {
  BudgetDesignTokens._();

  // Spacing constants
  static const double heroHeight = 180.0;
  static const double cardBorderWidth = 4.0;
  static const double badgeSize = 32.0;
  static const double progressBarHeight = 12.0;
  static const double alertBorderWidth = 6.0;
  static const double sectionDividerThickness = 2.0;
  static const double barChartBarHeight = 24.0;
  static const double quickStatsHeight = 80.0;

  // Status colors (for left border on cards)
  static const Color healthyBorder = AppColors.copper;
  static const Color warningBorder = AppColors.gold;
  static const Color dangerBorder = AppColors.terracotta;

  // Badge colors
  static const Color groupBadgeBg = AppColors.terracotta;
  static const Color personalBadgeBg = AppColors.copper;
  static const Color badgeFg = AppColors.cream;

  // Typography - Hero section
  static TextStyle get amountHero => GoogleFonts.jetBrainsMono(
    fontSize: 42,
    fontWeight: FontWeight.w700,
    color: AppColors.cream,
    letterSpacing: -0.5,
  );

  static TextStyle get labelHero => GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: AppColors.cream.withValues(alpha: 0.9),
  );

  // Typography - Section labels
  static TextStyle get sectionLabel => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.0,
    color: AppColors.inkLight,
  );

  // Typography - Card amounts
  static TextStyle get cardAmount => GoogleFonts.jetBrainsMono(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  // Typography - Category names
  static TextStyle get categoryName => GoogleFonts.playfairDisplay(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );

  // Typography - Percentage display
  static TextStyle get percentageText => GoogleFonts.jetBrainsMono(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  // Shadows - Sharp brutalist shadow
  static const BoxShadow sharpShadow = BoxShadow(
    color: Color(0x40000000),
    offset: Offset(0, 2),
    blurRadius: 0,
    spreadRadius: 0,
  );

  // Border radius
  static const double cardRadius = 4.0;
  static const double progressBarRadius = 2.0;
  static const double badgeRadius = 16.0; // circle

  // Animation durations
  static const Duration snapDuration = Duration(milliseconds: 150);
  static const Duration expandDuration = Duration(milliseconds: 200);
}

/// Main theme configuration
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Color scheme
    colorScheme: ColorScheme.light(
      primary: AppColors.terracotta,
      onPrimary: AppColors.cream,
      primaryContainer: AppColors.terracottaLight.withValues(alpha: 0.3),
      onPrimaryContainer: AppColors.terracottaDark,
      secondary: AppColors.copper,
      onSecondary: AppColors.cream,
      secondaryContainer: AppColors.copperLight.withValues(alpha: 0.2),
      onSecondaryContainer: AppColors.copper,
      tertiary: AppColors.gold,
      onTertiary: AppColors.ink,
      tertiaryContainer: AppColors.goldLight.withValues(alpha: 0.3),
      onTertiaryContainer: AppColors.ink,
      surface: AppColors.cream,
      onSurface: AppColors.ink,
      surfaceContainerHighest: AppColors.parchment,
      outline: AppColors.inkFaded.withValues(alpha: 0.3),
      outlineVariant: AppColors.inkFaded.withValues(alpha: 0.15),
      error: AppColors.error,
    ),

    // Typography
    textTheme: AppTypography.lightTextTheme,

    // Scaffold
    scaffoldBackgroundColor: AppColors.parchment,

    // AppBar - clean, minimal
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.parchment,
      foregroundColor: AppColors.ink,
      centerTitle: false,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.ink,
        size: 24,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),

    // Cards - sharp edges, dramatic shadows
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4), // Sharp, almost brutalist
      ),
      color: AppColors.cream,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      clipBehavior: Clip.antiAlias,
    ),

    // Navigation bar - bold geometric
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 72,
      backgroundColor: AppColors.cream,
      indicatorColor: AppColors.terracotta,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.cream, size: 24);
        }
        return const IconThemeData(color: AppColors.inkLight, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.terracotta,
            letterSpacing: 0.5,
          );
        }
        return GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.inkFaded,
          letterSpacing: 0.5,
        );
      }),
    ),

    // FAB - geometric, sharp
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.terracotta,
      foregroundColor: AppColors.cream,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    ),

    // Chips - sharp, bold
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.cream,
      selectedColor: AppColors.terracotta,
      labelStyle: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: AppColors.inkFaded.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // Progress indicators
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.terracotta,
      linearTrackColor: AppColors.parchmentDark,
      linearMinHeight: 6,
    ),

    // Elevated buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.terracotta,
        foregroundColor: AppColors.cream,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    ),

    // Outlined buttons
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.terracotta,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: const BorderSide(color: AppColors.terracotta, width: 2),
        textStyle: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    ),

    // Text buttons
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.terracotta,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cream,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: AppColors.inkFaded.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: AppColors.inkFaded.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.terracotta, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      labelStyle: GoogleFonts.dmSans(
        color: AppColors.inkLight,
      ),
      hintStyle: GoogleFonts.dmSans(
        color: AppColors.inkFaded,
      ),
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: GoogleFonts.dmSans(
        color: AppColors.cream,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color: AppColors.inkFaded.withValues(alpha: 0.15),
      thickness: 1,
      space: 1,
    ),

    // List tile
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      minVerticalPadding: 12,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: ColorScheme.dark(
      primary: AppColors.terracottaLight,
      onPrimary: AppColors.ink,
      primaryContainer: AppColors.terracotta.withValues(alpha: 0.3),
      onPrimaryContainer: AppColors.terracottaLight,
      secondary: AppColors.copperLight,
      onSecondary: AppColors.ink,
      secondaryContainer: AppColors.copper.withValues(alpha: 0.3),
      onSecondaryContainer: AppColors.copperLight,
      tertiary: AppColors.gold,
      onTertiary: AppColors.ink,
      surface: AppColors.darkSurface,
      onSurface: AppColors.cream,
      surfaceContainerHighest: AppColors.darkCard,
      outline: AppColors.parchmentDark.withValues(alpha: 0.2),
      outlineVariant: AppColors.parchmentDark.withValues(alpha: 0.1),
      error: AppColors.terracottaLight,
    ),

    textTheme: AppTypography.darkTextTheme,
    scaffoldBackgroundColor: AppColors.darkSurface,

    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.cream,
      centerTitle: false,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: AppColors.cream,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.cream,
        size: 24,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      color: AppColors.darkCard,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    ),

    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 72,
      backgroundColor: AppColors.darkSurface,
      indicatorColor: AppColors.terracottaLight,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.ink, size: 24);
        }
        return const IconThemeData(color: AppColors.parchmentDark, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.terracottaLight,
            letterSpacing: 0.5,
          );
        }
        return GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.parchmentDark,
          letterSpacing: 0.5,
        );
      }),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.terracottaLight,
      foregroundColor: AppColors.ink,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkCard,
      selectedColor: AppColors.terracottaLight,
      labelStyle: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.cream,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: AppColors.parchmentDark.withValues(alpha: 0.2)),
      ),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.terracottaLight,
      linearTrackColor: AppColors.darkCardElevated,
      linearMinHeight: 6,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.terracottaLight,
        foregroundColor: AppColors.ink,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: AppColors.parchmentDark.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: AppColors.parchmentDark.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.terracottaLight, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.cream,
      contentTextStyle: GoogleFonts.dmSans(
        color: AppColors.ink,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    dividerTheme: DividerThemeData(
      color: AppColors.parchmentDark.withValues(alpha: 0.1),
      thickness: 1,
    ),

    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      minVerticalPadding: 12,
    ),
  );
}
