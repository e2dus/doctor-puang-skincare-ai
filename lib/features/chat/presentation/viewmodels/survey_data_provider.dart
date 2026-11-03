import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

const _storage = FlutterSecureStorage();

// 사용자별로 survey_data를 저장하기 위한 키 생성 함수
Future<String> _getSurveyDataKey() async {
  final userEmail = await _storage.read(key: 'user_email');
  if (userEmail != null && userEmail.isNotEmpty) {
    return 'survey_data_$userEmail';
  }
  return 'survey_data'; // fallback to old key if no user email
}

/// 설문 데이터 모델
class SurveyData {
  final String? primaryType; // 피부 타입
  final String? secondaryType; // 세부 타입
  final List<String> categories; // 화장품 카테고리
  final List<Map<String, String>> questionAnswers; // 질문과 답변

  const SurveyData({
    this.primaryType,
    this.secondaryType,
    this.categories = const [],
    this.questionAnswers = const [],
  });

  SurveyData copyWith({
    String? primaryType,
    String? secondaryType,
    List<String>? categories,
    List<Map<String, String>>? questionAnswers,
  }) {
    return SurveyData(
      primaryType: primaryType ?? this.primaryType,
      secondaryType: secondaryType ?? this.secondaryType,
      categories: categories ?? this.categories,
      questionAnswers: questionAnswers ?? this.questionAnswers,
    );
  }

  bool get isComplete => 
      primaryType != null && 
      categories.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'primaryType': primaryType,
    'secondaryType': secondaryType,
    'categories': categories,
    'questionAnswers': questionAnswers,
  };

  factory SurveyData.fromJson(Map<String, dynamic> json) {
    return SurveyData(
      primaryType: json['primaryType'] as String?,
      secondaryType: json['secondaryType'] as String?,
      categories: (json['categories'] as List<dynamic>?)?.cast<String>() ?? [],
      questionAnswers: (json['questionAnswers'] as List<dynamic>?)?.map((e) => Map<String, String>.from(e as Map)).toList() ?? [],
    );
  }
}

/// 설문 데이터 Notifier
class SurveyDataNotifier extends StateNotifier<SurveyData> {
  SurveyDataNotifier() : super(const SurveyData()) {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final key = await _getSurveyDataKey();
      final jsonStr = await _storage.read(key: key);
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        state = SurveyData.fromJson(json);
      }
    } catch (e) {
      // 로드 실패 시 기본 상태 유지
    }
  }

  Future<void> _saveData() async {
    try {
      final key = await _getSurveyDataKey();
      final jsonStr = jsonEncode(state.toJson());
      await _storage.write(key: key, value: jsonStr);
    } catch (e) {
      // 저장 실패 시 무시
    }
  }

  void setPrimaryType(String? type) {
    state = state.copyWith(primaryType: type);
    _saveData();
  }

  void setSecondaryType(String? type) {
    state = state.copyWith(secondaryType: type);
    _saveData();
  }

  void setCategories(List<String> categories) {
    state = state.copyWith(categories: categories);
    _saveData();
  }

  void setQuestionAnswers(List<Map<String, String>> answers) {
    state = state.copyWith(questionAnswers: answers);
    _saveData();
  }

  void addQuestionAnswer(String question, String answer) {
    final newAnswers = List<Map<String, String>>.from(state.questionAnswers);
    newAnswers.add({'question': question, 'answer': answer});
    state = state.copyWith(questionAnswers: newAnswers);
    _saveData();
  }

  Future<void> clear() async {
    state = const SurveyData();
    final key = await _getSurveyDataKey();
    await _storage.delete(key: key);
  }

  // 데이터 리로드 (로그인 후 호출)
  Future<void> reload() async {
    await _loadData();
  }
}

/// 설문 데이터 Provider
final surveyDataProvider = StateNotifierProvider<SurveyDataNotifier, SurveyData>(
  (ref) => SurveyDataNotifier(),
);

