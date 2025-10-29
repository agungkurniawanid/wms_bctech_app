import 'package:flutter/material.dart';
import 'package:wms_bctech/widgets/text_widget.dart';

class CardWidget extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final double elevation;
  final double iconSize;
  final double fontSize;
  final String? secondaryText;
  final bool? isRegistered;
  final double height;
  final Widget? trailingButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final BorderRadiusGeometry? borderRadius;

  const CardWidget({
    super.key,
    this.text,
    this.icon,
    this.elevation = 4.0,
    this.iconSize = 24.0,
    this.fontSize = 14.0,
    this.secondaryText,
    this.isRegistered,
    this.height = 60.0,
    this.trailingButton,
    this.onBackPressed,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReg = isRegistered ?? false;
    final hasTrailingButton = trailingButton != null;

    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12.0),
      ),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  color: backgroundColor ?? theme.colorScheme.primaryContainer,
                  borderRadius:
                      borderRadius?.resolve(TextDirection.ltr) ??
                      const BorderRadius.only(
                        topLeft: Radius.circular(12.0),
                        bottomRight: Radius.circular(20.0),
                      ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextWidget(
                      text: isReg
                          ? (secondaryText ?? 'No Text')
                          : 'No Document',
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      maxLines: 1,
                      textAlign: TextAlign.left,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    if (isReg) ...[
                      IconButton(
                        onPressed:
                            onBackPressed ?? () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20.0,
                          color: theme.colorScheme.primary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36.0,
                          minHeight: 36.0,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                    ],
                    Expanded(
                      child: TextWidget(
                        text: text ?? 'No Title',
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (isReg && hasTrailingButton) ...[
                      const SizedBox(width: 4.0),
                      trailingButton!,
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomCardWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final bool enabled;

  const CustomCardWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.color,
    this.padding,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2.0,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: enabled ? onTap : null,
        onLongPress: enabled ? onLongPress : null,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16.0),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 16.0)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12.0), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
