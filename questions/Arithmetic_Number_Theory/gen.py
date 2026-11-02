import json
import random
from pathlib import Path

# -------------------------------
# Generator functions per topic
# -------------------------------

def generate_basic_operations():
    qlist = []
    for _ in range(10):
        a = random.randint(1, 20)
        b = random.randint(1, 20)
        question = f"{a}+{b}"
        correct = str(a + b)
        # 3 random wrong answers
        wrongs = set()
        while len(wrongs) < 3:
            w = random.randint(max(0, a + b - 3), a + b + 3)
            if str(w) != correct:
                wrongs.add(str(w))
        answers = list(wrongs) + [correct]
        random.shuffle(answers)
        qlist.append({'question': rf'{question}', 'answers': answers, 'correct': correct})
    return qlist

def generate_fractions_and_ratios():
    qlist = []
    for _ in range(8):
        numerator = random.randint(1, 9)
        denominator = random.randint(2, 10)
        question = f"{numerator}/{denominator}"
        correct = fmt(numerator/denominator)
        answers = [correct,
                   fmt((numerator+1)/denominator),
                   fmt(numerator/(denominator+1)),
                   fmt((numerator-1)/denominator)]
        random.shuffle(answers)
        qlist.append({'question': rf'{question}', 'answers': answers, 'correct': correct})
    return qlist

def generate_number_properties():
    qlist = []
    for _ in range(8):
        n = random.randint(2, 20)
        question = f"Is {n} prime?"
        correct = "Yes" if is_prime(n) else "No"
        answers = ["Yes", "No"]
        qlist.append({'question': rf'{question}', 'answers': answers, 'correct': correct})
    return qlist

def generate_squares_and_roots():
    qlist = []
    for _ in range(10):
        n = random.randint(2, 15)
        question_type = random.choice(["square", "root"])
        if question_type == "square":
            question = f"{n}^2"
            correct = str(n * n)
        else:
            question = rf"\sqrt{{{n*n}}}"
            correct = str(n)
        wrongs = set()
        while len(wrongs) < 3:
            wrong = str(random.randint(max(0, int(correct)-3), int(correct)+3))
            if wrong != correct:
                wrongs.add(wrong)
        answers = list(wrongs) + [correct]
        random.shuffle(answers)
        qlist.append({'question': rf'{question}', 'answers': answers, 'correct': correct})
    return qlist

# -------------------------------
# Helper functions
# -------------------------------

def is_prime(n):
    if n < 2:
        return False
    for i in range(2,int(n**0.5)+1):
        if n % i == 0:
            return False
    return True

def fmt(x):
    """Round to 2 decimals and drop trailing zeros (3.0 -> 3)"""
    return f"{round(x, 2):g}"

# -------------------------------
# Main execution
# -------------------------------

TOPICS = {
    "Basic_operations": generate_basic_operations,
    "Fractions_and_ratios": generate_fractions_and_ratios,
    "Number_properties": generate_number_properties,
    "Squares_and_roots": generate_squares_and_roots
}

if __name__ == "__main__":
    # Writes one <topic>.json next to this script
    here = Path(__file__).parent
    for topic_name, generator in TOPICS.items():
        questions = generator()
        out = here / f"{topic_name}.json"
        out.write_text(json.dumps(questions, indent=2, ensure_ascii=False) + "\n")
        print(f"wrote {out} ({len(questions)} questions)")
