import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:wms_bctech/models/role_model.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:logger/logger.dart';

class Rolevm extends GetxController {
  final GlobalVM globalvm = Get.find();

  final RxBool isLoading = true.obs;
  final Rx<Role> role = Role.empty().obs;

  Stream<Role> listrole() {
    try {
      return FirebaseFirestore.instance
          .collection('role')
          .doc(globalvm.username.value)
          .snapshots()
          .asyncMap((DocumentSnapshot docSnapshot) async {
            if (!docSnapshot.exists) {
              isLoading.value = false;
              return Role.empty();
            }

            final Role returnstock = Role.fromDocumentSnapshot(docSnapshot);
            role.value = returnstock;
            isLoading.value = false;
            return returnstock;
          });
    } catch (e) {
      Logger().e("Error in listrole: $e");
      isLoading.value = false;
      return Stream.value(Role.empty());
    }
  }
}
