// todo:✅ Clean Code checked
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class HomeShimmerLoadingWidget extends StatefulWidget {
  const HomeShimmerLoadingWidget({super.key});

  @override
  State<HomeShimmerLoadingWidget> createState() =>
      _HomeShimmerLoadingWidgetState();
}

class _HomeShimmerLoadingWidgetState extends State<HomeShimmerLoadingWidget> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: 250,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
