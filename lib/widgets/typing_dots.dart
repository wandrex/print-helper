import 'package:flutter/material.dart';

class TypingBubbleWave extends StatefulWidget {
  final Color bubbleColor;
  final Color dotColor;
  final double dotSize;

  const TypingBubbleWave({
    super.key,
    this.bubbleColor = const Color(0xFFEFEFEF),
    this.dotColor = Colors.grey,
    this.dotSize = 6,
  });

  @override
  State<TypingBubbleWave> createState() => _TypingBubbleWaveState();
}

class _TypingBubbleWaveState extends State<TypingBubbleWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _dotAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.15,
            0.6 + index * 0.15,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _dot(Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(0, animation.value),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        height: widget.dotSize,
        width: widget.dotSize,
        decoration: BoxDecoration(
          color: widget.dotColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: widget.bubbleColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _dotAnimations.map(_dot).toList(),
      ),
    );
  }
}
