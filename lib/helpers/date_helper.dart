// todo:✅ Clean Code checked
import 'package:intl/intl.dart';

class DateHelper {
  static String formatDate(String? date) {
    if (date == null || date.isEmpty) return '-';
    try {
      final dt = DateTime.parse(date);
      return DateFormat('d MMM yyyy').format(dt);
    } catch (e) {
      return date;
    }
  }
}
