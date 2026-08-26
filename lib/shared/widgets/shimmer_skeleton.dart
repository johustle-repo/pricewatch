import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class ShimmerSkeleton extends StatefulWidget {
  const ShimmerSkeleton({super.key, required this.child});

  final Widget child;

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
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
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + (_controller.value * 2), -0.3),
              end: Alignment(1.0 + (_controller.value * 2), 0.3),
              colors: const [
                Color(0xFFE5E7EB),
                Color(0xFFF8FAFC),
                Color(0xFFE5E7EB),
              ],
              stops: const [0.1, 0.45, 0.9],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 16,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.backgroundAlt,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class ListLoadingView extends StatelessWidget {
  const ListLoadingView({
    super.key,
    this.cardCount = 5,
    this.shrinkWrap = false,
  });

  final int cardCount;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    Widget loadingCard() => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          SkeletonBox(height: 60, width: 60, radius: 20),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 16, width: 150),
                SizedBox(height: 10),
                SkeletonBox(height: 12, width: 110),
              ],
            ),
          ),
          SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SkeletonBox(height: 16, width: 56),
              SizedBox(height: 10),
              SkeletonBox(height: 12, width: 44),
            ],
          ),
        ],
      ),
    );

    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < cardCount; index++) ...[
            loadingCard(),
            if (index != cardCount - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );

    if (shrinkWrap) {
      return content;
    }

    return SingleChildScrollView(
      primary: false,
      physics: const AlwaysScrollableScrollPhysics(),
      child: content,
    );
  }
}
