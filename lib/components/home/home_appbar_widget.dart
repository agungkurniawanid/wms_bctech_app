import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:wms_bctech/constants/app_constant.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/controllers/auth/auth_controller.dart';
import 'package:wms_bctech/helpers/text_helper.dart';

class HomeAppbarWidget extends StatefulWidget {
  const HomeAppbarWidget({super.key});

  @override
  State<HomeAppbarWidget> createState() => _HomeAppbarWidgetState();
}

class _HomeAppbarWidgetState extends State<HomeAppbarWidget> {
  final authController = Get.find<NewAuthController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Day,',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),

              Obx(() {
                final rawName =
                    authController.userName.value ??
                    authController.userId.value;
                final formattedName = TextHelper.formatUserName(rawName);

                return Text(
                  formattedName.isEmpty ? 'Memuat...' : formattedName,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }),

              const SizedBox(height: 8),
              Text(
                'App Version ${AppConstants.appVersion}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          Spacer(),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              FontAwesomeIcons.solidBell,
              color: hijauGojek,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
