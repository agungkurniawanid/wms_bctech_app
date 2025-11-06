import 'package:flutter/material.dart';
import 'package:wms_bctech/constants/delivery_order/delivery_order_constant.dart';

class DeliveryOrderEmptyWidget extends StatelessWidget {
  final VoidCallback onRefresh;
  final String title;
  final String description;
  final String buttonText;
  final IconData icon;
  final double iconSize;
  final double iconContainerSize;
  final double spacing;

  const DeliveryOrderEmptyWidget({
    super.key,
    required this.onRefresh,
    this.title = "No Delivery Order Data Found",
    this.description = "No Delivery Order serial numbers available",
    this.buttonText = 'Refresh',
    this.icon = Icons.inventory_outlined,
    this.iconSize = 60,
    this.iconContainerSize = 120,
    this.spacing = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                color: DeliveryOrderConstant.backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: DeliveryOrderConstant.textSecondaryColor,
              ),
            ),
            SizedBox(height: spacing),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: DeliveryOrderConstant.textPrimaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 14,
                color: DeliveryOrderConstant.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: DeliveryOrderConstant.primaryColor,
              ),
              child: TextButton(
                onPressed: onRefresh,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontFamily: 'MonaSans',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// checked
