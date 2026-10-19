const VALID_DIFFICULTIES = ['basic', 'intermediate', 'advanced'];

/**
 * Validates a single question object produced by the AI, before it may be
 * saved. Mirrors the app-side validation and adds richer checks
 * (requirements, section 12).
 *
 * The AI output is NEVER considered valid without passing this validation.
 *
 * Expected shape (already parsed from the model's structured output):
 * {
 *   statement: string,
 *   codeSnippet?: string | null,
 *   difficulty: 'basic'|'intermediate'|'advanced',
 *   options: [{ id, text, explanation, correct }] x4
 * }
 *
 * Returns { valid: true, value: normalizedQuestion } or
 * { valid: false, errors: string[] }.
 */
export function validateQuestion(raw, context = {}) {
  const errors = [];

  if (!raw || typeof raw !== 'object') {
    return { valid: false, errors: ['Questão com formato inválido.'] };
  }

  const statement =
    typeof raw.statement === 'string' ? raw.statement.trim() : '';
  if (statement === '') {
    errors.push('Enunciado vazio.');
  }

  const difficulty =
    typeof raw.difficulty === 'string' ? raw.difficulty.trim() : '';
  if (!VALID_DIFFICULTIES.includes(difficulty)) {
    errors.push('Nível de dificuldade inválido.');
  }

  const options = Array.isArray(raw.options) ? raw.options : [];
  if (options.length !== 4) {
    errors.push(`Deve haver exatamente 4 alternativas (há ${options.length}).`);
  }

  let correctCount = 0;
  const normalizedOptions = [];
  for (let i = 0; i < options.length; i++) {
    const o = options[i] && typeof options[i] === 'object' ? options[i] : {};
    const text = typeof o.text === 'string' ? o.text.trim() : '';
    const explanation =
      typeof o.explanation === 'string' ? o.explanation.trim() : '';
    const correct = o.correct === true;

    if (text === '') errors.push(`Alternativa ${i + 1} sem texto.`);
    if (explanation === '') {
      errors.push(`Alternativa ${i + 1} sem explicação.`);
    }
    if (correct) correctCount++;

    // Assign a stable id (a, b, c, d) regardless of what the model returned.
    normalizedOptions.push({
      id: String.fromCharCode(97 + i),
      text,
      explanation,
      correct,
    });
  }

  if (options.length === 4) {
    if (correctCount < 1) {
      errors.push('Deve haver pelo menos 1 alternativa correta.');
    } else if (correctCount === options.length) {
      errors.push('A questão não pode ter todas as alternativas corretas.');
    }
  }

  // Duplicate / nearly identical option texts.
  const normTexts = normalizedOptions
    .map((o) => normalize(o.text))
    .filter((t) => t !== '');
  if (new Set(normTexts).size !== normTexts.length) {
    errors.push('Há alternativas duplicadas ou praticamente idênticas.');
  }

  // Forbidden option phrasings (requirements, section 6).
  for (const o of normalizedOptions) {
    const t = normalize(o.text);
    if (
      t.includes('todas as alternativas') ||
      t.includes('nenhuma das alternativas')
    ) {
      errors.push(
        'Alternativas não podem ser "todas"/"nenhuma das alternativas".',
      );
      break;
    }
  }

  if (errors.length > 0) {
    return { valid: false, errors };
  }

  return {
    valid: true,
    value: {
      statement,
      codeSnippet:
        typeof raw.codeSnippet === 'string' && raw.codeSnippet.trim() !== ''
          ? raw.codeSnippet
          : null,
      difficulty,
      theme: context.theme ?? null,
      subtopic: context.subtopic ?? null,
      options: normalizedOptions,
    },
  };
}

function normalize(s) {
  return String(s)
    .trim()
    .toLowerCase()
    .replace(/\s+/g, ' ');
}

/**
 * Builds short, normalized "signatures" of questions to detect simple local
 * duplicates (requirements, section 13). Two questions with the same
 * statement signature are considered duplicates.
 */
export function statementSignature(statement) {
  return normalize(statement).replace(/[^\p{L}\p{N} ]/gu, '');
}
