import { GeminiClient } from './gemini_client.js';

/**
 * Suggests a theme and topic for a free-text study description, reusing the
 * user's existing themes/topics when a close match exists.
 *
 * The AI client is injected for testability.
 */
export class Classifier {
  constructor({ client } = {}) {
    this._client = client;
  }

  /**
   * @param {{ text: string, existingThemes: {theme:string, topics:string[]}[] }} params
   * @returns {Promise<{ theme, topic, themeExists, topicExists }>}
   */
  async classify(params) {
    const prompt = buildClassifyPrompt(params);
    const { theme, topic } = await this._client.classify(prompt);

    // Reconcile with existing data (case-insensitive) so we reuse the exact
    // stored label instead of a slightly different spelling.
    const existing = params.existingThemes ?? [];
    const matchedTheme = existing.find(
      (e) => e.theme.toLowerCase() === theme.toLowerCase(),
    );

    if (matchedTheme) {
      const matchedTopic = (matchedTheme.topics ?? []).find(
        (t) => t.toLowerCase() === topic.toLowerCase(),
      );
      return {
        theme: matchedTheme.theme,
        topic: matchedTopic ?? topic,
        themeExists: true,
        topicExists: matchedTopic != null,
      };
    }

    return { theme, topic, themeExists: false, topicExists: false };
  }
}

export function buildClassifyPrompt({ text, existingThemes = [] }) {
  const parts = [
    'Você classifica uma descrição de estudo em um TEMA e um TÓPICO.',
    'O tema é a área geral (ex.: "Biologia", "Java Core", "História").',
    'O tópico é o assunto específico dentro do tema (ex.: "Genética",',
    '"Collections", "Revolução Francesa").',
    '',
    'Regras:',
    '- Responda em português.',
    '- Seja conciso: o tema e o tópico devem ser curtos (poucas palavras).',
    '- Se a descrição se encaixar em um tema/tópico já existente do usuário',
    '  (lista abaixo), REUTILIZE exatamente o mesmo nome.',
    '- Caso contrário, proponha um tema e um tópico novos e adequados.',
    '- Não invente conteúdo além de nomear o tema e o tópico.',
    '',
    `Descrição do usuário: "${text}"`,
    '',
  ];

  if (existingThemes.length > 0) {
    parts.push('Temas e tópicos já existentes do usuário:');
    for (const e of existingThemes) {
      parts.push(`- ${e.theme}: ${(e.topics ?? []).join(', ')}`);
    }
  } else {
    parts.push('O usuário ainda não tem temas cadastrados.');
  }

  return parts.join('\n');
}

/** Factory used by the server to build a real, Gemini-backed classifier. */
export function createGeminiClassifier() {
  return new Classifier({ client: new GeminiClient() });
}
