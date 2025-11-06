import 'package:flutter/material.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:intl/intl.dart';
import 'package:wms_bctech/models/out/out_detail_model.dart';

class OutProductDetailBottomsheetWidget extends StatelessWidget {
  final OutDetailModel product;
  final Function()? onScan;
  final Function()? onManualInput;

  const OutProductDetailBottomsheetWidget({
    required this.product,
    this.onScan,
    this.onManualInput,
    super.key,
  });

  String _formatCurrency(num? value) {
    if (value == null) return "Rp 0";
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  Color _getStatusColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return Colors.blue;
    if (progress >= 0.3) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final qtyEntered = product.qtyEntered?.toInt() ?? 0;
    final qtyOrdered = product.qtyordered?.toInt() ?? 0;
    final qtyDelivered = product.qtydelivered?.toInt() ?? 0;
    final qtyReserved = product.qtyreserved?.toInt() ?? 0;
    final qtyInvoiced = product.qtyinvoiced?.toInt() ?? 0;
    final remainingQty = qtyOrdered - qtyEntered;
    final progress = qtyOrdered > 0 ? (qtyEntered / qtyOrdered) : 0.0;
    final isSNInput = product.isSN == "Y";
    final isFullyDelivered = product.isFullyDelivered == "Y";

    return Container(
      height: screenHeight * 0.92,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [hijauGojek, hijauGojek.withValues(alpha: 0.85)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: hijauGojek.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.inventory_2_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.cOrderId ?? "-",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, color: Colors.white),
                        iconSize: 24,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isFullyDelivered
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFullyDelivered
                            ? Icons.check_circle_rounded
                            : Icons.pending_actions_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        isFullyDelivered ? 'Fully Delivered' : 'In Progress',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: hijauGojek,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Product Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildInfoTile(
                          "Product Name",
                          product.mProductName ?? "-",
                          Icons.inventory_2_outlined,
                        ),
                        _buildInfoTile(
                          "Product ID",
                          product.mProductId ?? "-",
                          Icons.qr_code_2_outlined,
                        ),
                        _buildInfoTile(
                          "Unit of Measure",
                          product.cUomId ?? "-",
                          Icons.straighten_outlined,
                        ),
                        _buildInfoTile(
                          "Tax Information",
                          product.cTaxId ?? "-",
                          Icons.receipt_long_outlined,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              color: hijauGojek,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delivery Progress',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  progress,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${(progress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(progress),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Stack(
                          children: [
                            Container(
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                height: 14,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getStatusColor(progress),
                                      _getStatusColor(
                                        progress,
                                      ).withValues(alpha: 0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getStatusColor(
                                        progress,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMiniStatCard(
                                "Ordered",
                                qtyOrdered.toString(),
                                Icons.shopping_cart_outlined,
                                Colors.blue,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _buildMiniStatCard(
                                "Entered",
                                qtyEntered.toString(),
                                Icons.input_rounded,
                                Colors.green,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _buildMiniStatCard(
                                "Remaining",
                                remainingQty.toString(),
                                Icons.pending_outlined,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMiniStatCard(
                                "Delivered",
                                qtyDelivered.toString(),
                                Icons.local_shipping_outlined,
                                Colors.purple,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _buildMiniStatCard(
                                "Reserved",
                                qtyReserved.toString(),
                                Icons.bookmark_outline,
                                Colors.teal,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _buildMiniStatCard(
                                "Invoiced",
                                qtyInvoiced.toString(),
                                Icons.description_outlined,
                                Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              color: hijauGojek,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Pricing Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildPriceRow(
                          "Price List",
                          double.tryParse(product.pricelist ?? "") ?? 0.0,
                          Colors.grey,
                        ),
                        _buildPriceRow(
                          "Price Entered",
                          product.priceentered ?? 0,
                          Colors.blue,
                        ),
                        _buildPriceRow(
                          "Price Actual",
                          product.priceactual ?? 0,
                          hijauGojek,
                          isHighlight: true,
                        ),
                      ],
                    ),
                  ),
                  if (isSNInput &&
                      product.sN != null &&
                      product.sN!.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.qr_code_scanner_rounded,
                                color: hijauGojek,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Serial Numbers',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: hijauGojek.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${product.sN!.length} items',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: hijauGojek,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 14),
                          ...List.generate(
                            product.sN!.length,
                            (index) => Container(
                              margin: EdgeInsets.only(bottom: 8),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.grey.shade50,
                                    Colors.grey.shade100,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          hijauGojek.withValues(alpha: 0.2),
                                          hijauGojek.withValues(alpha: 0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: hijauGojek,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      product.sN![index].toString(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.verified_outlined,
                                    size: 18,
                                    color: Colors.green.shade400,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    String label,
    String value,
    IconData icon, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hijauGojek.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: hijauGojek),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          SizedBox(height: 12),
          Divider(height: 1),
          SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildMiniStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    num price,
    Color color, {
    bool isHighlight = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: isHighlight
            ? LinearGradient(
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.08),
                ],
              )
            : null,
        color: isHighlight ? null : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: isHighlight
            ? Border.all(color: color.withValues(alpha: 0.4), width: 2)
            : Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            _formatCurrency(price),
            style: TextStyle(
              fontSize: isHighlight ? 15 : 14,
              fontWeight: FontWeight.bold,
              color: isHighlight ? color : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

// checked
