import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'menu.dart';
import 'styles.dart';
//import 'config/credentials.dart'; test

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
  Map<String, int> highScores = {};

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Quiz',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Builder(
        builder: (context) => FolderMenuScreen(
          rootFolder: rootMenu,
          onLevelSelected: (fileNode) {
            final questions = fileNode.getQuestions();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QuizPageWithQuestions(
                  questions: questions,
                  onFinished: (score) {
                    // optionally handle highscore here
                  },
                  onRestart: () => Navigator.pop(context),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class QuizPageWithQuestions extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final void Function(int score) onFinished;
  final VoidCallback onRestart;

  const QuizPageWithQuestions({
    super.key,
    required this.questions,
    required this.onFinished,
    required this.onRestart,
  });

  @override
  State<QuizPageWithQuestions> createState() => _QuizPageWithQuestionsState();
}

class _QuizPageWithQuestionsState extends State<QuizPageWithQuestions> {
  late List<Map<String, dynamic>> shuffledQuestions;
  int currentQuestion = 0;
  int score = 0;
  String? selectedAnswer;
  List<String> shuffledAnswers = [];
  bool showCorrect = false;
  bool waitForContinue = false; // true only for wrong answers
  late BannerAd myBanner;
  bool isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    shuffledQuestions = List.from(widget.questions)..shuffle();
    shuffleAnswers();

      // Banner initialisieren
    myBanner = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',//Config.admobBannerIdAndroid,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => isAdLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Ad failed to load: $error');
        },
      ),
    );
    myBanner.load();
  }

  @override
  void dispose() {
    myBanner.dispose();
    super.dispose();
  }

  void shuffleAnswers() {
    final question = shuffledQuestions[currentQuestion];
    shuffledAnswers = List<String>.from(question['answers'])..shuffle();
  }

  void selectAnswer(String answer) {
    if (selectedAnswer != null) return;

    final correctAnswer = shuffledQuestions[currentQuestion]['correct'];

    setState(() {
      selectedAnswer = answer;
      showCorrect = true;
      waitForContinue = answer != correctAnswer;
      if (answer == correctAnswer) score++;
    });

    if (!waitForContinue) {
      // Correct → automatically go to next after 0.5s
      Future.delayed(const Duration(milliseconds: 500), goToNextQuestion);
    }
  }

  void goToNextQuestion() {
    setState(() {
      currentQuestion++;
      selectedAnswer = null;
      showCorrect = false;
      waitForContinue = false;
      if (currentQuestion < shuffledQuestions.length) shuffleAnswers();
    });
  }

  Color getButtonColor(String answer) {
    if (!showCorrect) return AppColors.buttonDefault;

    final correctAnswer = shuffledQuestions[currentQuestion]['correct'];

    // Correct answer selected → highlight green, others default
    if (!waitForContinue && answer == correctAnswer) return AppColors.buttonCorrect;
    if (!waitForContinue) return AppColors.buttonDefault;

    // Wrong answer selected → correct green, selected red, others default
    if (answer == correctAnswer) return AppColors.buttonCorrect;
    if (answer == selectedAnswer) return AppColors.buttonWrong;
    return AppColors.buttonDefault;
  }

  @override
  Widget build(BuildContext context) {
    if (currentQuestion >= shuffledQuestions.length) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
            title: const Text('Quiz Finished'),
            backgroundColor: AppColors.appBar),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Final Score: $score / ${shuffledQuestions.length}'),
              const SizedBox(height: 20)
            ],
          ),
        ),
      );
    }

    final question = shuffledQuestions[currentQuestion];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: Text('Question ${currentQuestion + 1}'),
          backgroundColor: AppColors.appBar),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Math.tex(
              question['question'],
              textStyle: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ...shuffledAnswers.map(
              (answer) => Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16),
                child: ElevatedButton(
                  onPressed: () => selectAnswer(answer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getButtonColor(answer),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Math.tex(
                    answer,
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
            if (waitForContinue && showCorrect)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: goToNextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonDefault,
                    padding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                ),
              ),
          ],
        ),
      ),  
      bottomNavigationBar: isAdLoaded
      ? SizedBox(
          height: myBanner.size.height.toDouble(),
          child: AdWidget(ad: myBanner),
        )
      : null,
    );
  }
}
