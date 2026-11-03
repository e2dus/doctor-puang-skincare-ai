import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pages/chat_bot_guide_page.dart';
import '../../../../features/main/presentation/providers/main_page_provider.dart';

class DailyTipsCarousel extends ConsumerStatefulWidget {
  final List<Map<String, String>> tips;

  const DailyTipsCarousel({super.key, required this.tips});

  @override
  ConsumerState<DailyTipsCarousel> createState() => _DailyTipsCarouselState();
}

class _DailyTipsCarouselState extends ConsumerState<DailyTipsCarousel> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85, initialPage: 0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                "Today's Tips!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'HelveticaNeue93',
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  widget.tips.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: (_currentPage % widget.tips.length) == index ? 8 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: (_currentPage % widget.tips.length) == index
                          ? Colors.grey[800]
                          : Colors.grey[400],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 24),
          child: SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _pageController,
              padEnds: false,
              clipBehavior: Clip.none,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: 1000,
              itemBuilder: (context, index) {
                final actualIndex = index % widget.tips.length;
                final tip = widget.tips[actualIndex];
                return Padding(
                  padding: const EdgeInsets.only(right: 40),
                  child: GestureDetector(
                    onTap: () {
                      // 첫 번째 카드(Enter in calendar!)를 눌렀을 때 MainPage의 Calendar 탭(index 2)으로 변경
                      if (actualIndex == 0) {
                        ref.read(mainPageTabIndexProvider.notifier).setTabIndex(2);
                      }
                      // 두 번째 카드(100% Chatbot Usage Guide)를 눌렀을 때 가이드 페이지로 이동
                      else if (actualIndex == 1) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ChatBotGuidePage(),
                          ),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: actualIndex == 0
                            ? Colors.green[700]
                            : Colors.teal[600],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  tip['title']!,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'HelveticaNeue93',
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  tip['subtitle']!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward,
                              color: actualIndex == 0
                                  ? Colors.green[700]
                                  : Colors.teal[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
