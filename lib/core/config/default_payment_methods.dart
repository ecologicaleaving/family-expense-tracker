/// Default Payment Methods Configuration
///
/// Defines the predefined payment methods available to all users.
/// These methods are seeded in the database during migration 052.
class DefaultPaymentMethods {
  /// List of default payment method names
  static const List<String> names = [
    'Contanti',
    'Carta di Credito',
    'Bonifico',
    'Satispay',
  ];

  /// Default payment method for new expenses
  static const String defaultMethod = 'Contanti';

  /// Private constructor to prevent instantiation
  DefaultPaymentMethods._();
}
