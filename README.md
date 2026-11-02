![icon](assets/icon/app_icon.png)



# Math Quiz

A web-based math quiz with customizable question sets for learning, practice, or skill refresh. Runs in any browser, on phone, tablet or desktop.

## Link to Webversion

[Current state of quiz](https://josefgull.github.io/math_quiz/)

## How the menu works

The menu is built from the folder structure in [`questions/`](questions/). Every folder becomes a menu entry, every `.json` file becomes a quiz:

```text
questions/
  Algebra/                     -> menu folder "Algebra"
    Complex_numbers.json       -> quiz "Complex numbers"
    Advanced/                  -> folders can be nested as deep as you like
      ...
```

Underscores turn into spaces. To control the order, prefix names with a number (`01_Basics`, `02_Advanced`); the prefix is hidden in the menu.

## Adding questions

A quiz file is a list of questions. Questions and answers can use LaTeX (no `$` needed). In JSON, backslashes must be doubled:

```json
[
  {
    "question": "\\frac{d}{dx}\\sin x",
    "answers": ["\\cos x", "-\\cos x", "\\sin x", "-\\sin x"],
    "correct": "\\cos x"
  },
  {
    "question": "Is 7 prime?",
    "answers": ["Yes", "No"],
    "correct": "Yes"
  }
]
```

Answers are shuffled automatically. `correct` must be exactly one of the answers.

Question files can also be generated with Python, see [`questions/Arithmetic_Number_Theory/gen.py`](questions/Arithmetic_Number_Theory/gen.py).

## Running locally

```sh
python3 build_menu.py        # builds questions.json from questions/ and checks every file
python3 -m http.server       # then open http://localhost:8000
```

On every push to `main`, GitHub Actions runs `build_menu.py` and deploys the site to GitHub Pages. Pull requests run the same check, so a broken question file shows up before it is merged.

## Contributing

This project is open source, and contributions are welcome!
If you’d like to add your own question sets or improve existing ones, feel free to submit a pull request.
We appreciate all contributions that help make the quiz better for everyone.
