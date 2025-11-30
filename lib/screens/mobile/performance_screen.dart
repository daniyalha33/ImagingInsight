// lib/screens/mobile/performance_screen.dart
import 'package:flutter/material.dart';

class LeaderboardUser {
  final int rank;
  final String name;
  final String avatar;
  final int score;
  final bool isCurrentUser;

  LeaderboardUser({
    required this.rank,
    required this.name,
    required this.avatar,
    required this.score,
    this.isCurrentUser = false,
  });
}

class PerformanceScreen extends StatelessWidget {
  final String userName;

  const PerformanceScreen({
    Key? key,
    required this.userName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final leaderboard = [
      LeaderboardUser(
        rank: 1,
        name: 'Daniel',
        avatar: 'D',
        score: 300,
      ),
      LeaderboardUser(
        rank: 2,
        name: 'Musads',
        avatar: 'M',
        score: 200,
      ),
      LeaderboardUser(
        rank: 3,
        name: userName,
        avatar: userName.substring(0, 1).toUpperCase(),
        score: 180,
        isCurrentUser: true,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.blue.shade100),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2463EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.show_chart,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Performance',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leaderboard Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '🏆',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Leaderboard',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: const [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '300P',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2463EB),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Leaderboard Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      children: leaderboard.asMap().entries.map((entry) {
                        final index = entry.key;
                        final user = entry.value;
                        final isLast = index == leaderboard.length - 1;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: user.isCurrentUser
                                ? const Color(0xFFEFF6FF)
                                : Colors.white,
                            border: !isLast
                                ? Border(
                                    bottom: BorderSide(
                                      color: Colors.blue.shade100,
                                    ),
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              // Rank
                              SizedBox(
                                width: 32,
                                child: Text(
                                  '${user.rank}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: user.rank <= 3
                                        ? const Color(0xFF2463EB)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Avatar
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: user.isCurrentUser
                                      ? const Color(0xFF2463EB)
                                      : const Color(0xFFDBEAFE),
                                  shape: BoxShape.circle,
                                  border: user.isCurrentUser
                                      ? Border.all(
                                          color: const Color(0xFF2463EB),
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    user.avatar,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: user.isCurrentUser
                                          ? Colors.white
                                          : const Color(0xFF2463EB),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Name and Badge
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      user.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: user.isCurrentUser
                                            ? const Color(0xFF1E40AF)
                                            : const Color(0xFF1E293B),
                                      ),
                                    ),
                                    if (user.isCurrentUser) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDBEAFE),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'You',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1E40AF),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Score
                              Text(
                                '${user.score}P',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2463EB),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Your Stats
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Tests Completed',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '12',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Average Score',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '87%',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2463EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}