final Map<int, List<Map<String, dynamic>>> questionPacks = {
  1: [ // Fractions
    {
      'question': r'\frac{1}{2} + \frac{1}{3}',
      'answers': ['5/6', '2/5', '1/5', '3/4'],
      'correct': 1, // index starting from 1
    },
    {
      'question': r'\frac{3}{4} - \frac{1}{2}',
      'answers': ['1/2', '1/4', '2/4', '3/2'],
      'correct': 2,
    },
  ],
  2: [ // Roots
    {
      'question': r'\sqrt{16}',
      'answers': ['2', '4', '8', '16'],
      'correct': 2,
    },
    {
      'question': r'\sqrt{49}',
      'answers': ['7', '14', '9', '21'],
      'correct': 1,
    },
  ],
  3: [ // Exponentials
    {
      'question': r'2^3',
      'answers': ['6', '8', '4', '16'],
      'correct': 2,
    },
    {
      'question': r'3^2',
      'answers': ['6', '9', '8', '5'],
      'correct': 2,
    },
  ],
};
