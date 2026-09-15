import 'package:core_architecture/core_architecture.dart';
import 'package:flutter/material.dart';

/// This app's loading indicator, drawn here rather than pulled from a package.
///
/// It exists to make the point that core_architecture no longer decides which
/// animation library an app depends on: it is installed once through
/// `AppTheme.light(loadingIndicatorBuilder: ...)`, and every [CustomButton]
/// picks it up.
class PulsingDots extends StatefulWidget {
  const PulsingDots({super.key, required this.color});

  /// Handed in by the package: the foreground of the button showing it, so the
  /// dots stay legible on a primary, secondary, outlined or danger button.
  final Color color;

  @override
  State<PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.shimmer,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < 3; i++)
            Padding(
              padding: SpacingUtils.onlyRight(AppSpacings.wXxs),
              child: Opacity(
                // Each dot trails the one before it by a third of a cycle.
                opacity: (((_controller.value + i / 3) % 1) - 0.5).abs() * 2,
                child: Container(
                  width: AppSpacings.wXs,
                  height: AppSpacings.hXs,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
