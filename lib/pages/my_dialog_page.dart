import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:get/get.dart';

class MyDialogAnimation extends StatefulWidget {
  final String type;

  const MyDialogAnimation(this.type, {super.key});

  @override
  MyDialogAnimationState createState() => MyDialogAnimationState();
}

class MyDialogAnimationState extends State<MyDialogAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 1), () {
          if (Get.isDialogOpen == true) {
            Get.back(); // tutup dialog
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Lottie.asset(
        widget.type == "reject"
            ? 'data/images/reject_animation.json'
            : 'data/images/success_animation.json',
        controller: _controller,
        onLoaded: (composition) {
          _controller.duration = composition.duration;
          _controller.forward();
        },
      ),
    );
  }
}
