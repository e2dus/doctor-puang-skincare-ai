import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobileprogramming_groupproject_2025/api_keys.dart';
import 'package:mobileprogramming_groupproject_2025/features/skincare/presentation/viewmodels/skincare_viewmodel.dart';
import 'package:mobileprogramming_groupproject_2025/features/skincare/domain/entities/skincare_routine_entity.dart';
import 'package:dio/dio.dart';

/// 스킨케어 점수 상태
class SkincareScoreState {
  final int? score; // 0-100 점수
  final bool isLoading;
  final String? error;
  final bool hasEnoughData; // 3일 이상 데이터가 있는지
  final int daysCount; // 데이터가 있는 일수

  const SkincareScoreState({
    this.score,
    this.isLoading = false,
    this.error,
    this.hasEnoughData = false,
    this.daysCount = 0,
  });

  SkincareScoreState copyWith({
    int? score,
    bool? isLoading,
    String? error,
    bool? hasEnoughData,
    int? daysCount,
  }) {
    return SkincareScoreState(
      score: score ?? this.score,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasEnoughData: hasEnoughData ?? this.hasEnoughData,
      daysCount: daysCount ?? this.daysCount,
    );
  }
}

/// 스킨케어 점수 계산 Provider
class SkincareScoreNotifier extends Notifier<SkincareScoreState> {
  final Dio _dio = Dio();

  SkincareScoreNotifier() {
    _dio.options.baseUrl = 'https://openrouter.ai/api/v1';
    _dio.options.headers = {
      'Authorization': 'Bearer $OPENROUTER_API_KEY',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://mobileprogramming-groupproject_2025.app',
      'X-Title': 'Mobile Programming Group Project',
    };
  }

  @override
  SkincareScoreState build() {
    // 초기화 시 점수 계산 시도
    Future.microtask(() => calculateScore());

    return const SkincareScoreState();
  }

  /// 체크리스트 데이터 수집
  /// - 과거/미래 상관없이 사용자가 **실제로 체크한 날**만 기록으로 간주
  List<Map<String, dynamic>> _collectRecentData(
    Map<String, SkincareRoutineEntity> routines,
  ) {
    final List<Map<String, dynamic>> data = [];

    // 날짜순으로 정렬된 루틴 리스트 생성
    final sortedRoutines = routines.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final routine in sortedRoutines) {
      final key = _dateKey(routine.date);

      // 체크된 항목들 수집 (1개 이상 체크된 날만 기록으로 포함)
      final checkedItems = routine.checklist.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .toList();

      if (checkedItems.isEmpty) {
        continue;
      }

      data.add({
        'date': key,
        'items': checkedItems,
        'totalItems': routine.checklist.length,
        'checkedCount': checkedItems.length,
      });
    }

    return data;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// AI를 이용한 점수 계산
  Future<void> calculateScore() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final routines = ref.read(skincareRoutineProvider);
      final recentData = _collectRecentData(routines);

      // 3일 이상 데이터가 있는지 확인
      if (recentData.length < 3) {
        state = state.copyWith(
          isLoading: false,
          hasEnoughData: false,
          daysCount: recentData.length,
          error: null,
        );
        return;
      }

      state = state.copyWith(hasEnoughData: true, daysCount: recentData.length);

      // AI 프롬프트 생성
      final prompt = _buildPrompt(recentData);

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'google/gemma-3-27b-it:free',
          'messages': [
            {
              'role': 'system',
              'content':
                  '''You are a skincare routine evaluation expert. Your task is to analyze a user's skincare routine checklist data and provide a score from 0 to 100.

Evaluation Criteria:
1. Consistency (30 points): How consistently the user follows their routine
2. Completeness (30 points): How many items are checked each day
3. Variety (20 points): Diversity of skincare products used
4. Frequency (20 points): How often the routine is performed

You must respond with ONLY a number between 0 and 100, nothing else. No explanations, no text, just the number.''',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.3,
          'max_tokens': 10,
        },
      );

      final responseData = response.data;

      if (responseData == null ||
          responseData['choices'] == null ||
          (responseData['choices'] as List).isEmpty ||
          responseData['choices'][0] == null ||
          responseData['choices'][0]['message'] == null) {
        throw Exception("AI API가 유효한 응답을 반환하지 않았습니다.");
      }

      var responseText =
          responseData['choices'][0]['message']['content'] as String?;
      responseText = responseText
          ?.replaceAll(RegExp(r'<\|[^|]+\|>'), '')
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .trim();

      if (responseText == null || responseText.isEmpty) {
        throw Exception("AI API가 유효한 점수를 반환하지 않았습니다.");
      }

      // 숫자만 추출
      final scoreMatch = RegExp(r'\d+').firstMatch(responseText);
      if (scoreMatch == null) {
        throw Exception("AI 응답에서 점수를 추출할 수 없습니다: $responseText");
      }

      final score = int.tryParse(scoreMatch.group(0) ?? '0');
      if (score == null) {
        throw Exception("점수를 숫자로 변환할 수 없습니다: ${scoreMatch.group(0)}");
      }

      // 0-100 범위로 제한
      final finalScore = score.clamp(0, 100);

      state = state.copyWith(score: finalScore, isLoading: false, error: null);
    } catch (e) {
      debugPrint('스킨케어 점수 계산 오류: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// AI 프롬프트 생성
  String _buildPrompt(List<Map<String, dynamic>> data) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Here is my skincare routine checklist data for the past ${data.length} days:\n',
    );

    for (var dayData in data) {
      buffer.writeln('Date: ${dayData['date']}');
      buffer.writeln('Checked items: ${(dayData['items'] as List).join(', ')}');
      buffer.writeln('Total items available: ${dayData['totalItems']}');
      buffer.writeln(
        'Checked count: ${dayData['checkedCount']} / ${dayData['totalItems']}',
      );
      buffer.writeln('');
    }

    buffer.writeln(
      'Please evaluate my skincare routine and provide a score from 0 to 100 based on:',
    );
    buffer.writeln(
      '1. Consistency (30 points): How consistently I follow my routine',
    );
    buffer.writeln(
      '2. Completeness (30 points): How many items I check each day',
    );
    buffer.writeln(
      '3. Variety (20 points): Diversity of skincare products I use',
    );
    buffer.writeln('4. Frequency (20 points): How often I perform my routine');
    buffer.writeln(
      '\nRespond with ONLY a number between 0 and 100, nothing else.',
    );

    return buffer.toString();
  }
}

final skincareScoreProvider =
    NotifierProvider<SkincareScoreNotifier, SkincareScoreState>(() {
      return SkincareScoreNotifier();
    });
