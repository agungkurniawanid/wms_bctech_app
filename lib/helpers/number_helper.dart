import 'package:intl/intl.dart';

class NumberHelper {
  static String formatNumber(double? number) {
    if (number == null) return '0';
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(number);
  }

  static String formatIDR(double? number) {
    if (number == null) return 'Rp 0';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(number);
  }
}
