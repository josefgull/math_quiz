import 'package:flutter/material.dart';

class LevelScreen extends StatelessWidget {
  final Map<int, int> highScores; // level -> high score
  final void Function(int level) onLevelSelected;
  final List<String> topics; // added field
  final Map<int, List<Map<String, dynamic>>> questionPacks;


  const LevelScreen({
    super.key,
    required this.highScores,
    required this.onLevelSelected,
    required this.topics,
    required this.questionPacks,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 108, 153, 166), // NEW: background color
      appBar: AppBar(
        title: const Text('Select Topic'),
        backgroundColor: const Color.fromARGB(255, 172, 223, 199),
        ),
      body: ListView.builder(
        itemCount: topics.length, // use length of topics
        itemBuilder: (context, index) {
          final level = index + 1;
          final topicName = topics[index];
          final score = highScores[level] ?? 0;
          final maxScore = questionPacks[level]!.length;
          final isPerfect = score == maxScore;

          return ListTile(
            title: Text(topicName),
            subtitle: Text('Highscore: $score / $maxScore'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPerfect) const Icon(Icons.star, color: Colors.amber),
                const Icon(Icons.arrow_forward),
              ],
            ),
            tileColor: isPerfect
                ? Colors.green[200] // highlight perfect levels
                : const Color.fromARGB(255, 172, 223, 199),
            onTap: () => onLevelSelected(level),
          );
        },
      ),
    );
  }
}
