import '../config/constants.dart';

/// Validation utilities for form fields.
class Validators {
  Validators._();

  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Inserisci la tua email';
    }

    // Basic email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Inserisci un indirizzo email valido';
    }

    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Inserisci la password';
    }

    if (value.length < ValidationRules.minPasswordLength) {
      return 'La password deve avere almeno ${ValidationRules.minPasswordLength} caratteri';
    }

    return null;
  }

  /// Validate password confirmation
  static String? validatePasswordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Conferma la password';
    }

    if (value != password) {
      return 'Le password non corrispondono';
    }

    return null;
  }

  /// Validate display name
  static String? validateDisplayName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Inserisci il tuo nome';
    }

    if (value.length < ValidationRules.minDisplayNameLength) {
      return 'Il nome deve avere almeno ${ValidationRules.minDisplayNameLength} caratteri';
    }

    if (value.length > ValidationRules.maxDisplayNameLength) {
      return 'Il nome può avere massimo ${ValidationRules.maxDisplayNameLength} caratteri';
    }

    // Only allow alphanumeric, spaces, and common name characters
    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ0-9 '-]+$");
    if (!nameRegex.hasMatch(value)) {
      return 'Il nome contiene caratteri non validi';
    }

    return null;
  }

  /// Validate group name
  static String? validateGroupName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Inserisci il nome del gruppo';
    }

    if (value.length < ValidationRules.minDisplayNameLength) {
      return 'Il nome deve avere almeno ${ValidationRules.minDisplayNameLength} caratteri';
    }

    if (value.length > ValidationRules.maxGroupNameLength) {
      return 'Il nome può avere massimo ${ValidationRules.maxGroupNameLength} caratteri';
    }

    return null;
  }

  /// Validate expense amount
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Inserisci l\'importo';
    }

    // Replace comma with dot for parsing
    final normalizedValue = value.replaceAll(',', '.');
    final amount = double.tryParse(normalizedValue);

    if (amount == null) {
      return 'Importo non valido';
    }

    if (amount < ValidationRules.minExpenseAmount) {
      return 'L\'importo minimo è €${ValidationRules.minExpenseAmount.toStringAsFixed(2)}';
    }

    if (amount > ValidationRules.maxExpenseAmount) {
      return 'L\'importo massimo è €${ValidationRules.maxExpenseAmount.toStringAsFixed(2)}';
    }

    return null;
  }

  /// Parse amount string to double
  static double? parseAmount(String? value) {
    if (value == null || value.isEmpty) return null;
    final normalizedValue = value.replaceAll(',', '.');
    return double.tryParse(normalizedValue);
  }

  /// Validate expense date (not in future)
  static String? validateExpenseDate(DateTime? value) {
    if (value == null) {
      return 'Seleziona la data';
    }

    if (value.isAfter(DateTime.now())) {
      return 'La data non può essere nel futuro';
    }

    return null;
  }

  /// Validate merchant name (optional but with max length)
  static String? validateMerchant(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    if (value.length > ValidationRules.maxMerchantLength) {
      return 'Il nome del negozio può avere massimo ${ValidationRules.maxMerchantLength} caratteri';
    }

    return null;
  }

  /// Validate notes (optional but with max length)
  static String? validateNotes(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    if (value.length > ValidationRules.maxNotesLength) {
      return 'Le note possono avere massimo ${ValidationRules.maxNotesLength} caratteri';
    }

    return null;
  }

  /// Validate invite code format
  static String? validateInviteCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Inserisci il codice invito';
    }

    if (value.length != ValidationRules.inviteCodeLength) {
      return 'Il codice deve avere ${ValidationRules.inviteCodeLength} caratteri';
    }

    // Only uppercase letters and numbers (excluding confusable chars)
    final codeRegex = RegExp(r'^[A-HJ-NP-Z2-9]+$');
    if (!codeRegex.hasMatch(value.toUpperCase())) {
      return 'Codice non valido';
    }

    return null;
  }

  /// Check if a string is not empty
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? 'Inserisci $fieldName'
          : 'Questo campo è obbligatorio';
    }
    return null;
  }
}
