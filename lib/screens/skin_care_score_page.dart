import 'package:flutter/material.dart';
import 'package:mobileprogramming_groupproject_2025/features/dashboard/presentation/widgets/skin_care_status.dart';
import 'package:mobileprogramming_groupproject_2025/features/dashboard/presentation/widgets/skin_care_gauge.dart';
import 'package:mobileprogramming_groupproject_2025/features/dashboard/presentation/widgets/detail_content.dart';

class SkinCareScorePage extends StatefulWidget {
  final int score; // 0-100 점수

  const SkinCareScorePage({
    super.key,
    this.score = 50, // 기본값 50 (NORMAL)
  });

  @override
  State<SkinCareScorePage> createState() => _SkinCareScorePageState();
}

class _SkinCareScorePageState extends State<SkinCareScorePage>
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

  // 점수를 상태로 변환
  SkinCareStatus _getStatus(int score) {
    if (score <= 20) return SkinCareStatus.veryBad;
    if (score <= 40) return SkinCareStatus.bad;
    if (score <= 60) return SkinCareStatus.normal;
    if (score <= 80) return SkinCareStatus.good;
    return SkinCareStatus.excellent;
  }

  @override
  Widget build(BuildContext context) {
    final status = _getStatus(widget.score);
    final angle = _getAngle(widget.score);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.white,
      appBar: AppBar(
        title: Text(
          '피부관리 점수',
          style: TextStyle(
            fontFamily: 'HelveticaNeue93',
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDarkMode
            ? Theme.of(context).appBarTheme.backgroundColor
            : Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // 게이지와 점수를 포함하는 Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    // 게이지 위젯
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        final primaryColor = Theme.of(
                          context,
                        ).colorScheme.primary;
                        final secondaryColor = Theme.of(
                          context,
                        ).colorScheme.secondary;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(350, 200),
                              painter: SkinCareGaugePainter(
                                score: widget.score,
                                angle: angle * _animation.value,
                                status: status,
                                primaryColor: primaryColor,
                                secondaryColor: secondaryColor,
                              ),
                            ),
                            // 가운데 점수 표시
                            Positioned(
                              bottom: 20,
                              child: Column(
                                children: [
                                  Text(
                                    '${widget.score}점',
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
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
                ),
              ),
              const SizedBox(height: 40),
              // 상세 설명
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '상세 분석',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailSection(status),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 점수를 각도로 변환 (0-100 -> 0-180도)
  double _getAngle(int score) {
    return (score / 100) * 180;
  }

  Widget _buildDetailSection(SkinCareStatus status) {
    switch (status) {
      case SkinCareStatus.veryBad:
        return const DetailContent(
          title: '매우 나쁨 (VERY BAD)',
          description:
              '피부 상태가 매우 좋지 않습니다. 전문가의 상담을 받는 것을 권장합니다.\n\n'
              '• 일일 스킨케어 루틴을 재검토하세요\n'
              '• 충분한 수분 공급이 필요합니다\n'
              '• 자극적인 제품 사용을 피하세요\n'
              '• 충분한 수면과 건강한 식습관을 유지하세요',
          color: Colors.red,
        );
      case SkinCareStatus.bad:
        return const DetailContent(
          title: '나쁨 (BAD)',
          description:
              '피부 상태가 개선이 필요합니다. 스킨케어 루틴을 점검하고 개선하세요.\n\n'
              '• 적절한 클렌징과 보습이 중요합니다\n'
              '• 자외선 차단제를 매일 사용하세요\n'
              '• 피부에 맞는 제품을 선택하세요\n'
              '• 스트레스 관리와 충분한 휴식을 취하세요',
          color: Colors.orange,
        );
      case SkinCareStatus.normal:
        return const DetailContent(
          title: '보통 (NORMAL)',
          description:
              '피부 상태가 평균 수준입니다. 현재 루틴을 유지하면서 지속적인 관리가 필요합니다.\n\n'
              '• 규칙적인 스킨케어 루틴을 유지하세요\n'
              '• 수분 공급과 보습에 신경 쓰세요\n'
              '• 주기적으로 피부 상태를 점검하세요\n'
              '• 건강한 생활 습관을 유지하세요',
          color: Colors.amber,
        );
      case SkinCareStatus.good:
        return const DetailContent(
          title: '좋음 (GOOD)',
          description:
              '피부 상태가 양호합니다. 현재 관리 방법을 계속 유지하세요.\n\n'
              '• 현재 스킨케어 루틴을 유지하세요\n'
              '• 예방적 관리에 집중하세요\n'
              '• 주기적으로 피부 상태를 모니터링하세요\n'
              '• 건강한 생활 습관을 계속 유지하세요',
          color: Colors.lightGreen,
        );
      case SkinCareStatus.excellent:
        return const DetailContent(
          title: '매우 좋음 (EXCELLENT)',
          description:
              '피부 상태가 매우 우수합니다! 현재 관리 방법을 계속 유지하세요.\n\n'
              '• 현재 스킨케어 루틴을 그대로 유지하세요\n'
              '• 예방적 관리와 유지에 집중하세요\n'
              '• 건강한 생활 습관을 계속 유지하세요\n'
              '• 정기적인 피부 상태 점검을 받으세요',
          color: Colors.green,
        );
    }
  }
}
