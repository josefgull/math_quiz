"""
Builds questions.json (the menu tree + all questions) from the questions/ folder.

    questions/
      Algebra/                    -> menu folder "Algebra"
        Complex_numbers.json      -> quiz "Complex numbers"
        Advanced/                 -> nested folders work at any depth
          ...

Names: underscores become spaces, an optional "01_" style prefix sets the
order and is hidden. Each .json file is a list of
    {"question": "...", "answers": ["...", ...], "correct": "..."}
with LaTeX allowed in question and answers.

Run:  python3 build_menu.py        (exits non-zero if a question file is broken)
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).parent
QUESTIONS_DIR = ROOT / "questions"
OUTPUT = ROOT / "questions.json"

errors = []


def display_name(path: Path) -> str:
    name = path.stem if path.is_file() else path.name
    name = re.sub(r"^\d+[_\- ]+", "", name)
    return name.replace("_", " ")


def load_questions(file: Path) -> list:
    rel = file.relative_to(ROOT)
    try:
        questions = json.loads(file.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        errors.append(f"{rel}: invalid JSON ({e})")
        return []

    if not isinstance(questions, list):
        errors.append(f"{rel}: must be a list of questions")
        return []

    valid = []
    for i, q in enumerate(questions, 1):
        where = f"{rel} question {i}"
        if not isinstance(q, dict) or not {"question", "answers", "correct"} <= q.keys():
            errors.append(f"{where}: needs 'question', 'answers' and 'correct'")
            continue
        answers = [str(a) for a in q["answers"]]
        correct = str(q["correct"])
        if len(answers) < 2:
            errors.append(f"{where}: needs at least 2 answers")
            continue
        if correct not in answers:
            errors.append(f"{where}: correct answer {correct!r} is not one of the answers")
            continue
        if len(set(answers)) != len(answers):
            errors.append(f"{where}: duplicate answers {answers}")
            continue
        valid.append({"question": str(q["question"]), "answers": answers, "correct": correct})
    return valid


def build_folder(path: Path) -> dict:
    folders, quizzes = [], []
    for item in sorted(path.iterdir()):
        if item.name.startswith("."):
            continue
        if item.is_dir():
            sub = build_folder(item)
            if sub["folders"] or sub["quizzes"]:
                folders.append(sub)
        elif item.suffix == ".json":
            questions = load_questions(item)
            if questions:
                quizzes.append({"id": item.stem, "name": display_name(item), "questions": questions})
    return {"id": path.name, "name": display_name(path), "folders": folders, "quizzes": quizzes}


def count(folder: dict) -> tuple:
    quizzes = len(folder["quizzes"]) + sum(count(f)[0] for f in folder["folders"])
    questions = sum(len(q["questions"]) for q in folder["quizzes"]) + sum(count(f)[1] for f in folder["folders"])
    return quizzes, questions


if __name__ == "__main__":
    tree = build_folder(QUESTIONS_DIR)
    tree["name"] = "Topics"

    for e in errors:
        print("ERROR", e, file=sys.stderr)

    OUTPUT.write_text(json.dumps(tree, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    quizzes, questions = count(tree)
    print(f"wrote {OUTPUT.name}: {quizzes} quizzes, {questions} questions")
    sys.exit(1 if errors else 0)
