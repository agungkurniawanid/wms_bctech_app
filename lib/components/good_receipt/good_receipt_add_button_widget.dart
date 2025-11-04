import 'package:flutter/material.dart';
import 'package:wms_bctech/constants/good_receipt/good_receipt_constant.dart';

class GoodReceiptAddButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;
  final String buttonText;
  final IconData? icon;
  final double iconSize;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;

  const GoodReceiptAddButtonWidget({
    super.key,
    required this.onPressed,
    this.buttonText = 'Tambah Good Receipt',
    this.icon = Icons.add,
    this.iconSize = 20,
    this.horizontalPadding = 20,
    this.verticalPadding = 12,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: GoodReceiptConstant.primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize),
            const SizedBox(width: 8),
            Text(
              buttonText,
              style: const TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
