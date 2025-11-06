import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wms_bctech/controllers/auth/auth_controller.dart';
import 'package:wms_bctech/controllers/delivery_order/delivery_order_controller.dart';
import 'package:wms_bctech/controllers/delivery_order/delivery_order_sequence_controller.dart';
import 'package:wms_bctech/controllers/good_receipt/good_receipt_sequence_controller.dart';
import 'package:wms_bctech/controllers/good_receipt/good_receipt_controller.dart';
import 'package:wms_bctech/controllers/in/in_controller.dart';
import 'package:wms_bctech/controllers/out/out_controller.dart';
import 'package:wms_bctech/controllers/role_controller.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:wms_bctech/controllers/stock_take/stock_take_controller.dart';
import 'package:wms_bctech/helpers/config_helper.dart';
import 'package:wms_bctech/helpers/network_helper.dart';
import 'package:wms_bctech/pages/splash_screen_page.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    await Firebase.initializeApp();
    Logger().i('Firebase initialized successfully');
  } catch (e) {
    Logger().e('Firebase initialization error: $e');
  }

  final networkListener = NetworkHelper();
  networkListener.startListening();

  Get.put(GlobalVM());
  Get.put(Rolevm());
  Get.put(NewAuthController());
  Get.put(InVM());
  Get.put(OutController());
  Get.put(GoodReceiptController());
  Get.put(GoodReceiptSequenceController());
  Get.put(DeliveryOrderController());
  Get.put(DeliveryOrderSequenceController());
  Get.put(StockTakeController());

  final authController = Get.find<NewAuthController>();
  await authController.generateAuthCollectionIfNotExists();

  runApp(const MyApp());
  ConfigHelper.configLoading();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'WMS Bina Cipta Teknologi',
      debugShowCheckedModeBanner: false,
      home: const SplashScreenPage(),
      builder: EasyLoading.init(),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        fontFamily: 'MonaSans',
      ),
    );
  }
}
