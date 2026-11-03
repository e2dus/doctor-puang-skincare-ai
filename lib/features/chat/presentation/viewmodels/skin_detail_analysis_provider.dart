import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:mobileprogramming_groupproject_2025/api_keys.dart';
import 'package:mobileprogramming_groupproject_2025/features/skincare/presentation/viewmodels/skincare_viewmodel.dart';
import 'package:mobileprogramming_groupproject_2025/features/skincare/domain/entities/skincare_routine_entity.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/survey_data_provider.dart';

/// AI가 반환하는 상세 분석 구조
class SkinDetailAnalysisData {
  final String overall;
  final String strengths;
  final String problems;
  final List<String> dailyPlan;
  final List<String> weeklyPlan;

  const SkinDetailAnalysisData({
    required this.overall,
    required this.strengths,
    required this.problems,
    required this.dailyPlan,
    required this.weeklyPlan,
  });
}

/// 상태: 상세 피부 분석
class SkinDetailAnalysisState {
  final bool isLoading;
  final SkinDetailAnalysisData? data;
  final String? rawText;
  final String? error;

  const SkinDetailAnalysisState({
    this.isLoading = false,
    this.data,
    this.rawText,
    this.error,
  });

  SkinDetailAnalysisState copyWith({
    bool? isLoading,
    SkinDetailAnalysisData? data,
    String? rawText,
    String? error,
  }) {
    return SkinDetailAnalysisState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      rawText: rawText ?? this.rawText,
      error: error ?? this.error,
    );
  }
}

/// AI 기반 상세 피부 분석 Provider
class SkinDetailAnalysisNotifier extends Notifier<SkinDetailAnalysisState> {
  final Dio _dio = Dio();
  bool _isRequestInProgress = false;

  SkinDetailAnalysisNotifier() {
    _dio.options.baseUrl = 'https://openrouter.ai/api/v1';
    _dio.options.headers = {
      'Authorization': 'Bearer $OPENROUTER_API_KEY',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://mobileprogramming-groupproject_2025.app',
      'X-Title': 'Mobile Programming Group Project',
    };
  }

  @override
  SkinDetailAnalysisState build() {
    return const SkinDetailAnalysisState();
  }

