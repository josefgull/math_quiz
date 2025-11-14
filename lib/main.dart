import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/credentials.dart'; 

import 'level_screen.dart';
import 'questions/l1_pm.dart';
import 'questions/fractions.dart';
import 'questions/roots.dart';
import 'questions/exponentials.dart';

final Map<int, List<Map<String, dynamic>>> questionPacks = {
  1: plusMinus,
  2: fractionsQuestions,
  3: rootsQuestions,
  4: exponentialsQuestions,
};

final List<String> topics = [
  'Plus/Minus',
  'Fractions',
  'Roots',
  'Exponentials',
];


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const MathQuizApp());
}

class MathQuizApp extends StatefulWidget {
  const MathQuizApp({super.key});

  @override
  State<MathQuizApp> createState() => _MathQuizAppState();
}

class _MathQuizAppState extends State<MathQuizApp> {
  Map<int, int> highScores = {};
  int? selectedLevel;

  @override
  void initState() {
    super.initState();
    // Initialize all highscores to 0 for each topic
    highScores = {for (int i = 1; i <= topics.length; i++) i: 0};
    loadHighScores();
  }

  Future<void> loadHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var level in questionPacks.keys) {
        highScores[level] = prefs.getInt('highscore_level_$level') ?? 0;
      }
    });
  }

  void startLevel(int level) {
    setState(() {
      selectedLevel = level;
    });
  }

  void onQuizFinished(int score) {
    if (selectedLevel != null) {
      setState(() {
        highScores[selectedLevel!] = 
            max(highScores[selectedLevel!] ?? 0, score);
        selectedLevel = null; // go back to level screen
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Quiz',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: selectedLevel == null
          ? LevelScreen(
            highScores: highScores,
            onLevelSelected: startLevel,
            topics: topics,
            questionPacks: questionPacks,
            )
          : QuizPage(
            level: selectedLevel!,
            onFinished: onQuizFinished,
            onRestart: () {
              setState(() {
                selectedLevel = null; // go back to level screen
              });
            },
          ),
    );
  }
}

class QuizPage extends StatefulWidget {
  final int level;
  final void Function(int score) onFinished;
  final VoidCallback onRestart;

  const QuizPage({
    super.key,
    required this.level,
    required this.onFinished,
    required this.onRestart,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage>{
  int score = 0;
  int currentQuestion = 0;
  int? selectedAnswerIndex;
  bool showCorrect = false;
  bool wasCorrect = false;
  bool inputLocked = false;

  // BannerAd
  late BannerAd myBanner;

  // Shuffled questions list
  late List<Map<String, dynamic>> shuffledQuestions;

  // Shuffled answers for current question
  late List<String> shuffledAnswers;

  @override
  void initState() {
    super.initState();

    // Initialize banner
    myBanner = BannerAd(
      adUnitId: Config.admobBannerIdAndroid, 
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => print('Ad loaded.'),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Ad failed to load: $error');
        },
      ),
    );
    myBanner.load();

    // Shuffle questions at the start
    shuffledQuestions = List.from(questionPacks[widget.level]!)..shuffle();

    // Shuffle answers for the first question
    shuffleAnswers();
  }

  void shuffleAnswers() {
    final currentQ = shuffledQuestions[currentQuestion];
    shuffledAnswers = List.from(currentQ['answers'])..shuffle();
  }

  void checkAnswer(String selectedAnswer) {
    if (inputLocked) return;
    inputLocked = true;

    final currentQ = shuffledQuestions[currentQuestion];
    final correctAnswer = currentQ['answers'][currentQ['correct'] - 1];

    setState(() {
      selectedAnswerIndex = shuffledAnswers.indexOf(selectedAnswer);
      showCorrect = true;
      wasCorrect = (selectedAnswer == correctAnswer);
    });

    if (wasCorrect) {
      score++;
      saveHighScore();
      // Correct → go immediately to next question
      goToNextQuestion();
    } else {
      // Wrong → wait for user to press "Continue"
      setState(() {
        inputLocked = false;
      });
    }
  }

  Future<void> saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    final currentHighScore =
        prefs.getInt('highscore_level_${widget.level}') ?? 0;
    if (score > currentHighScore) {
      await prefs.setInt('highscore_level_${widget.level}', score);
    }
  }

  void goToNextQuestion() {
    setState(() {
      currentQuestion++;
      selectedAnswerIndex = null;
      showCorrect = false;
      wasCorrect = false;
      inputLocked = false;

      if (currentQuestion < shuffledQuestions.length) {
        shuffleAnswers();
      }
    });
  }

  Color buttonColor(int index) {
    final currentQ = shuffledQuestions[currentQuestion];
    final correctAnswer = currentQ['answers'][currentQ['correct'] - 1];
    final answer = shuffledAnswers[index];

    if (!showCorrect) return const Color.fromARGB(255, 172, 223, 199);
    if (answer == correctAnswer) return const Color.fromARGB(255, 149, 235, 152); // correct
    if (index == selectedAnswerIndex) return const Color.fromARGB(255, 228, 178, 174); // wrong
    return const Color.fromARGB(255, 172, 223, 199);
  }

  @override
  void dispose() {
    myBanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentQuestion >= shuffledQuestions.length) {
      return finishScreen();
    }
    final question = shuffledQuestions[currentQuestion];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 108, 153, 166),
      appBar: AppBar(
        title: const Text('Math Quiz'),
        backgroundColor: const Color.fromARGB(255, 172, 223, 199),
        leading: IconButton(
          icon: Image.asset('assets/icons/app_icon.png'),
          onPressed: widget.onRestart,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Math.tex(
              question['question']!,
              textStyle: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ...List.generate(shuffledAnswers.length, (index) {
              final answer = shuffledAnswers[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ElevatedButton(
                  onPressed:
                      inputLocked ? null : () => checkAnswer(answer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor(index),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(answer),
                ),
              );
            }),
            if (showCorrect && !wasCorrect)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: goToNextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color.fromARGB(255, 172, 223, 199),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text('Score: $score'),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: myBanner.size.height.toDouble(),
        child: AdWidget(ad: myBanner),
      ),
    );
  }

  Widget finishScreen() {
    final currentPack = shuffledQuestions;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 108, 153, 166),
      appBar: AppBar(
        title: const Text('Quiz Finished'),
        backgroundColor: const Color.fromARGB(255, 172, 223, 199),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Final Score: $score / ${currentPack.length}',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                widget.onFinished(score);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 172, 223, 199),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
              child: const Text(
                'Back to Levels',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

