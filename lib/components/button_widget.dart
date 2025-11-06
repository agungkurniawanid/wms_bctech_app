import 'package:flutter/material.dart';
import 'package:wms_bctech/constants/theme_constant.dart';

class BtnWidget extends StatelessWidget {
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final OutlinedBorder? shape;
  final String buttonText;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool isEnabled;

  const BtnWidget({
    super.key,
    required this.onPressed,
    required this.buttonText,
    this.backgroundColor,
    this.foregroundColor,
    this.shape,
    this.width,
    this.height,
    this.padding,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 50,
      child: FilledButton(
        onPressed: isEnabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor ?? const Color(0xfff44236),
          foregroundColor: foregroundColor ?? kWhiteColor,
          disabledBackgroundColor: Colors.grey.shade400,
          shape:
              shape ??
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
            fontFamily: 'MonaSans',
          ),
        ),
        child: Text(buttonText),
      ),
    );
  }
}

class CustomButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Color? color;
  final Color? textColor;
  final bool isExpanded;
  final bool isLoading;
  final IconData? icon;
  final double borderRadius;

  const CustomButtonWidget({
    super.key,
    required this.onPressed,
    required this.text,
    this.color,
    this.textColor,
    this.isExpanded = true,
    this.isLoading = false,
    this.icon,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isExpanded ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? const Color(0xfff44236),
          foregroundColor: textColor ?? Colors.white,
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
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

// checked
