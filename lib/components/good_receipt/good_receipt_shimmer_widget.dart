import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class GoodReceiptShimmerWidget extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double verticalPadding;
  final double borderRadius;
  final Color baseColor;
  final Color highlightColor;
  final Duration period;

  const GoodReceiptShimmerWidget({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 140,
    this.verticalPadding = 8,
    this.borderRadius = 16,
    this.baseColor = Colors.grey,
    this.highlightColor = Colors.white,
    this.period = const Duration(milliseconds: 1500),
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: itemCount,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          child: Shimmer.fromColors(
            baseColor: baseColor.withValues(alpha: 0.3),
            highlightColor: highlightColor.withValues(alpha: 0.1),
            period: period,
            child: Container(
              width: double.infinity,
              height: itemHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
