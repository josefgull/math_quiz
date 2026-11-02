import random

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
        correct = str(round(numerator/denominator, 2))
        answers = [correct,
                   str(round((numerator+1)/denominator,2)),
                   str(round(numerator/(denominator+1),2)),
                   str(round((numerator-1)/denominator,2))]
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
            question = f"√{n*n}"
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

def dart_var_name(topic_name):
    """Convert topic name to Dart variable name"""
    return topic_name.replace("_questions","") + "Questions"

def print_dart_list(var_name, questions):
    print(f"final List<Map<String, dynamic>> {var_name} = [")
    for q in questions:
        print(f"  {{'question': r'{q['question']}', 'answers': {q['answers']}, 'correct': '{q['correct']}'}}," )
    print("];\n")

# -------------------------------
# Main execution
# -------------------------------

TOPICS = {
    "Basic_operations_questions": generate_basic_operations,
    "Fractions_and_ratios_questions": generate_fractions_and_ratios,
    "Number_properties_questions": generate_number_properties,
    "Squares_and_roots_questions": generate_squares_and_roots
}

if __name__ == "__main__":
    for topic_name, generator in TOPICS.items():
        questions = generator()
        var_name = dart_var_name(topic_name)
        print_dart_list(var_name, questions)
