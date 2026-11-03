import 'package:flutter/material.dart';

class ChatBotGuidePage extends StatelessWidget {
  const ChatBotGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chatbot Usage Guide',
          style: TextStyle(
            fontFamily: 'HelveticaNeue93',
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 20,
          ),
        ),
        backgroundColor: isDarkMode
            ? Theme.of(context).appBarTheme.backgroundColor
            : Colors.white,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        centerTitle: true,
      ),
      body: Container(
        color: isDarkMode
            ? Theme.of(context).scaffoldBackgroundColor
            : Colors.grey[50],
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _HeaderCard(isDarkMode: isDarkMode),
            const SizedBox(height: 16),
            _GuideSectionCard(
              isDarkMode: isDarkMode,
              icon: Icons.assignment_turned_in,
              title: '1. Skin Survey 🤔',
              description:
                  'Answer a few simple questions about your skin type and daily routine. '
                  'This helps the AI understand your skin condition.',
              steps: [
                'Go to the Chatbot tab and choose "Skin Survey".',
                'Select your main skin type and detailed skin concerns.',
                'Answer follow-up questions honestly for better results.',
              ],
            ),
            const SizedBox(height: 16),
            _GuideSectionCard(
              isDarkMode: isDarkMode,
              icon: Icons.recommend,
              title: '2. Find Your Perfect Skincare ✨',
              description:
                  'Get AI-powered product recommendations based on your survey answers.',
              steps: [
                'After completing the survey, choose "Find Your Perfect Skincare".',
                'The AI will show recommended products in a carousel.',
                'Swipe to browse products and tap a card for detailed information.',
              ],
            ),
            const SizedBox(height: 16),
            _GuideSectionCard(
              isDarkMode: isDarkMode,
              icon: Icons.attach_money,
              title: "3. What's Your Budget? 💸",
              description:
                  'Tell the AI your budget and get a simple skincare routine that fits your wallet.',
              steps: [
                'Open the Chatbot and tap "What\'s Your Budget".',
                'Choose your budget level.',
                'Check the recommended routine and total price below the products.',
              ],
            ),
            const SizedBox(height: 16),
            _GuideSectionCard(
              isDarkMode: isDarkMode,
              icon: Icons.compare_arrows,
              title: '4. Compare Products 📊',
              description:
                  'Use your liked products to compare two items side-by-side with AI.',
              steps: [
                'Like products from the Home or Detail page.',
                'Open the Chatbot and choose "Compare Products".',
                'Pick two liked products to see an AI comparison table.',
              ],
            ),
            const SizedBox(height: 24),
            _TipCard(isDarkMode: isDarkMode),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final bool isDarkMode;

  const _HeaderCard({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.teal[700] : Colors.teal[600],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Get 100% out of Puang Chatbot',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'HelveticaNeue93',
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Follow this simple guide to use all chatbot features easily.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> steps;
  final bool isDarkMode;

  const _GuideSectionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.steps,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.teal[400],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'HelveticaNeue93',
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.grey[200] : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(steps.length, (index) {
              final step = steps[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.teal[900] : Colors.teal[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        step,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              isDarkMode ? Colors.grey[200] : Colors.black87,
                        ),
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

class _TipCard extends StatelessWidget {
  final bool isDarkMode;

  const _TipCard({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You can always open the Chatbot from the bottom tab and switch between survey, recommendation, budget, and comparison anytime.',
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? Colors.grey[200] : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


