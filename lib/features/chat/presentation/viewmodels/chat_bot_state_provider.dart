import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ChatBotPage의 상태를 관리하는 Notifier
class ChatBotStateNotifier extends StateNotifier<bool> {
  ChatBotStateNotifier() : super(false);

  void setHasStartedChat(bool value) {
    state = value;
  }
}

/// ChatBotPage의 상태를 관리하는 Provider
/// AppBar에서 뒤로가기 버튼 표시 여부를 결정하기 위해 사용
final chatBotStateProvider = StateNotifierProvider<ChatBotStateNotifier, bool>(
  (ref) => ChatBotStateNotifier(),
);

