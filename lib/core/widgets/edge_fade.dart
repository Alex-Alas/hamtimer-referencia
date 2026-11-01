import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Difumina el borde derecho de una lista horizontal para avisar que hay más
/// elementos al deslizar. El difuminado desaparece al llegar al final.
class EdgeFade extends StatefulWidget {
  const EdgeFade({super.key, required this.child, this.width = 36});

  final Widget child;
  final double width;

  @override
  State<EdgeFade> createState() => _EdgeFadeState();
}

class _EdgeFadeState extends State<EdgeFade> {
  bool _hasMore = true;

  bool _onMetrics(ScrollMetrics metrics) {
    final hasMore = metrics.extentAfter > 8;
    if (hasMore != _hasMore) setState(() => _hasMore = hasMore);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (n) => _onMetrics(n.metrics),
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) => _onMetrics(n.metrics),
            child: widget.child,
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: widget.width,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _hasMore ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.surface.withValues(alpha: 0), AppColors.surface],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
