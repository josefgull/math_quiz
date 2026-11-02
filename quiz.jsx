import { useState, useEffect, useCallback, useMemo } from "react";

// questions.json is generated from the questions/ folder by build_menu.py
const DATA_URL = "./questions.json";
const REPO_URL = "https://github.com/josefgull/math_quiz";

const STRINGS = {
  en: {
    title: "Math Quiz",
    root: "Topics",
    loading: "Loading questions…",
    loadError: "Could not load questions.json. Run python3 build_menu.py and serve the folder over http.",
    quizzes: (n) => `${n} ${n === 1 ? "quiz" : "quizzes"}`,
    questions: (n) => `${n} ${n === 1 ? "question" : "questions"}`,
    best: (s, t) => `best ${s}/${t}`,
    back: "BACK",
    points: "POINTS",
    stamp: "CHECKED",
    bestStreak: (n) => `Best streak: ${n}.`,
    again: "PLAY AGAIN",
    menu: "MENU",
    footer: "Add your own quiz: drop a JSON file into questions/",
    grades: {
      qed: { label: "Q.E.D.", detail: "Flawless." },
      derived: { label: "Well Derived", detail: "Solid work." },
      onTrack: { label: "On the Right Track", detail: "Most of it adds up." },
      firstSteps: { label: "First Steps", detail: "Every proof starts with a lemma." },
    },
  },
  de: {
    title: "Mathe-Quiz",
    root: "Themen",
    loading: "Fragen werden geladen…",
    loadError: "questions.json konnte nicht geladen werden. python3 build_menu.py ausführen und den Ordner über http ausliefern.",
    quizzes: (n) => `${n} ${n === 1 ? "Quiz" : "Quizze"}`,
    questions: (n) => `${n} ${n === 1 ? "Frage" : "Fragen"}`,
    best: (s, t) => `Rekord ${s}/${t}`,
    back: "ZURÜCK",
    points: "PUNKTE",
    stamp: "GEPRÜFT",
    bestStreak: (n) => `Bester Streak: ${n}.`,
    again: "NOCHMAL",
    menu: "MENÜ",
    footer: "Eigenes Quiz hinzufügen: JSON-Datei in questions/ ablegen",
    grades: {
      qed: { label: "Q.E.D.", detail: "Fehlerfrei." },
      derived: { label: "Sauber hergeleitet", detail: "Solide Arbeit." },
      onTrack: { label: "Auf dem richtigen Weg", detail: "Das meiste geht auf." },
      firstSteps: { label: "Erste Schritte", detail: "Jeder Beweis beginnt mit einem Lemma." },
    },
  },
};

// Colors from the original app (old lib/styles.dart AppColors)
const C = {
  page: "#55838f",
  background: "#6c99a6", // AppColors.background
  mint: "#acdfc7", // AppColors.appBar / buttonDefault
  correct: "#95eb98", // AppColors.buttonCorrect
  wrong: "#e4b2ae", // AppColors.buttonWrong
  mintLight: "#d3efe2",
  border: "#8cc4ad",
  line: "#5d8b97",
  text: "#0f1f24",
  muted: "#14292f",
  mutedOnMint: "#3a5a5c",
  red: "#7a1f2b",
  green: "#1d5a24",
};

// --- Storage (per browser; never required) ------------------------------
function load(key, fallback) {
  try {
    const v = localStorage.getItem(key);
    return v ? JSON.parse(v) : fallback;
  } catch {
    return fallback;
  }
}
function save(key, value) {
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch {}
}

// --- Math rendering ----------------------------------------------------
// Most question files hold LaTeX without $…$ delimiters, mixed with plain
// sentences like "Is 7 prime?". Plain sentences are shown as text; everything
// else goes through KaTeX, with words of 3+ letters (and short words like
// "of", "is") set upright via \text{}. Delimited math is handled by renderMixed.
const SHORT_WORDS = "of|is|if|in|to|by|on|at|an|as|or|be|it|no|so|we|ob|im|zu|da|wo|es|um";
function isPlainText(s) {
  if (/[\\^_{}]/.test(s)) return false;
  const words = s.trim().split(/\s+/);
  if (words.length > 1) return words.some((w) => /^[A-Za-z]{2,}[?!.,:]?$/.test(w));
  return /^[A-Z][a-z]+(-[a-z]+)?$/.test(s) || /^[a-z]{4,}$/.test(s);
}

