import 'package:flutter/material.dart';

class AIUsageTipsPage extends StatelessWidget {
  const AIUsageTipsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
            Navigator.pop(context);
          },
        ),
        title: Text(
          '100% Chatbot Usage Guide!',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontFamily: 'HelveticaNeue93',
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal[600]!, Colors.teal[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Get the most out of Puang',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'HelveticaNeue93',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Learn how to use our AI chatbot features effectively',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontFamily: 'HelveticaNeue',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Find Your Perfect Skincare 섹션
            _buildFeatureSection(
              context,
              icon: Icons.spa,
              iconColor: Colors.purple,
              title: 'Find Your Perfect Skincare',
              description:
                  'Get personalized skincare product recommendations based on your skin type and concerns.',
              steps: [
                'Complete the survey to provide your skin information',
                'Click "Find Your Perfect Skincare" card',
                'AI will analyze your skin type and recommend products',
                'Answer additional questions for more personalized recommendations',
                'View recommended products from Sephora',
              ],
            ),
            const SizedBox(height: 24),

            // Budget Routine 섹션
            _buildFeatureSection(
              context,
              icon: Icons.account_balance_wallet,
              iconColor: Colors.green,
              title: 'Budget Routine',
              description:
                  'Create a skincare routine that fits your budget. Get product recommendations within your price range.',
              steps: [
                'Complete the survey first',
                'Click "Budget Routine" card',
                'Select your budget (\$50, \$100, \$300, or \$500)',
                'AI will recommend products that fit your budget',
                'View the total cost and product details',
              ],
            ),
            const SizedBox(height: 24),

            // Tips 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber[700], size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Pro Tips',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'HelveticaNeue93',
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTipItem(
                    'Be specific in your survey answers for better recommendations',
                  ),
                  _buildTipItem(
                    'You can ask follow-up questions after getting recommendations',
                  ),
                  _buildTipItem(
                    'Try different budget ranges to see various product options',
                  ),
                  _buildTipItem(
                    'All recommended products are from Sephora.com',
                  ),
                  _buildTipItem(
                    'You can search again if you want different recommendations',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // FAQ 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.help_outline,
                        color: Colors.blue[700],
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Frequently Asked Questions',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'HelveticaNeue93',
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFAQItem(
                    'Q: Do I need to complete the survey?',
                    'A: Yes, completing the survey helps AI provide more accurate recommendations based on your skin type and concerns.',
                  ),
                  _buildFAQItem(
                    'Q: Can I change my answers?',
                    'A: You can go back and restart the survey anytime to update your information.',
                  ),
                  _buildFAQItem(
                    'Q: Are the products available for purchase?',
                    'A: All recommended products are from Sephora.com and are available for purchase.',
                  ),
                  _buildFAQItem(
                    'Q: Can I get recommendations without a budget?',
                    'A: The "Find Your Perfect Skincare" feature doesn\'t require a budget, while "Budget Routine" helps you find products within a specific price range.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureSection(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required List<String> steps,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'HelveticaNeue93',
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontFamily: 'HelveticaNeue',
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'How to use:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Helvetica',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        fontFamily: 'HelveticaNeue',
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.amber[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                fontFamily: 'HelveticaNeue',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'Helvetica',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontFamily: 'HelveticaNeue',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