  /// 설문 + 캘린더 + 점수를 기반으로 상세 분석 생성
  Future<void> generateAnalysis({required int score}) async {
    try {
      // 이미 요청 중이면 새로 호출하지 않고 기존 응답을 기다림
      if (_isRequestInProgress) {
        debugPrint('Skin detail analysis request already in progress. Skip.');
        return;
      }

      _isRequestInProgress = true;
      state = state.copyWith(isLoading: true, error: null);

      final surveyData = ref.read(surveyDataProvider);
      final routines = ref.read(skincareRoutineProvider);

      final calendarSummary = _buildCalendarSummary(routines);
      final surveySummary = _buildSurveySummary(surveyData);

      final prompt = _buildPrompt(
        score: score,
        surveySummary: surveySummary,
        calendarSummary: calendarSummary,
      );

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'google/gemma-3-27b-it:free',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a professional skincare coach.

Your job is to analyze the user's skin condition and routine based on:
- Their survey answers about skin type and concerns
- The products they use (from calendar checklist)
- Their current AI skin score (0-100)

CRITICAL RULES:
- Always respond in ENGLISH.
- Be short, clear and practical.
- NEVER use markdown or bullet symbols like *, -, • inside the JSON values.
- You MUST return ONLY valid JSON. No extra text before or after the JSON.
- JSON keys and structure MUST match exactly the specification the user gives you.
''',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.5,
          'max_tokens': 600,
        },
      );

      final responseData = response.data;
      if (responseData == null ||
          responseData['choices'] == null ||
          (responseData['choices'] as List).isEmpty ||
          responseData['choices'][0] == null ||
          responseData['choices'][0]['message'] == null) {
        throw Exception('AI API did not return a valid response.');
      }

      var responseText =
          responseData['choices'][0]['message']['content'] as String?;
      responseText = responseText
          ?.replaceAll(RegExp(r'<\|[^|]+\|>'), '')
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .trim();

      if (responseText == null || responseText.isEmpty) {
        throw Exception('AI API did not return analysis text.');
      }

      SkinDetailAnalysisData? parsed;
      try {
        // ```json ... ``` 같은 코드 블록이나 앞뒤 텍스트가 섞여 있을 수 있으므로
        // 순수 JSON 객체 부분만 추출해서 파싱
        final jsonString = _extractJsonObject(responseText);
        final decoded = jsonDecode(jsonString);
        if (decoded is Map<String, dynamic>) {
          final overall = (decoded['overall'] as String?) ?? '';
          final strengths = (decoded['strengths'] as String?) ?? '';
          final problems = (decoded['problems'] as String?) ?? '';
          final daily =
              (decoded['daily_plan'] as List?)?.map((e) => '$e').toList() ?? [];
          final weekly =
              (decoded['weekly_plan'] as List?)?.map((e) => '$e').toList() ??
              [];

          parsed = SkinDetailAnalysisData(
            overall: overall,
            strengths: strengths,
            problems: problems,
            dailyPlan: daily,
            weeklyPlan: weekly,
          );
        } else {
          debugPrint('Skin detail analysis JSON is not a Map: $decoded');
        }
      } catch (e) {
        debugPrint('Failed to parse skin detail analysis JSON: $e');
      }

      state = state.copyWith(
        isLoading: false,
        data: parsed,
        rawText: responseText,
        error: null,
      );
    } catch (e) {
      debugPrint('Skin detail analysis error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      _isRequestInProgress = false;
    }
  }

  /// 캘린더 루틴 요약 생성 (체크된 날 위주)
  String _buildCalendarSummary(Map<String, SkincareRoutineEntity> routines) {
    if (routines.isEmpty) {
      return 'No skincare routine data recorded in the calendar.';
    }

    final buffer = StringBuffer();
    buffer.writeln('Calendar routine summary:');

    final sorted = routines.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    int recordedDays = 0;

    for (final routine in sorted) {
      final dateKey = _dateKey(routine.date);
      final checkedItems = routine.checklist.entries
          .where((e) => e.value == true)
          .map((e) => e.key)
          .toList();

      if (checkedItems.isEmpty) {
        continue;
      }

      recordedDays++;
      buffer.writeln(
        '- $dateKey: checked ${checkedItems.length} items (${checkedItems.join(', ')})',
      );
    }

    if (recordedDays == 0) {
      return 'No days with checked skincare items in the calendar.';
    }

    buffer.writeln('Total recorded days with skincare routine: $recordedDays');
    return buffer.toString();
  }

  /// 설문 요약 생성
  String _buildSurveySummary(SurveyData survey) {
    final buffer = StringBuffer();
    buffer.writeln('Survey summary:');

    if (survey.primaryType != null) {
      buffer.writeln('- Primary skin type: ${survey.primaryType}');
    }
    if (survey.secondaryType != null) {
      buffer.writeln('- Secondary/condition: ${survey.secondaryType}');
    }
    if (survey.categories.isNotEmpty) {
      buffer.writeln(
        '- Product categories used: ${survey.categories.join(', ')}',
      );
    }
    if (survey.questionAnswers.isNotEmpty) {
      buffer.writeln('- Additional Q&A:');
      for (final qa in survey.questionAnswers) {
        final q = qa['question'] ?? '';
        final a = qa['answer'] ?? '';
        if (q.isEmpty && a.isEmpty) continue;
        buffer.writeln('  • Q: $q');
        buffer.writeln('    A: $a');
      }
    }

    if (buffer.toString().trim() == 'Survey summary:') {
      return 'No survey data available.';
    }

    return buffer.toString();
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 응답 텍스트에서 첫 번째 JSON 객체({ ... })만 깔끔하게 추출
  String _extractJsonObject(String text) {
    // ```json 코드 블록 제거
    var cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      // ```json 또는 ``` 로 시작하는 경우
      final firstNewline = cleaned.indexOf('\n');
      if (firstNewline != -1) {
        cleaned = cleaned.substring(firstNewline + 1);
      }
      // 마지막 ``` 제거
      final lastFence = cleaned.lastIndexOf('```');
      if (lastFence != -1) {
        cleaned = cleaned.substring(0, lastFence).trim();
      }
    }

    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');

    if (start != -1 && end != -1 && end > start) {
      return cleaned.substring(start, end + 1);
    }

    // 실패 시 원본 반환 (jsonDecode 단계에서 에러 처리)
    return cleaned;
  }

  /// 최종 프롬프트 생성
  String _buildPrompt({
    required int score,
    required String surveySummary,
    required String calendarSummary,
  }) {
    return '''
Here is the user's current skin information.

AI skin score: $score (0-100, higher is better)

$surveySummary

$calendarSummary

You MUST respond with ONLY a single JSON object in this exact format (no extra text):
{
  "overall": "short paragraph about overall skin condition",
  "strengths": "short paragraph about good points in the current routine",
  "problems": "short paragraph about problems and what needs improvement",
  "daily_plan": [
    "short, clear daily action item 1",
    "short, clear daily action item 2",
    "short, clear daily action item 3"
  ],
  "weekly_plan": [
    "short, clear weekly action item 1",
    "short, clear weekly action item 2"
  ]
}

Each string should be natural English sentences (no numbering like 1), 2) inside the text).
Be specific but concise. Focus on what the user should change or keep doing.
''';
  }
}

final skinDetailAnalysisProvider =
    NotifierProvider<SkinDetailAnalysisNotifier, SkinDetailAnalysisState>(
      () => SkinDetailAnalysisNotifier(),
    );
