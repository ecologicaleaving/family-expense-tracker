import 'dart:math';

import '../config/constants.dart';

/// Generator for invite codes.
///
/// Generates 6-character alphanumeric codes excluding confusable characters
/// (0/O/1/I/L) to avoid user confusion when sharing codes.
class InviteCodeGenerator {
  InviteCodeGenerator._();

  /// Characters allowed in invite codes.
  /// Excludes 0, O, 1, I, L to avoid confusion.
  static const String _allowedCharacters = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  static final Random _random = Random.secure();

  /// Generate a random invite code.
  ///
  /// Returns a 6-character string using only unambiguous alphanumeric characters.
  static String generate() {
    final buffer = StringBuffer();
    for (int i = 0; i < ValidationRules.inviteCodeLength; i++) {
      final index = _random.nextInt(_allowedCharacters.length);
      buffer.write(_allowedCharacters[index]);
    }
    return buffer.toString();
  }

  /// Validate an invite code format.
  ///
  /// Returns true if the code matches the expected format.
  static bool isValidFormat(String code) {
    if (code.length != ValidationRules.inviteCodeLength) {
      return false;
    }

    final normalizedCode = code.toUpperCase();
    for (int i = 0; i < normalizedCode.length; i++) {
      if (!_allowedCharacters.contains(normalizedCode[i])) {
        return false;
      }
    }

    return true;
  }

  /// Normalize an invite code for comparison.
  ///
  /// Converts to uppercase and validates format.
  /// Returns null if the code is invalid.
  static String? normalize(String code) {
    final normalized = code.toUpperCase().trim();
    if (!isValidFormat(normalized)) {
      return null;
    }
    return normalized;
  }

  /// Format a code for display (e.g., "ABC-DEF" with dash in the middle).
  static String formatForDisplay(String code) {
    if (code.length != ValidationRules.inviteCodeLength) {
      return code;
    }
    final middle = code.length ~/ 2;
    return '${code.substring(0, middle)}-${code.substring(middle)}';
  }

  /// Remove formatting from a displayed code.
  static String removeFormatting(String displayedCode) {
    return displayedCode.replaceAll('-', '').replaceAll(' ', '').toUpperCase();
  }
}