const WORD = new RegExp(`(?<![\\\\A-Za-z{])([A-Za-z]{3,}(?:'s?)?|(?:${SHORT_WORDS})(?=\\\\;|\\s|$))(?![A-Za-z])`, "gi");

function wrapWords(tex) {
  return tex.replace(WORD, "\\text{$1}");
}

// Split at top-level "\;" so long questions can wrap between chunks.
function splitChunks(tex) {
  const chunks = [];
  let depth = 0;
  let start = 0;
  for (let i = 0; i < tex.length; i++) {
    const ch = tex[i];
    if (ch === "{") depth++;
    else if (ch === "}") depth--;
    else if (tex.startsWith("\\left", i) || tex.startsWith("\\begin", i)) depth++;
    else if (tex.startsWith("\\right", i) || tex.startsWith("\\end", i)) depth--;
    else if (depth === 0 && tex.startsWith("\\;", i)) {
      chunks.push(tex.slice(start, i));
      start = i + 2;
      i++;
    }
  }
  chunks.push(tex.slice(start));
  return chunks.filter((c) => c.trim() !== "");
}

// Sentences with delimited math, e.g. "Was repräsentiert \( \vec{F} \)?",
// keep their text as is and only render the \( \), \[ \], $ $ and $$ $$ parts.
const DELIMITED = /\$\$([\s\S]+?)\$\$|\\\[([\s\S]+?)\\\]|\\\(([\s\S]+?)\\\)|\$([^$\n]+?)\$/g;

function escapeHtml(s) {
  return s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
}

function renderMixed(src) {
  let html = "";
  let last = 0;
  for (const m of src.matchAll(DELIMITED)) {
    html += escapeHtml(src.slice(last, m.index));
    html += window.katex.renderToString(m[1] ?? m[2] ?? m[3] ?? m[4], { throwOnError: false });
    last = m.index + m[0].length;
  }
  return html + escapeHtml(src.slice(last));
}

function renderMath(tex) {
  return splitChunks(tex)
    .map((chunk) => window.katex.renderToString(wrapWords(chunk), { throwOnError: false }))
    .join(" ");
}

function Tex({ src, className = "", style }) {
  const html = useMemo(() => {
    if (!window.katex) return null;
    if (src.search(DELIMITED) !== -1) return renderMixed(src);
    if (isPlainText(src)) return null;
    return renderMath(src);
  }, [src]);
  const cls = `${className} whitespace-pre-line`;
  if (html === null) return <span className={cls} style={style}>{src}</span>;
  return <span className={cls} style={style} dangerouslySetInnerHTML={{ __html: html }} />;
}

