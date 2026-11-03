import 'package:flutter/material.dart';

/// 상세 설명 위젯
class DetailContent extends StatelessWidget {
  final String title;
  final String description;
  final Color color;

  const DetailContent({
    super.key,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey[700]),
        ),
      ],
    );
  }
}
