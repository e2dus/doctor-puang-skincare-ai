import 'package:flutter/material.dart';
import 'skin_care_status.dart';
import 'skin_care_gauge.dart';

class SkinCareGaugeWidget extends StatefulWidget {
  final int score;

  const SkinCareGaugeWidget({super.key, required this.score});

  @override
  State<SkinCareGaugeWidget> createState() => _SkinCareGaugeWidgetState();
}

class _SkinCareGaugeWidgetState extends State<SkinCareGaugeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  SkinCareStatus _getStatus(int score) {
    if (score <= 20) return SkinCareStatus.veryBad;
    if (score <= 40) return SkinCareStatus.bad;
    if (score <= 60) return SkinCareStatus.normal;
    if (score <= 80) return SkinCareStatus.good;
    return SkinCareStatus.excellent;
  }

  double _getAngle(int score) {
    return (score / 100) * 180;
  }

  @override
  Widget build(BuildContext context) {
    final status = _getStatus(widget.score);
    final angle = _getAngle(widget.score);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "What's My Skin Score?",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFamily: 'HelveticaNeue93',
              color: Colors.black87,
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(350, 180),
                  painter: SkinCareGaugePainter(
                    score: widget.score,
                    angle: angle * _animation.value,
                    status: status,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                  ),
                ),
                Positioned(
                  bottom: 20,
                  child: Column(
                    children: [
                      Text(
                        '${widget.score} points',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'HelveticaNeue93',
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status.label,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: status.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
