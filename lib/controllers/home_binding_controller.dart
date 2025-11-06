import 'package:get/get.dart';
import 'package:wms_bctech/controllers/history_controller.dart';
import 'package:wms_bctech/controllers/pid_controller.dart';
import 'package:wms_bctech/controllers/stock_take_controller.dart';
import 'package:wms_bctech/models/out/out_model.dart';
import 'category_controller.dart';
import 'weborder_controller.dart';
import 'in/in_controller.dart';
import 'stock_check_controlller.dart';
import 'global_controller.dart';
import 'reports_controller.dart';
import 'role_controller.dart';

class HomeBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CategoryVM>(() => CategoryVM(), fenix: true);
    Get.lazyPut<WeborderVM>(() => WeborderVM(), fenix: true);
    Get.lazyPut<OutModel>(() => OutModel(), fenix: true);
    Get.lazyPut<InVM>(() => InVM(), fenix: true);
    Get.lazyPut<StockCheckVM>(() => StockCheckVM(), fenix: true);
    Get.lazyPut<HistoryViewModel>(() => HistoryViewModel(), fenix: true);
    Get.lazyPut<ReportsVM>(() => ReportsVM(), fenix: true);
    Get.lazyPut<GlobalVM>(() => GlobalVM(), fenix: true);
    Get.lazyPut<PidViewModel>(() => PidViewModel(), fenix: true);
    Get.lazyPut<StockTakeController>(() => StockTakeController(), fenix: true);
    Get.lazyPut<Rolevm>(() => Rolevm(), fenix: true);
  }
}
