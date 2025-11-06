import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:wms_bctech/constants/theme_constant.dart';

class TextWidget extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final int maxLines;
  final Color? color;
  final bool isUnderlined;
  final double? height;
  final TextOverflow overflow;
  final TextStyle? textStyle;

  const TextWidget({
    super.key,
    required this.text,
    this.fontSize = 14.0,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.color,
    this.isUnderlined = false,
    this.height,
    this.overflow = TextOverflow.ellipsis,
    this.textStyle,
  });

  const TextWidget.headlineLarge({
    super.key,
    required this.text,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines = 2,
    this.height,
  }) : fontSize = 32.0,
       fontWeight = FontWeight.w700,
       isUnderlined = false,
       overflow = TextOverflow.ellipsis,
       textStyle = null;

  const TextWidget.headlineMedium({
    super.key,
    required this.text,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines = 2,
    this.height,
  }) : fontSize = 24.0,
       fontWeight = FontWeight.w600,
       isUnderlined = false,
       overflow = TextOverflow.ellipsis,
       textStyle = null;

  const TextWidget.titleLarge({
    super.key,
    required this.text,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.height,
  }) : fontSize = 20.0,
       fontWeight = FontWeight.w600,
       isUnderlined = false,
       overflow = TextOverflow.ellipsis,
       textStyle = null;

  const TextWidget.titleMedium({
    super.key,
    required this.text,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.height,
  }) : fontSize = 16.0,
       fontWeight = FontWeight.w500,
       isUnderlined = false,
       overflow = TextOverflow.ellipsis,
       textStyle = null;

  const TextWidget.bodyLarge({
    super.key,
    required this.text,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines = 3,
    this.height,
  }) : fontSize = 16.0,
       fontWeight = FontWeight.normal,
       isUnderlined = false,
       overflow = TextOverflow.ellipsis,
       textStyle = null;

  const TextWidget.bodyMedium({
    super.key,
    required this.text,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines = 3,
    this.height,
  }) : fontSize = 14.0,
       fontWeight = FontWeight.normal,
       isUnderlined = false,
       overflow = TextOverflow.ellipsis,
       textStyle = null;

  const TextWidget.bodySmall({
    super.key,
    required this.text,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines = 2,
    this.height,
  }) : fontSize = 12.0,
       fontWeight = FontWeight.normal,
       isUnderlined = false,
       overflow = TextOverflow.ellipsis,
       textStyle = null;

  const TextWidget.labelLarge({
    super.key,
    required this.text,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.height,
  }) : fontSize = 14.0,
       fontWeight = FontWeight.w500,
       isUnderlined = false,
       overflow = TextOverflow.ellipsis,
       textStyle = null;

  const TextWidget.labelSmall({
    super.key,
    required this.text,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.height,
  }) : fontSize = 11.0,
       fontWeight = FontWeight.w400,
       isUnderlined = false,
       overflow = TextOverflow.ellipsis,
       textStyle = null;

  const TextWidget.error({
    super.key,
    required this.text,
    this.fontSize = 14.0,
    this.textAlign = TextAlign.start,
    this.maxLines = 2,
    this.height,
  }) : fontWeight = FontWeight.normal,
       color = kErrorColor,
       isUnderlined = false,
       overflow = TextOverflow.ellipsis,
       textStyle = null;

  const TextWidget.success({
    super.key,
    required this.text,
    this.fontSize = 14.0,
    this.textAlign = TextAlign.start,
    this.maxLines = 2,
    this.height,
  }) : fontWeight = FontWeight.normal,
       color = kSuccessColor,
       isUnderlined = false,
       overflow = TextOverflow.ellipsis,
       textStyle = null;

  const TextWidget.primary({
    super.key,
    required this.text,
    this.fontSize = 14.0,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.start,
    this.maxLines = 2,
    this.height,
  }) : color = kBlueColor,
       isUnderlined = false,
       overflow = TextOverflow.ellipsis,
       textStyle = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final resolvedColor = color ?? theme.colorScheme.onSurface;

    final textStyle =
        this.textStyle ??
        TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: resolvedColor,
          height: height,
          decoration: isUnderlined
              ? TextDecoration.underline
              : TextDecoration.none,
        );

    return AutoSizeText(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: textStyle,
      minFontSize: 8.0,
    );
  }
}

class SimpleTextWidget extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final int maxLines;
  final TextOverflow overflow;
  final bool selectable;

  const SimpleTextWidget({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = Theme.of(context).textTheme.bodyMedium;
    final resolvedStyle = defaultStyle?.merge(style);

    if (selectable) {
      return SelectableText(
        text,
        style: resolvedStyle,
        textAlign: textAlign,
        maxLines: maxLines,
      );
    }

    return Text(
      text,
      style: resolvedStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

// checked
