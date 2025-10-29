import 'package:get/get.dart';
import 'package:wms_bctech/config/config.dart';
import 'package:intl/intl.dart';

class GlobalVM extends GetxController {
  final Config config = Config();
  var choicecategory = "".obs;
  var username = "".obs;
  var version = "".obs;

  String dateToString(String date) {
    final format = DateFormat('dd-MM-yyyy');
    final dateTime = DateTime.parse(date);
    final dateFormat = format.format(dateTime);
    return dateFormat;
  }

  String stringToDateWithTime(String date) {
    final format = DateFormat('dd-MM-yyyy HH:mm:ss');
    final dateTime = DateTime.parse(date);
    final dateFormat = format.format(dateTime);
    return dateFormat;
  }

  String stringToDateWithHour(String date) {
    final format = DateFormat('dd-MM-yyyy / HH:mm');
    final dateTime = DateTime.parse(date);
    final dateFormat = format.format(dateTime);
    return dateFormat;
  }
}
