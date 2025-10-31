import 'package:flutter/material.dart';

/// Modern Loading Overlay untuk proses Kirim CPERP
class InModernLoadingOverlayWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color primaryColor;

  const InModernLoadingOverlayWidget({
    super.key,
    this.title = 'Mengirim ke CPERP',
    this.subtitle = 'Mohon tunggu, sedang memproses data...',
    this.primaryColor = const Color(0xFF00AA13),
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Loading Circle
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer rotating circle
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                // Inner rotating circle
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
                // Icon in center
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D2D2D),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Progress steps indicator
            _buildProgressSteps(primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSteps(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildStepItem(
            icon: Icons.check_circle,
            text: 'Validasi data',
            isCompleted: true,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 8),
          _buildStepItem(
            icon: Icons.sync,
            text: 'Mengirim ke CPERP',
            isCompleted: false,
            isActive: true,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 8),
          _buildStepItem(
            icon: Icons.done_all,
            text: 'Konfirmasi penerimaan',
            isCompleted: false,
            primaryColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required IconData icon,
    required String text,
    required bool isCompleted,
    bool isActive = false,
    required Color primaryColor,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isCompleted
                ? primaryColor
                : isActive
                ? primaryColor.withValues(alpha: 0.2)
                : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isCompleted
                ? Colors.white
                : isActive
                ? primaryColor
                : Colors.grey.shade400,
            size: 14,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'MonaSans',
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isCompleted || isActive
                  ? const Color(0xFF2D2D2D)
                  : Colors.grey.shade500,
            ),
          ),
        ),
        if (isActive)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
      ],
    );
  }
}

class CompactLoadingOverlay extends StatelessWidget {
  final String message;
  final Color primaryColor;

  const CompactLoadingOverlay({
    super.key,
    this.message = 'Mengirim ke CPERP...',
    this.primaryColor = const Color(0xFF00AA13),
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing circle animation
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.3),
                    primaryColor.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Message
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2D2D),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Animated dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _AnimatedDot(
                    delay: Duration(milliseconds: index * 200),
                    color: primaryColor,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedDot extends StatefulWidget {
  final Duration delay;
  final Color color;

  const _AnimatedDot({required this.delay, required this.color});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
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
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
