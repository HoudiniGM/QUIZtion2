import { config } from '../config.js';

const VALID_DIFFICULTIES = ['basic', 'intermediate', 'advanced'];

/**
 * Validates the body of a POST /generate request.
 *
 * Enforces the mandatory rules from the requirements (sections 3 and 5):
 * - theme is required;
 * - subtopic is required;
 * - quantity within a safe range;
 * - difficulty is one of the valid levels.
 *
 * Returns { valid: true, value } with a normalized payload, or
 * { valid: false, errors: string[] } with user-facing (pt-BR) messages.
 */
export function validateGenerateRequest(body) {
  const errors = [];
  const b = body && typeof body === 'object' ? body : {};

  const theme = typeof b.theme === 'string' ? b.theme.trim() : '';
  const subtopic = typeof b.subtopic === 'string' ? b.subtopic.trim() : '';

  if (theme === '') {
    errors.push('O tema é obrigatório.');
  }
  if (subtopic === '') {
    errors.push('O subtópico é obrigatório.');
  }

  const difficulty =
    typeof b.difficulty === 'string' ? b.difficulty.trim() : '';
  if (!VALID_DIFFICULTIES.includes(difficulty)) {
    errors.push(
      'A dificuldade deve ser "basic", "intermediate" ou "advanced".',
    );
  }

  let quantity = Number(b.quantity);
  if (!Number.isInteger(quantity) || quantity < 1) {
    errors.push('A quantidade deve ser um número inteiro maior ou igual a 1.');
  } else if (quantity > config.maxQuestionsPerRequest) {
    errors.push(
      `A quantidade máxima por geração é ${config.maxQuestionsPerRequest}.`,
    );
  }

  // Optional complementary material (plain text only in this version).
  const material =
    typeof b.material === 'string' ? b.material.trim() : '';

  // Optional: summaries of existing questions, used to avoid duplicates.
  const existingSummaries = Array.isArray(b.existingSummaries)
    ? b.existingSummaries.filter((s) => typeof s === 'string').slice(0, 50)
    : [];

  // Optional: a user-edited prompt template (with {{placeholders}}). When
  // present and non-empty, it overrides the default prompt assembly.
  const customPrompt =
    typeof b.customPrompt === 'string' && b.customPrompt.trim() !== ''
      ? b.customPrompt
      : null;

  if (errors.length > 0) {
    return { valid: false, errors };
  }

  return {
    valid: true,
    value: {
      theme,
      subtopic,
      difficulty,
      quantity,
      material,
      existingSummaries,
      customPrompt,
    },
  };
}
