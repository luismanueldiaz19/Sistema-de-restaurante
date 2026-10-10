import 'package:intl/intl.dart';

class FormatterNumber {
  static String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: 'RD\$ ',
    ).format(amount);
  }

  static String formatMoneda(double amount) {
    return NumberFormat.simpleCurrency(
      locale: 'en_US',
      name: 'RD\$ ',
    ).format(amount);
  }

  static String formatFechaLatina(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatFechaHora(DateTime date) {
    return DateFormat('dd/MM/yyyy hh:mm a').format(date);
  }

  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
