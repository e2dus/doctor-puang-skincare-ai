import 'package:flutter/material.dart';

class FriendsScoreList extends StatelessWidget {
  final List<Map<String, dynamic>> friends;

  const FriendsScoreList({super.key, required this.friends});

  @override
  Widget build(BuildContext context) {
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
          const Text(
            "What are your friends' scores?",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFamily: 'HelveticaNeue93',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...friends.map(
            (friend) => _FriendScoreItem(
              name: friend['name'] as String,
              score: friend['score'] as int,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendScoreItem extends StatelessWidget {
  final String name;
  final int score;

  const _FriendScoreItem({required this.name, required this.score});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
            child: Icon(Icons.person, color: Colors.grey[600], size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Helvetica',
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$score points',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
