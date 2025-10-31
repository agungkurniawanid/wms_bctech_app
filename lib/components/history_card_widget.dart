import 'package:flutter/material.dart';
import 'package:wms_bctech/components/text_widget.dart';

class HistoryCard extends StatelessWidget {
  final int index;
  final String documentNumber;
  final String approvedDate;
  final String approvedBy;
  final double elevation;
  final Color? backgroundColor;
  final Color? accentColor;
  final VoidCallback? onTap;
  final String type;

  const HistoryCard({
    super.key,
    required this.index,
    required this.documentNumber,
    required this.approvedDate,
    required this.approvedBy,
    this.elevation = 4.0,
    this.backgroundColor,
    this.accentColor,
    this.onTap,
    this.type = 'IN',
  });

  factory HistoryCard.fromDetails({
    required Key? key,
    required int index,
    required String docNumber,
    required DateTime approvedDate,
    required String approvedBy,
    Color? accentColor,
    VoidCallback? onTap,
    String type = 'IN',
  }) {
    final dateFormat = approvedDate.toString();
    return HistoryCard(
      key: key,
      index: index,
      documentNumber: docNumber,
      approvedDate: dateFormat,
      approvedBy: approvedBy,
      accentColor: accentColor,
      onTap: onTap,
      type: type,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final resolvedAccentColor = accentColor ?? colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: resolvedAccentColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8.0),
                            bottomRight: Radius.circular(16.0),
                          ),
                        ),
                        child: TextWidget(
                          text: '$type - $documentNumber',
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimary,
                          maxLines: 1,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),

                    // Trailing Icon
                    const SizedBox(width: 12.0),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16.0,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),

                const SizedBox(height: 12.0),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16.0,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: TextWidget(
                        text: 'Approved Date: $approvedDate',
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8.0),
                Row(
                  children: [
                    Icon(
                      Icons.person_rounded,
                      size: 16.0,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: TextWidget(
                        text: 'Approved By: $approvedBy',
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),

                if (index == 0) ...[
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Icon(
                        Icons.format_list_numbered_rounded,
                        size: 16.0,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8.0),
                      TextWidget(
                        text: 'Item #${index + 1}',
                        fontSize: 12.0,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurfaceVariant,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CompactHistoryCard extends StatelessWidget {
  final String documentNumber;
  final String date;
  final String status;
  final VoidCallback? onTap;
  final Color? statusColor;

  const CompactHistoryCard({
    super.key,
    required this.documentNumber,
    required this.date,
    required this.status,
    this.onTap,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 4.0,
          decoration: BoxDecoration(
            color: statusColor ?? colorScheme.primary,
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
        title: TextWidget(
          text: documentNumber,
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
          maxLines: 1,
        ),
        subtitle: TextWidget(
          text: date,
          fontSize: 14.0,
          fontWeight: FontWeight.normal,
          color: colorScheme.onSurfaceVariant,
          maxLines: 1,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color:
                statusColor?.withValues(alpha: 0.1) ??
                colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: statusColor ?? colorScheme.primary,
              width: 1.0,
            ),
          ),
          child: TextWidget(
            text: status,
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
            color: statusColor ?? colorScheme.primary,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
