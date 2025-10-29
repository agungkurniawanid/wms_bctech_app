import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityController extends GetxController {
  final Connectivity _connectivity = Connectivity();
  final RxBool isConnected = false.obs;

  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    final connected =
        result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi);
    isConnected.value = connected;
    return connected;
  }

  void listenConnectionChanges() {
    _connectivity.onConnectivityChanged.listen((result) {
      isConnected.value =
          result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi);
    });
  }
}
