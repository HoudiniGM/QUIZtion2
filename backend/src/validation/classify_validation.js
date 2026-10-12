/**
 * Validates the body of a POST /classify request.
 *
 * The user describes, in free text, what they want to study; the AI suggests a
 * theme and a topic. We also accept the list of themes/topics the user already
 * has, so the AI can reuse an existing one instead of inventing a near-duplicate.
 *
 * Returns { valid: true, value } or { valid: false, errors: string[] }.
 */
export function validateClassifyRequest(body) {
  const errors = [];
  const b = body && typeof body === 'object' ? body : {};

  const text = typeof b.text === 'string' ? b.text.trim() : '';
  if (text === '') {
    errors.push('Descreva o que você quer estudar.');
  } else if (text.length > 2000) {
    errors.push('A descrição é muito longa (máximo de 2000 caracteres).');
  }

  // Optional existing structure: [{ theme, topics: [..] }].
  const existing = Array.isArray(b.existingThemes)
    ? b.existingThemes
        .filter((e) => e && typeof e === 'object')
        .slice(0, 50)
        .map((e) => ({
          theme: typeof e.theme === 'string' ? e.theme.trim() : '',
          topics: Array.isArray(e.topics)
            ? e.topics
                .filter((t) => typeof t === 'string')
                .map((t) => t.trim())
                .filter((t) => t !== '')
                .slice(0, 50)
            : [],
        }))
        .filter((e) => e.theme !== '')
    : [];

  if (errors.length > 0) {
    return { valid: false, errors };
  }
  return { valid: true, value: { text, existingThemes: existing } };
}
