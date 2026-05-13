import 'package:intl/intl.dart';

class MoneyFormatter {
  static final NumberFormat _wholeNumberFormat = NumberFormat.decimalPattern();

  static String format(double amount, String currency) {
    final rounded = amount.round();
    return '${_wholeNumberFormat.format(rounded)} $currency';
  }
}
