// todo:✅ Clean Code checked
import 'package:flutter/material.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/helpers/date_helper.dart';

class HomeRecentOrderCardWidget extends StatefulWidget {
  final String documentNo;
  final String title1;
  final String value1;
  final String title2;
  final String value2;
  final String title3;
  final String value3;
  final String contextType;

  const HomeRecentOrderCardWidget({
    super.key,
    required this.documentNo,
    required this.title1,
    required this.value1,
    required this.title2,
    required this.value2,
    required this.title3,
    required this.value3,
    required this.contextType,
  });

  @override
  State<HomeRecentOrderCardWidget> createState() =>
      _HomeRecentOrderCardWidgetState();
}

class _HomeRecentOrderCardWidgetState extends State<HomeRecentOrderCardWidget> {
  Widget _buildInfoRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 14,
            ),
            softWrap: true,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [hijauGojek, hijauGojek.withValues(alpha: 0.8)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Text(
              widget.documentNo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  '${widget.title1}:',
                  DateHelper.formatDate(widget.value1),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('${widget.title2}:', widget.value2),
                const SizedBox(height: 8),
                _buildInfoRow('${widget.title3}:', widget.value3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