// --- Helpers -----------------------------------------------------------
function shuffle(arr) {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

function countFolder(folder) {
  let quizzes = folder.quizzes.length;
  let questions = folder.quizzes.reduce((n, q) => n + q.questions.length, 0);
  for (const f of folder.folders) {
    const [a, b] = countFolder(f);
    quizzes += a;
    questions += b;
  }
  return [quizzes, questions];
}

// "#/Algebra/Complex_numbers" -> { trail: [root, Algebra], quiz }
function resolveRoute(tree, hash) {
  const segments = hash.replace(/^#\/?/, "").split("/").filter(Boolean).map(decodeURIComponent);
  const trail = [tree];
  for (let i = 0; i < segments.length; i++) {
    const here = trail[trail.length - 1];
    const folder = here.folders.find((f) => f.id === segments[i]);
    if (folder) {
      trail.push(folder);
      continue;
    }
    const quiz = i === segments.length - 1 && here.quizzes.find((q) => q.id === segments[i]);
    return { trail, quiz: quiz || null };
  }
  return { trail, quiz: null };
}

function hashFor(trail, quiz) {
  const ids = trail.slice(1).map((f) => f.id);
  if (quiz) ids.push(quiz.id);
  return "#/" + ids.map(encodeURIComponent).join("/");
}

function useHash() {
  const [hash, setHash] = useState(window.location.hash);
  useEffect(() => {
    const onChange = () => setHash(window.location.hash);
    window.addEventListener("hashchange", onChange);
    return () => window.removeEventListener("hashchange", onChange);
  }, []);
  return hash;
}

// --- Ad slot -----------------------------------------------------------
// Fill in your AdSense client and slot to show an ad under the card.
// Family-safe filtering is set in the AdSense account, not here.
const ADSENSE = { client: "", slot: "" };

function AdSlot() {
  useEffect(() => {
    if (!ADSENSE.client) return;
    if (!document.querySelector("script[data-adsense]")) {
      const s = document.createElement("script");
      s.async = true;
      s.dataset.adsense = "1";
      s.crossOrigin = "anonymous";
      s.src = `https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${ADSENSE.client}`;
      document.head.appendChild(s);
    }
    try {
      (window.adsbygoogle = window.adsbygoogle || []).push({});
    } catch {}
  }, []);
  if (!ADSENSE.client) return null;
  return (
    <div className="w-full max-w-md mt-4">
      <ins
        className="adsbygoogle"
        style={{ display: "block", minHeight: "90px" }}
        data-ad-client={ADSENSE.client}
        data-ad-slot={ADSENSE.slot}
        data-ad-format="auto"
        data-full-width-responsive="true"
      />
    </div>
  );
}

// --- UI pieces ---------------------------------------------------------
function LanguageSelector({ lang, setLang }) {
  return (
    <div className="flex mq-mono text-[10px] tracking-wide rounded-full overflow-hidden" style={{ border: `1px solid ${C.text}` }}>
      {["en", "de"].map((code) => (
        <button
          key={code}
          onClick={() => setLang(code)}
          className="px-2.5 py-1 transition-colors"
          style={{ background: lang === code ? C.text : "transparent", color: lang === code ? C.mint : C.text }}
        >
          {code.toUpperCase()}
        </button>
      ))}
    </div>
  );
}

function PillButton({ onClick, children, variant = "solid" }) {
  const solid = variant === "solid";
  return (
    <button
      onClick={onClick}
      className="mq-mono text-sm tracking-wide px-6 py-3 rounded-full transition-transform active:scale-95"
      style={{
        background: solid ? C.mint : "transparent",
        color: C.text,
        border: `1.5px solid ${solid ? C.mint : C.text}`,
      }}
    >
      {children}
    </button>
  );
}

// --- Menu --------------------------------------------------------------
function Menu({ trail, t, best }) {
  const folder = trail[trail.length - 1];
  const parentHash = trail.length > 1 ? hashFor(trail.slice(0, -1)) : null;

  return (
    <div>
      <div className="flex items-center gap-2 mb-4 mq-mono text-[11px] flex-wrap" style={{ color: C.muted }}>
        {parentHash && (
          <a href={parentHash} className="px-2 py-0.5 rounded-full mr-1" style={{ border: `1px solid ${C.text}`, color: C.text }}>
            ← {t.back}
          </a>
        )}
        {trail.map((f, i) => (
          <span key={i} className="flex items-center gap-2">
            {i > 0 && <span>›</span>}
            {i < trail.length - 1 ? (
              <a href={hashFor(trail.slice(0, i + 1))} className="underline underline-offset-2">
                {i === 0 ? t.root : f.name}
              </a>
            ) : (
              <span style={{ color: C.text, fontWeight: 600 }}>{i === 0 ? t.root : f.name}</span>
            )}
          </span>
        ))}
      </div>

      <div className="grid grid-cols-1 gap-2.5">
        {folder.folders.map((f) => {
          const [quizzes, questions] = countFolder(f);
          return (
            <a
              key={f.id}
              href={hashFor([...trail, f])}
              className="mq-card flex items-center justify-between px-4 py-3 rounded-lg"
              style={{ background: C.mint, border: `1.5px solid ${C.border}`, color: C.text }}
            >
              <span className="flex items-center gap-3">
                <span className="mq-mono text-base" style={{ color: C.text }}>▸</span>
                <span className="mq-body text-sm font-medium">{f.name}</span>
              </span>
              <span className="mq-mono text-[10px] text-right" style={{ color: C.mutedOnMint }}>
                {t.quizzes(quizzes)} · {t.questions(questions)}
              </span>
            </a>
          );
        })}
        {folder.quizzes.map((q) => {
          const href = hashFor(trail, q);
          const b = best[href];
          return (
            <a
              key={q.id}
              href={href}
              className="mq-card flex items-center justify-between px-4 py-3 rounded-lg"
              style={{ background: C.mint, border: `1.5px solid ${C.border}`, color: C.text }}
            >
              <span className="flex items-center gap-3">
                <span className="mq-mono text-base" style={{ color: C.red }}>∑</span>
                <span className="mq-body text-sm font-medium">{q.name}</span>
              </span>
              <span className="mq-mono text-[10px] text-right" style={{ color: b && b.score === b.total ? C.green : C.mutedOnMint, fontWeight: b && b.score === b.total ? 600 : 400 }}>
                {b ? t.best(b.score, b.total) : t.questions(q.questions.length)}
              </span>
            </a>
          );
        })}
      </div>
    </div>
  );
}

// --- Quiz --------------------------------------------------------------
function buildRounds(quiz) {
  return shuffle(quiz.questions).map((q) => ({ ...q, options: shuffle(q.answers) }));
}

function Quiz({ quiz, t, menuHash, onFinish }) {
  const [rounds, setRounds] = useState(() => buildRounds(quiz));
  const [idx, setIdx] = useState(0);
  const [selected, setSelected] = useState(null);
  const [score, setScore] = useState(0);
  const [streak, setStreak] = useState(0);
  const [bestStreak, setBestStreak] = useState(0);
  const [history, setHistory] = useState([]);
  const [done, setDone] = useState(false);

  const total = rounds.length;
  const round = rounds[idx];

  const restart = useCallback(() => {
    setRounds(buildRounds(quiz));
    setIdx(0);
    setSelected(null);
    setScore(0);
    setStreak(0);
    setBestStreak(0);
    setHistory([]);
    setDone(false);
  }, [quiz]);

  const answer = useCallback(
    (opt) => {
      if (selected !== null || done) return;
      setSelected(opt);
      const correct = opt === round.correct;
      setHistory((h) => [...h, { question: round.question, correctAnswer: round.correct, correct }]);
      if (correct) {
        setScore((s) => s + 1);
        setStreak((s) => {
          const ns = s + 1;
          setBestStreak((b) => Math.max(b, ns));
          return ns;
        });
      } else {
        setStreak(0);
      }
    },
    [selected, done, round]
  );

  // Advance automatically; wrong answers stay up longer so the right one can sink in.
  useEffect(() => {
    if (selected === null) return;
    const delay = selected === round.correct ? 900 : 2200;
    const timer = setTimeout(() => {
      if (idx + 1 >= total) {
        setDone(true);
      } else {
        setIdx((i) => i + 1);
        setSelected(null);
      }
    }, delay);
    return () => clearTimeout(timer);
  }, [selected, round, idx, total]);

  useEffect(() => {
    if (done) onFinish(score, total);
  }, [done]);

  // Number keys 1–4 pick an answer.
  useEffect(() => {
    const onKey = (e) => {
      if (done || !round) return;
      const n = Number(e.key);
      if (n >= 1 && n <= round.options.length) answer(round.options[n - 1]);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [done, round, answer]);

  const grade = useMemo(() => {
    const pct = score / total;
    if (pct === 1) return t.grades.qed;
    if (pct >= 0.75) return t.grades.derived;
    if (pct >= 0.5) return t.grades.onTrack;
    return t.grades.firstSteps;
  }, [score, total, t]);

  if (done) {
    return (
      <div className="text-center py-2">
        <div className="mq-stamp-anim inline-block mb-4">
          <div
            className="w-24 h-24 rounded-full flex flex-col items-center justify-center"
            style={{ border: `3px double ${C.red}`, color: C.red, transform: "rotate(-8deg)" }}
          >
            <span className="mq-mono text-[10px] tracking-widest">{t.stamp}</span>
            <span className="mq-display text-2xl leading-none">
              {score}/{total}
            </span>
          </div>
        </div>
        <h2 className="mq-display text-2xl mb-1" style={{ color: C.text }}>
          {grade.label}
        </h2>
        <p className="mq-body text-sm mb-5" style={{ color: C.muted }}>
          {grade.detail} {t.bestStreak(bestStreak)}
        </p>

        <div className="text-left mb-6 max-h-56 overflow-y-auto rounded-lg" style={{ border: `1px solid ${C.border}`, background: C.mintLight }}>
          {history.map((h, i) => (
            <div
              key={i}
              className="text-xs px-3 py-2 flex items-center justify-between gap-3"
              style={{
                borderBottom: i < history.length - 1 ? `1px solid ${C.mint}` : "none",
                color: h.correct ? C.green : C.red,
              }}
            >
              <span className="min-w-0 overflow-x-auto">
                <Tex src={h.question} />
                {!h.correct && (
                  <span className="ml-2" style={{ color: C.mutedOnMint }}>
                    → <Tex src={h.correctAnswer} style={{ color: C.green }} />
                  </span>
                )}
              </span>
              <span className="mq-mono shrink-0">{h.correct ? "✓" : "✗"}</span>
            </div>
          ))}
        </div>

        <div className="flex justify-center gap-3 flex-wrap">
          <PillButton onClick={restart}>{t.again}</PillButton>
          <PillButton variant="outline" onClick={() => (window.location.hash = menuHash)}>
            {t.menu}
          </PillButton>
        </div>
      </div>
    );
  }

  const progressPct = Math.round((idx / total) * 100);
  const compact = round.options.every((o) => o.length <= 14);

  return (
    <div>
      <div className="flex items-center justify-between gap-3 mb-1 mq-mono text-[11px]" style={{ color: C.muted }}>
        <a href={menuHash} className="underline underline-offset-2 truncate min-w-0">
          ← {quiz.name}
        </a>
        <span className="shrink-0">
          {idx + 1}/{total} · {t.points} {score}
        </span>
      </div>
      <div className="h-1.5 rounded-full mb-5" style={{ background: C.line }}>
        <div className="h-1.5 rounded-full transition-all duration-300" style={{ width: `${progressPct}%`, background: C.mint }} />
      </div>

      {/* question card on graph paper */}
      <div
        className="mq-grid relative rounded-xl mb-5 flex items-center justify-center px-5 py-8 text-center overflow-x-auto"
        style={{ minHeight: "9.5rem", border: `1px solid ${C.line}` }}
      >
        <Tex src={round.question} className={`mq-question leading-relaxed ${round.question.length > 90 ? "text-lg sm:text-xl" : "text-xl sm:text-2xl"}`} style={{ color: C.text }} />
        {streak >= 3 && (
          <div className="absolute top-2 right-2 mq-mono text-[10px] px-2 py-1 rounded-full" style={{ background: C.text, color: C.mint }}>
            🔥 {streak}
          </div>
        )}
      </div>

      <div className={`grid gap-2.5 ${compact ? "grid-cols-2" : "grid-cols-1"}`}>
        {round.options.map((opt, i) => {
          const isSelected = selected === opt;
          const isCorrect = selected !== null && opt === round.correct;
          let bg = C.mint;
          let border = C.border;
          if (selected !== null) {
            if (isCorrect) {
              bg = C.correct;
              border = C.green;
            } else if (isSelected) {
              bg = C.wrong;
              border = C.red;
            }
          }
          return (
            <button
              key={opt}
              onClick={() => answer(opt)}
              disabled={selected !== null}
              className="mq-body text-base text-left px-4 py-3 rounded-lg transition-colors flex items-center gap-3 overflow-x-auto"
              style={{ background: bg, border: `1.5px solid ${border}`, color: C.text }}
            >
              <span className="mq-mono text-[10px] shrink-0 hidden sm:inline" style={{ color: C.mutedOnMint }}>
                {i + 1}
              </span>
              <Tex src={opt} />
            </button>
          );
        })}
      </div>
    </div>
  );
}

// --- App ---------------------------------------------------------------
export default function MathQuiz() {
  const [lang, setLangState] = useState(() => load("mq-lang", "en"));
  const [tree, setTree] = useState(null);
  const [error, setError] = useState(false);
  const [best, setBest] = useState(() => load("mq-best", {}));
  const hash = useHash();
  const t = STRINGS[lang] || STRINGS.en;

  const setLang = (l) => {
    setLangState(l);
    save("mq-lang", l);
  };

  useEffect(() => {
    fetch(DATA_URL)
      .then((r) => (r.ok ? r.json() : Promise.reject(r.status)))
      .then(setTree)
      .catch(() => setError(true));
  }, []);

  useEffect(() => {
    document.documentElement.lang = lang;
  }, [lang]);

  const route = tree ? resolveRoute(tree, hash) : null;
  const quizHash = route && route.quiz ? hashFor(route.trail, route.quiz) : null;

  const recordScore = useCallback(
    (score, total) => {
      setBest((prev) => {
        const old = prev[quizHash];
        if (old && old.score / old.total >= score / total) return prev;
        const next = { ...prev, [quizHash]: { score, total } };
        save("mq-best", next);
        return next;
      });
    },
    [quizHash]
  );

  return (
    <div className="min-h-screen w-full flex flex-col items-center p-4 sm:p-6 sm:py-10" style={{ background: C.page }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,600;9..144,700&family=IBM+Plex+Mono:wght@400;500;600&family=Inter:wght@400;500;600&display=swap');
        .mq-display { font-family: 'Fraunces', serif; }
        .mq-mono { font-family: 'IBM Plex Mono', monospace; }
        .mq-body { font-family: 'Inter', sans-serif; }
        .mq-question:not(:has(.katex)) { font-family: 'Fraunces', serif; }
        .mq-grid {
          background-color: ${C.mintLight};
          background-image:
            linear-gradient(${C.mint} 1px, transparent 1px),
            linear-gradient(90deg, ${C.mint} 1px, transparent 1px);
          background-size: 18px 18px;
          background-position: center center;
        }
        .mq-card { transition: border-color .15s, transform .1s; }
        .mq-card:hover { border-color: ${C.text} !important; }
        .mq-card:active { transform: scale(0.99); }
        .katex { font-size: 1.1em; }
        @keyframes mq-stamp {
          0% { transform: scale(2.2) rotate(-14deg); opacity: 0; }
          60% { transform: scale(0.92) rotate(-14deg); opacity: 1; }
          100% { transform: scale(1) rotate(-14deg); opacity: 1; }
        }
        .mq-stamp-anim { animation: mq-stamp 0.4s ease-out; }
        @media (prefers-reduced-motion: reduce) {
          .mq-stamp-anim { animation: none; }
        }
      `}</style>

      <div className="w-full max-w-md rounded-2xl overflow-hidden shadow-2xl" style={{ background: C.background, border: `1px solid ${C.mint}` }}>
        <div className="px-5 py-4 flex items-center justify-between" style={{ background: C.mint, borderBottom: `1px solid ${C.border}` }}>
          <a href="#/" className="mq-mono text-[10px] tracking-[0.2em]" style={{ color: C.text }}>
            N° 3.14159
          </a>
          <h1 className="mq-display text-lg sm:text-xl" style={{ color: C.text }}>
            {t.title}
          </h1>
          <LanguageSelector lang={lang} setLang={setLang} />
        </div>

        <div className="p-5 sm:p-6">
          {error && (
            <p className="mq-body text-sm" style={{ color: C.red }}>
              {t.loadError}
            </p>
          )}
          {!error && !tree && (
            <p className="mq-mono text-xs text-center py-6" style={{ color: C.muted }}>
              {t.loading}
            </p>
          )}
          {route && !route.quiz && <Menu trail={route.trail} t={t} best={best} />}
          {route && route.quiz && (
            <Quiz key={quizHash} quiz={route.quiz} t={t} menuHash={hashFor(route.trail)} onFinish={recordScore} />
          )}
        </div>

        <div className="px-5 py-2.5 mq-mono text-[10px] text-center" style={{ background: C.mint, color: C.mutedOnMint }}>
          <a href={REPO_URL} target="_blank" rel="noopener">
            {t.footer}
          </a>
        </div>
      </div>

      <AdSlot />
    </div>
  );
}
