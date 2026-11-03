import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/skin_detail_analysis_provider.dart';

/// 상세 피부 분석 페이지 (영어)
class SkinDetailAnalysisPage extends ConsumerStatefulWidget {
  final int score;

  const SkinDetailAnalysisPage({super.key, required this.score});

  @override
  ConsumerState<SkinDetailAnalysisPage> createState() =>
      _SkinDetailAnalysisPageState();
}

class _SkinDetailAnalysisPageState
    extends ConsumerState<SkinDetailAnalysisPage> {
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    // 첫 진입 시, 아직 분석 데이터가 없고 로딩 중이 아닐 때만 요청
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = ref.read(skinDetailAnalysisProvider);
      if (!currentState.isLoading && currentState.data == null) {
        ref
            .read(skinDetailAnalysisProvider.notifier)
            .generateAnalysis(score: widget.score);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(skinDetailAnalysisProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? theme.scaffoldBackgroundColor : Colors.white,
      appBar: AppBar(
        title: Text(
          'Detailed Skin Analysis',
          style: TextStyle(
            fontFamily: 'HelveticaNeue93',
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 카드 헤더 (아이콘 + 제목 + 설명)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: Text('🧴', style: TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Personal Skin Plan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'HelveticaNeue93',
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Quick tips based on your skin score, survey and calendar ✨',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'AI skin score: ${widget.score} / 100',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null
                  ? _buildError(state.error!, theme)
                  : _buildAnalysis(state, theme),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isLoading
            ? null
            : () {
                final now = DateTime.now();
                if (_lastRefreshTime != null &&
                    now.difference(_lastRefreshTime!).inSeconds < 60) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please try again in 1 minute.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                  return;
                }

                _lastRefreshTime = now;
                ref
                    .read(skinDetailAnalysisProvider.notifier)
                    .generateAnalysis(score: widget.score);
              },
        label: const Text('Refresh analysis'),
        icon: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildError(String message, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          const Text(
            'Failed to load analysis.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysis(SkinDetailAnalysisState state, ThemeData theme) {
    final data = state.data;

    if (data == null &&
        (state.rawText == null || state.rawText!.trim().isEmpty)) {
      return const Center(
        child: Text(
          'No analysis available yet.',
          style: TextStyle(fontSize: 14),
        ),
      );
    }

    if (data == null) {
      // JSON 파싱 실패 시 원본 텍스트 그대로 표시
      final text = state.rawText!;
      return SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? Colors.grey[900]
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[800]!
                  : Colors.grey[200]!,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ),
      );
    }

    // 액션 스텝 리스트 (Daily + Weekly를 하나의 순서 리스트로 병합)
    final List<String> steps = [
      ...data.dailyPlan.map((e) => 'Daily: $e'),
      ...data.weeklyPlan.map((e) => 'Weekly: $e'),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 요약 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[900]
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[800]!
                    : Colors.grey[200]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick summary ✨',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.overall,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'What you\'re doing well 💜',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.strengths,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'What to improve ⚠️',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.problems,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // How to use 스타일 액션 플랜
          Text(
            'Simple plan to follow:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          if (steps.isEmpty)
            Text(
              'AI could not generate a clear action plan. Try refreshing analysis.',
              style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodyMedium?.color,
              ),
            )
          else
            Column(
              children: List.generate(steps.length, (index) {
                final stepText = steps[index];
                final number = index + 1;
                final isDaily = stepText.startsWith('Daily:');
                final displayText = stepText.replaceFirst(
                  RegExp(r'^(Daily:|Weekly:)\s*'),
                  '',
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            number.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDaily ? 'Daily' : 'Weekly',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.brightness == Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayText,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}
