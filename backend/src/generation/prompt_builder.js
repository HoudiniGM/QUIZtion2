import { BASE_PROMPT, PROMPT_VERSION } from './prompt_base.js';

const DIFFICULTY_LABEL = {
  basic: 'básico',
  intermediate: 'intermediário',
  advanced: 'avançado',
};

/** Max length accepted for a user-provided custom template (token safety). */
const MAX_TEMPLATE_CHARS = 20000;

/**
 * Builds the prompt from a user-provided template by substituting the
 * {{placeholders}} with the real values. The response FORMAT is NOT controlled
 * here — it is enforced separately by the response schema.
 *
 * Returns { promptVersion, prompt }. `promptVersion` is marked 'custom' so
 * generation metadata reflects that a custom template was used.
 */
export function buildPromptFromTemplate(template, params) {
  const {
    theme,
    subtopic,
    difficulty,
    quantity,
    material = '',
    existingSummaries = [],
  } = params;

  const difficultyLabel = DIFFICULTY_LABEL[difficulty] ?? difficulty;

  const tpl = String(template).slice(0, MAX_TEMPLATE_CHARS);

  const existingText = (existingSummaries || [])
    .map((s) => (typeof s === 'string' ? s.trim() : ''))
    .filter((s) => s.length > 0)
    .map((s, i) => `${i + 1}. ${s}`)
    .join('\n');

  const values = {
    theme: theme ?? '',
    subtopic: subtopic ?? '',
    difficulty: difficultyLabel ?? '',
    quantity: String(quantity ?? ''),
    material: clampMaterial((material || '').trim()) || '(nenhum)',
    existing: existingText || '(nenhuma)',
  };

  const prompt = tpl.replace(/\{\{\s*(\w+)\s*\}\}/g, (match, key) => {
    return Object.prototype.hasOwnProperty.call(values, key)
      ? values[key]
      : match;
  });

  return { promptVersion: 'custom', prompt };
}

/**
 * Builds the full prompt for a generation request by combining:
 *  1. the permanent, generic base prompt (versioned);
 *  2. the mandatory theme and subtopic (dynamic specialization);
 *  3. the requested quantity;
 *  4. the chosen difficulty;
 *  5. optional complementary material;
 *  6. summaries of existing questions, to help avoid duplicates.
 *
 * Returns { promptVersion, prompt }.
 *
 * The caller must have validated the request first (theme/subtopic required).
 */
export function buildPrompt({
  theme,
  subtopic,
  difficulty,
  quantity,
  material = '',
  existingSummaries = [],
}) {
  const difficultyLabel = DIFFICULTY_LABEL[difficulty] ?? difficulty;

  const parts = [BASE_PROMPT, ''];

  parts.push(
    `Especialização desta geração:`,
    `- Tema: ${theme}`,
    `- Subtópico: ${subtopic}`,
    `Atue como especialista em "${theme}", com foco em "${subtopic}".`,
    '',
  );

  parts.push(
    `Gere ${quantity} questão(ões) no nível de dificuldade ${difficultyLabel}.`,
    '',
  );

  const trimmedMaterial = (material || '').trim();
  if (trimmedMaterial.length > 0) {
    parts.push(
      'Material complementar fornecido pelo usuário (use como orientação, mas',
      'ele NÃO é a única fonte permitida; complemente com conhecimento',
      'pertinente ao tema e subtópico). Não reproduza erros factuais evidentes',
      'do material como se fossem verdade, e não invente citações/dados a',
      'partir dele:',
      '"""',
      clampMaterial(trimmedMaterial),
      '"""',
      '',
    );
  } else {
    parts.push(
      'Nenhum material complementar foi fornecido. Baseie-se em conhecimento',
      'consolidado sobre o tema e o subtópico.',
      '',
    );
  }

  const summaries = (existingSummaries || [])
    .map((s) => (typeof s === 'string' ? s.trim() : ''))
    .filter((s) => s.length > 0);
  if (summaries.length > 0) {
    parts.push(
      'Para evitar duplicatas, abaixo estão resumos de questões já existentes',
      'neste tema/subtópico. NÃO repita essas questões nem variações cosméticas',
      'que avaliem exatamente o mesmo ponto da mesma forma. Pode abordar o mesmo',
      'conceito se exigir habilidade, contexto ou raciocínio diferentes:',
      ...summaries.map((s, i) => `${i + 1}. ${s}`),
      '',
    );
  }

  return {
    promptVersion: PROMPT_VERSION,
    prompt: parts.join('\n'),
  };
}

/**
 * Limits the amount of material sent to the model, to control token usage and
 * avoid sending unbounded user input (requirements, sections 13 and 17).
 */
function clampMaterial(material, maxChars = 6000) {
  if (material.length <= maxChars) return material;
  return `${material.slice(0, maxChars)}\n[...material truncado...]`;
}
