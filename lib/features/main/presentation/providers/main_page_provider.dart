import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to manage MainPage tab index
final mainPageTabIndexProvider = StateNotifierProvider<MainPageTabNotifier, int>((ref) {
  return MainPageTabNotifier();
});

class MainPageTabNotifier extends StateNotifier<int> {
  MainPageTabNotifier() : super(0);

  void setTabIndex(int index) {
    state = index;
  }
}

