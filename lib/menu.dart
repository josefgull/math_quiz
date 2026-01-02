// lib/menu.dart
import 'package:flutter/material.dart';
import 'styles.dart';
// Import all question files
import 'questions/arithmetic/l1_pm.dart';
import 'questions/else/fractions.dart';
import 'questions/else/roots.dart';
import 'questions/else/exponentials.dart';
import 'questions/Vectors_and_Linear_Algebra/Vector_calculus_questions.dart';

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
  name: 'root',
  subfolders: [
    Folder(
      name: 'Topics',
      subfolders: [
        Folder(
          name: 'Simple Arithmetic',
          files: [
            FileNode(name: 'Addition', getQuestions: () => plusminusQuestions),
          ],
        ),
        Folder(
          name: 'Other Topics',
          files: [
            FileNode(name: 'Fractions', getQuestions: () => fractionsQuestions),
            FileNode(name: 'Roots', getQuestions: () => rootsQuestions),
            FileNode(name: 'Exponentials', getQuestions: () => exponentialsQuestions),
          ],
        ),
        Folder(
          name: 'Vectors and Linear Algebra',
          files: [
            FileNode(name: 'Vector Calculus', getQuestions: () => Vector_calculusQuestions),
          ],
        ),
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
