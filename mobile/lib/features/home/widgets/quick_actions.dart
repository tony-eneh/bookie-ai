import 'package:flutter/material.dart';
import 'package:bookie_ai/core/theme/app_colors.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    this.onVoiceLog,
    this.onAddManual,
    this.onPayGoal,
    this.onViewInsights,
  });

  final VoidCallback? onVoiceLog;
  final VoidCallback? onAddManual;
  final VoidCallback? onPayGoal;
  final VoidCallback? onViewInsights;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          _QuickActionButton(
            icon: Icons.mic,
            label: 'Voice Log',
            color: AppColors.accent,
            onTap: onVoiceLog,
          ),
          const SizedBox(width: 16),
          _QuickActionButton(
            icon: Icons.add,
            label: 'Add Manual',
            color: AppColors.info,
            onTap: onAddManual,
          ),
          const SizedBox(width: 16),
          _QuickActionButton(
            icon: Icons.flag,
            label: 'Pay Goal',
            color: const Color(0xFF9C27B0),
            onTap: onPayGoal,
          ),
          const SizedBox(width: 16),
          _QuickActionButton(
            icon: Icons.lightbulb_outline,
            label: 'Insights',
            color: AppColors.warning,
            onTap: onViewInsights,
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();
  void _onTapUp(TapUpDetails _) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                color: widget.color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
