import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/survey_message_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/survey_data_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/typing_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/widgets/message_bubble.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/widgets/typing_indicator.dart';

class ChatSurveyPage extends ConsumerStatefulWidget {
  const ChatSurveyPage({super.key});

  @override
  ConsumerState<ChatSurveyPage> createState() => _ChatSurveyPageState();
}

class _ChatSurveyPageState extends ConsumerState<ChatSurveyPage> {
  final ScrollController _scrollController = ScrollController();
  final String chatId = 'chatbot_survey'; // 설문 전용 챗 ID
  bool _hasNavigatedBack = false; // 이미 뒤로 갔는지 추적
  bool _hasStartedSurvey = false;

  @override
  void initState() {
    super.initState();
    // 페이지가 열리면 설문 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasStartedSurvey) {
        _hasStartedSurvey = true;
        _startSurvey();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 설문 조사 시작
  void _startSurvey() {
    // 설문 데이터와 메시지 모두 초기화 (처음부터 다시 시작)
    ref.read(surveyDataProvider.notifier).clear();
    ref.read(surveyMessageProvider(chatId).notifier).clearMessages();

    // 설문 시작
    ref.read(surveyMessageProvider(chatId).notifier).startSurvey();
  }

  void _scrollToBottom() {
    if (mounted && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final surveyMessages = ref.watch(surveyMessageProvider(chatId));
    final isTyping = ref.watch(isTypingProvider(chatId));

    // 메시지가 변경될 때만 스크롤 (ref.listen 사용)
    ref.listen(
      surveyMessageProvider(chatId),
      (previous, next) {
        if (previous != null && next.length > previous.length && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scrollController.hasClients) {
              _scrollToBottom();
            }
          });
        }
      },
    );

    // 설문 완료 감지 (ref.listen 사용)
    ref.listen(
      surveyMessageProvider(chatId),
      (previous, next) {
        // 감사 메시지가 있는지 확인
        final hasThankYouMessage = next.any(
          (m) => m.text == 'Thank you for your answers!' || m.text == '알려주셔서 감사합니다!'
        );
        
        // 이전에는 없었는데 지금 생겼고, 아직 뒤로 가지 않았다면
        final hadThankYouMessage = previous?.any(
          (m) => m.text == 'Thank you for your answers!' || m.text == '알려주셔서 감사합니다!'
        ) ?? false;
        
        if (hasThankYouMessage && !hadThankYouMessage && !_hasNavigatedBack) {
          _hasNavigatedBack = true;
          // 2초 후 뒤로가기
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      },
    );

    // 마지막 메시지가 "Searching"인지 확인
    final isSearching = surveyMessages.isNotEmpty && 
                       surveyMessages.last.text == 'Searching' && 
                       !surveyMessages.last.isMe;

    // "Searching" 메시지가 있으면 typing indicator를 표시하지 않음
    final shouldShowTyping = isTyping && !isSearching;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDarkMode
            ? Theme.of(context).appBarTheme.backgroundColor
            : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () {
            // 설문 메시지 초기화
            ref.read(surveyMessageProvider(chatId).notifier).clearMessages();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Skin Survey',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontFamily: 'HelveticaNeue93',
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Column(
        children: [
          // 메시지 리스트
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: surveyMessages.length + (shouldShowTyping ? 1 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (context, index) {
                if (index == surveyMessages.length && shouldShowTyping) {
                  return const TypingIndicator();
                }
                return MessageBubble(
                  message: surveyMessages[index],
                  chatId: chatId,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

