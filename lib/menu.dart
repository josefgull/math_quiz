// lib/menu.dart
import 'package:flutter/material.dart';
import 'styles.dart';
// Import all question files
import 'questions/Algebra/Complex_numbers_questions.dart';
import 'questions/Algebra/Exponents_and_logarithms_questions.dart';
import 'questions/Algebra/Linear_equations_questions.dart';
import 'questions/Algebra/Partial_fractions_questions.dart';
import 'questions/Algebra/Polynomials_questions.dart';
import 'questions/Algebra/Quadratic_equations_questions.dart';
import 'questions/Arithmetic_Number_Theory/Basic_operations_questions.dart';
import 'questions/Arithmetic_Number_Theory/Fractions_and_ratios_questions.dart';
import 'questions/Arithmetic_Number_Theory/Number_properties_questions.dart';
import 'questions/Arithmetic_Number_Theory/Squares_and_roots_questions.dart';
import 'questions/Calculus/Applications_questions.dart';
import 'questions/Calculus/Differentiation_questions.dart';
import 'questions/Calculus/Integration_questions.dart';
import 'questions/Geometry_and_Trigonometry/Coordinate_geometry_questions.dart';
import 'questions/Geometry_and_Trigonometry/Plane_geometry_questions.dart';
import 'questions/Geometry_and_Trigonometry/Solid_geometry_questions.dart';
import 'questions/Geometry_and_Trigonometry/Trigonometry_questions.dart';
import 'questions/Probability_and_Statistics/Distributions_questions.dart';
import 'questions/Probability_and_Statistics/Probability_questions.dart';
import 'questions/Probability_and_Statistics/Statistics_questions.dart';
import 'questions/Vectors_and_Linear_Algebra/Matrices_and_determinants_questions.dart';
import 'questions/Vectors_and_Linear_Algebra/Vector_calculations_questions.dart';
import 'questions/Vectors_and_Linear_Algebra/Vector_calculus_questions.dart';
import 'questions/arithmetic/l1_pm.dart';
import 'questions/else/exponentials.dart';
import 'questions/else/fractions.dart';
import 'questions/else/roots.dart';

/// Leaf node: a file representing a level/quiz
class FileNode {
  final String name;
  final List<Map<String, dynamic>> Function() getQuestions;
  const FileNode({required this.name, required this.getQuestions});
}

/// Recursive folder structure
class Folder {
  final String name;
  final List<Folder> subfolders;
  final List<FileNode> files;

  const Folder({
    required this.name,
    this.subfolders = const [],
    this.files = const [],
  });
}

