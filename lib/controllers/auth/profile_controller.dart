import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wms_bctech/controllers/auth/auth_controller.dart';
import 'package:wms_bctech/helpers/text_helper.dart';
import 'package:wms_bctech/models/user/user_model.dart';

class ProfileController extends GetxController {
  final NewAuthController authController = Get.find<NewAuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Rx<NewUserModel?> userData = Rx<NewUserModel?>(null);
  final RxString userName = ''.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      isLoading.value = true;
      await authController.loadUserId();
      final String currentUserId = authController.userId.value;

      if (currentUserId.isEmpty) {
        debugPrint("User ID is empty");
        return;
      }

      await Future.wait([
        _loadRoleData(currentUserId),
        _loadUserData(currentUserId),
      ]);
    } catch (e) {
      debugPrint("Failed to load user data: $e");
      Get.snackbar(
        'Error',
        'Gagal memuat data profil',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadRoleData(String userId) async {
    final DocumentSnapshot roleDocument = await _firestore
        .collection('role')
        .doc(userId)
        .get();

    if (roleDocument.exists) {
      userData.value = NewUserModel.fromMap(
        roleDocument.data() as Map<String, dynamic>,
      );
    }
  }

  Future<void> _loadUserData(String userId) async {
    final DocumentSnapshot userDocument = await _firestore
        .collection('user')
        .doc(userId)
        .get();

    if (userDocument.exists) {
      userName.value = userDocument.get('name') as String? ?? '';
    } else {
      userName.value = userId;
    }
  }

  String get displayName => userName.value.isNotEmpty
      ? TextHelper.formatUserName(userName.value)
      : authController.userId.value;

  String get firstLetter {
    final String currentUserId = authController.userId.value;
    return currentUserId.isNotEmpty ? currentUserId[0].toUpperCase() : 'U';
  }
}
