import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/daily_tips_carousel.dart';
import '../widgets/skin_care_gauge_widget.dart';
import '../widgets/friends_score_list.dart';
import '../../../chat/presentation/viewmodels/skincare_score_provider.dart';
import 'skin_detail_analysis_page.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  DateTime? _lastScoreRefreshTime;

  final List<Map<String, String>> _tips = [
    {
      'title': 'Enter in calendar!',
      'subtitle': 'Schedule your skincare routine',
    },
    {
      'title': '100% Chatbot Usage Guide!',
      'subtitle': 'Get the most out of Puang',
    },
  ];

  final List<Map<String, dynamic>> _friends = [
    {'name': 'Jae Kwon Lee', 'score': 72},
    {'name': 'Min Jun Park', 'score': 85},
    {'name': 'Min Jun Park', 'score': 68},
  ];

  @override
  Widget build(BuildContext context) {
    final scoreState = ref.watch(skincareScoreProvider);
    final score = scoreState.score ?? 0;

    // 3일 미만 데이터인 경우 안내 메시지 표시
    if (!scoreState.hasEnoughData && !scoreState.isLoading) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 오늘의 팁! 컨테이너
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: DailyTipsCarousel(tips: _tips),
              ),
              // 데이터 부족 안내
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
                    Icon(
                      Icons.calendar_today,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '📅 We need a bit more data',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check your skincare routine in the calendar\nfor at least 3 days and AI will calculate your skin score ✨',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current recorded days: ${scoreState.daysCount}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 오늘의 팁! 컨테이너
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: DailyTipsCarousel(tips: _tips),
            ),
            // 게이지와 점수를 포함하는 Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Stack(
                children: [
                  // 오른쪽 위 새로고침 아이콘
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.refresh),
                      color: Colors.grey[600],
                      tooltip: 'Refresh score',
                      onPressed: scoreState.isLoading
                          ? null
                          : () async {
                              final now = DateTime.now();
                              if (_lastScoreRefreshTime != null &&
                                  now.difference(_lastScoreRefreshTime!).inSeconds < 60) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please try again in 1 minute.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                                return;
                              }

                              _lastScoreRefreshTime = now;
                              final notifier = ref.read(skincareScoreProvider.notifier);
                              await notifier.calculateScore();
                            },
                    ),
                  ),
                  // 본문 내용
                  Center(
                    child: GestureDetector(
                      onTap: scoreState.isLoading || scoreState.error != null
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SkinDetailAnalysisPage(
                                    score: score,
                                  ),
                                ),
                              );
                            },
                      child: scoreState.isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            )
                          : scoreState.error != null
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.red[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Error calculating score',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'AI is too busy right now 😢\nPlease try again in a few minutes.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                )
                              : SkinCareGaugeWidget(score: score),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 친구들의 점수
            FriendsScoreList(friends: _friends),
          ],
        ),
      ),
    );
  }
}