/// Build your static folder tree
final Folder rootMenu = Folder(
  name: 'questions',
  subfolders: [
    Folder(
      name: 'Algebra',
      files: [
        FileNode(name: 'Complex numbers questions', getQuestions: () => Complex_numbers_questionsQuestions),
        FileNode(name: 'Exponents and logarithms questions', getQuestions: () => Exponents_and_logarithms_questionsQuestions),
        FileNode(name: 'Linear equations questions', getQuestions: () => Linear_equations_questionsQuestions),
        FileNode(name: 'Partial fractions questions', getQuestions: () => Partial_fractions_questionsQuestions),
        FileNode(name: 'Polynomials questions', getQuestions: () => Polynomials_questionsQuestions),
        FileNode(name: 'Quadratic equations questions', getQuestions: () => Quadratic_equations_questionsQuestions),
      ],
    ),
    Folder(
      name: 'Arithmetic_Number_Theory',
      files: [
        FileNode(name: 'Basic operations questions', getQuestions: () => Basic_operations_questionsQuestions),
        FileNode(name: 'Fractions and ratios questions', getQuestions: () => Fractions_and_ratios_questionsQuestions),
        FileNode(name: 'Number properties questions', getQuestions: () => Number_properties_questionsQuestions),
        FileNode(name: 'Squares and roots questions', getQuestions: () => Squares_and_roots_questionsQuestions),
      ],
    ),
    Folder(
      name: 'Calculus',
      files: [
        FileNode(name: 'Applications questions', getQuestions: () => Applications_questionsQuestions),
        FileNode(name: 'Differentiation questions', getQuestions: () => Differentiation_questionsQuestions),
        FileNode(name: 'Integration questions', getQuestions: () => Integration_questionsQuestions),
      ],
    ),
    Folder(
      name: 'Geometry_and_Trigonometry',
      files: [
        FileNode(name: 'Coordinate geometry questions', getQuestions: () => Coordinate_geometry_questionsQuestions),
        FileNode(name: 'Plane geometry questions', getQuestions: () => Plane_geometry_questionsQuestions),
        FileNode(name: 'Solid geometry questions', getQuestions: () => Solid_geometry_questionsQuestions),
        FileNode(name: 'Trigonometry questions', getQuestions: () => Trigonometry_questionsQuestions),
      ],
    ),
    Folder(
      name: 'Probability_and_Statistics',
      files: [
        FileNode(name: 'Distributions questions', getQuestions: () => Distributions_questionsQuestions),
        FileNode(name: 'Probability questions', getQuestions: () => Probability_questionsQuestions),
        FileNode(name: 'Statistics questions', getQuestions: () => Statistics_questionsQuestions),
      ],
    ),
    Folder(
      name: 'Vectors_and_Linear_Algebra',
      files: [
        FileNode(name: 'Matrices and determinants questions', getQuestions: () => Matrices_and_determinants_questionsQuestions),
        FileNode(name: 'Vector calculations questions', getQuestions: () => Vector_calculations_questionsQuestions),
        FileNode(name: 'Vector calculus questions', getQuestions: () => Vector_calculus_questionsQuestions),
      ],
    ),
    Folder(
      name: 'arithmetic',
      files: [
        FileNode(name: 'l1 pm', getQuestions: () => l1_pmQuestions),
      ],
    ),
    Folder(
      name: 'else',
      files: [
        FileNode(name: 'exponentials', getQuestions: () => exponentialsQuestions),
        FileNode(name: 'fractions', getQuestions: () => fractionsQuestions),
        FileNode(name: 'roots', getQuestions: () => rootsQuestions),
      ],
    ),
  ],
);

/// Drill-down folder menu screen
class FolderMenuScreen extends StatefulWidget {
  final Folder rootFolder;
  final void Function(FileNode fileNode) onLevelSelected;

  const FolderMenuScreen({
    super.key,
    required this.rootFolder,
    required this.onLevelSelected,
  });

  @override
  _FolderMenuScreenState createState() => _FolderMenuScreenState();
}

class _FolderMenuScreenState extends State<FolderMenuScreen> {
  // Start the path already inside 'questions_new'
  List<Folder> path = [];

  Folder get currentFolder {
    // If path is empty, start with first subfolder (questions_new)
    if (path.isEmpty && widget.rootFolder.subfolders.isNotEmpty) {
      return widget.rootFolder.subfolders.first;
    }
    return path.isEmpty ? widget.rootFolder : path.last;
  }

  void enterFolder(Folder folder) {
    setState(() => path.add(folder));
  }

  void goBack() {
    if (path.isNotEmpty) setState(() => path.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    final folders = currentFolder.subfolders;
    final files = currentFolder.files;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          currentFolder.name,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: AppColors.appBar,
        leading: path.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: goBack,
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final folder in folders)
            Card(
              color: AppColors.background,
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: ListTile(
                title: Text(folder.name,
                    style: const TextStyle(color: Colors.black, fontSize: 18)),
                onTap: () => enterFolder(folder),
              ),
            ),
          for (final file in files)
            Card(
              color: AppColors.background,
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: ListTile(
                title: Text(file.name,
                    style: const TextStyle(color: Colors.black, fontSize: 18)),
                onTap: () => widget.onLevelSelected(file),
              ),
            ),
        ],
      ),
    );
  }
}
