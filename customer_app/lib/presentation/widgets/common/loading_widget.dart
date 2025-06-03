// lib/widgets/common/loading_widget.dart
import 'package:flutter/material.dart';

enum LoadingType {
  circular,
  linear,
  dots,
  pulse,
  spinner,
  wave,
}

class LoadingWidget extends StatelessWidget {
  final String? message;
  final Color? color;
  final double? size;
  final double? strokeWidth;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final bool showBackground;
  final Color? backgroundColor;
  final LoadingType type;

  const LoadingWidget({
    Key? key,
    this.message,
    this.color,
    this.size,
    this.strokeWidth,
    this.textStyle,
    this.padding,
    this.showBackground = false,
    this.backgroundColor,
    this.type = LoadingType.circular,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget loadingContent = _buildLoadingContent();

    if (showBackground) {
      return Container(
        color: backgroundColor ?? Colors.black.withOpacity(0.3),
        child: loadingContent,
      );
    }

    return loadingContent;
  }

  Widget _buildLoadingContent() {
    return Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLoadingIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: textStyle ?? const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF718096),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final Color indicatorColor = color ?? const Color(0xFF4299E1);
    final double indicatorSize = size ?? 40;

    switch (type) {
      case LoadingType.circular:
        return SizedBox(
          width: indicatorSize,
          height: indicatorSize,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth ?? 3,
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
          ),
        );

      case LoadingType.linear:
        return SizedBox(
          width: indicatorSize * 2,
          child: LinearProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            backgroundColor: indicatorColor.withOpacity(0.2),
          ),
        );

      case LoadingType.dots:
        return DotsLoadingIndicator(
          color: indicatorColor,
          size: indicatorSize / 6,
        );

      case LoadingType.pulse:
        return PulseLoadingIndicator(
          color: indicatorColor,
          size: indicatorSize,
        );

      case LoadingType.spinner:
        return SpinnerLoadingIndicator(
          color: indicatorColor,
          size: indicatorSize,
        );

      case LoadingType.wave:
        return WaveLoadingIndicator(
          color: indicatorColor,
          size: indicatorSize,
        );

      default:
        return SizedBox(
          width: indicatorSize,
          height: indicatorSize,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth ?? 3,
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
          ),
        );
    }
  }
}

// Predefined loading widgets for common scenarios
class ScreenLoadingWidget extends StatelessWidget {
  final String? message;

  const ScreenLoadingWidget({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LoadingWidget(
        message: message ?? 'Loading...',
        type: LoadingType.circular,
      ),
    );
  }
}

class OverlayLoadingWidget extends StatelessWidget {
  final String? message;
  final Widget child;

  const OverlayLoadingWidget({
    Key? key,
    required this.child,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        LoadingWidget(
          message: message,
          showBackground: true,
          backgroundColor: Colors.black.withOpacity(0.5),
          type: LoadingType.circular,
        ),
      ],
    );
  }
}

class InlineLoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;

  const InlineLoadingWidget({
    Key? key,
    this.message,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size ?? 16,
          height: size ?? 16,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        if (message != null) ...[
          const SizedBox(width: 8),
          Text(
            message!,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF718096),
            ),
          ),
        ],
      ],
    );
  }
}

class ButtonLoadingWidget extends StatelessWidget {
  final Color? color;
  final double? size;

  const ButtonLoadingWidget({
    Key? key,
    this.color,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size ?? 20,
      height: size ?? 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Colors.white,
        ),
      ),
    );
  }
}

// Custom loading indicators
class DotsLoadingIndicator extends StatefulWidget {
  final Color color;
  final double size;

  const DotsLoadingIndicator({
    Key? key,
    required this.color,
    required this.size,
  }) : super(key: key);

  @override
  State<DotsLoadingIndicator> createState() => _DotsLoadingIndicatorState();
}

class _DotsLoadingIndicatorState extends State<DotsLoadingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.size * 0.2),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.3 + _animations[index].value * 0.7),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

class PulseLoadingIndicator extends StatefulWidget {
  final Color color;
  final double size;

  const PulseLoadingIndicator({
    Key? key,
    required this.color,
    required this.size,
  }) : super(key: key);

  @override
  State<PulseLoadingIndicator> createState() => _PulseLoadingIndicatorState();
}

class _PulseLoadingIndicatorState extends State<PulseLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.3 + _animation.value * 0.7),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class SpinnerLoadingIndicator extends StatefulWidget {
  final Color color;
  final double size;

  const SpinnerLoadingIndicator({
    Key? key,
    required this.color,
    required this.size,
  }) : super(key: key);

  @override
  State<SpinnerLoadingIndicator> createState() => _SpinnerLoadingIndicatorState();
}

class _SpinnerLoadingIndicatorState extends State<SpinnerLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: SpinnerPainter(
          color: widget.color,
          animation: _controller,
        ),
      ),
    );
  }
}

class SpinnerPainter extends CustomPainter {
  final Color color;
  final Animation<double> animation;

  SpinnerPainter({required this.color, required this.animation})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw spinning arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      animation.value * 2 * 3.14159,
      3.14159, // Half circle
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(SpinnerPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class WaveLoadingIndicator extends StatefulWidget {
  final Color color;
  final double size;

  const WaveLoadingIndicator({
    Key? key,
    required this.color,
    required this.size,
  }) : super(key: key);

  @override
  State<WaveLoadingIndicator> createState() => _WaveLoadingIndicatorState();
}

class _WaveLoadingIndicatorState extends State<WaveLoadingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(5, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.size * 0.05),
              width: widget.size * 0.15,
              height: widget.size * (0.3 + _animations[index].value * 0.7),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(widget.size * 0.1),
              ),
            );
          },
        );
      }),
    );
  }
}

// Shimmer loading effect
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    Key? key,
    required this.child,
    required this.isLoading,
    this.baseColor,
    this.highlightColor,
  }) : super(key: key);

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isLoading && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor ?? Colors.grey[300]!,
                widget.highlightColor ?? Colors.grey[100]!,
                widget.baseColor ?? Colors.grey[300]!,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
              transform: GradientRotation(0),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}