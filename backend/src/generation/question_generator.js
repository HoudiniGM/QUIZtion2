import { randomUUID } from 'node:crypto';

import { logger } from '../logger.js';
import { GeminiClient } from './gemini_client.js';
import {
  buildPrompt,
  buildPromptFromTemplate,
} from './prompt_builder.js';
import {
  statementSignature,
  validateQuestion,
} from './question_validation.js';

/** Hard cap on attempts to avoid loops and excessive API usage (section 17). */
const MAX_ATTEMPTS = 3;

/**
 * Orchestrates question generation:
 *  1. builds the versioned, dynamic prompt;
 *  2. calls the AI client;
 *  3. validates each returned question;
 *  4. drops duplicates (vs existing summaries and within the batch);
 *  5. retries (bounded) if not enough valid questions were produced;
 *  6. reports saved vs. failed honestly.
 *
 * The AI client is injected for testability (mocked in tests).
 */
export class QuestionGenerator {
  constructor({ client } = {}) {
    this._client = client;
  }

  /**
   * @returns {Promise<{ saved: object[], failed: number, promptVersion: string }>}
   */
  async generate(params) {
    const { quantity } = params;
    const saved = [];
    const seenSignatures = new Set(
      (params.existingSummaries ?? []).map((s) => statementSignature(s)),
    );

    let failed = 0;
    let promptVersion = null;
    let attempt = 0;

    while (saved.length < quantity && attempt < MAX_ATTEMPTS) {
      attempt++;
      const remaining = quantity - saved.length;

      const perAttemptParams = {
        ...params,
        quantity: remaining,
        // Feed back what we already have, plus the originals, to steer away
        // from duplicates on retries.
        existingSummaries: [
          ...(params.existingSummaries ?? []),
          ...saved.map((q) => q.statement),
        ],
      };
      // Use the user's custom template when provided, else the default build.
      const built = params.customPrompt
          ? buildPromptFromTemplate(params.customPrompt, perAttemptParams)
          : buildPrompt(perAttemptParams);
      promptVersion = built.promptVersion;

      let rawQuestions;
      try {
        rawQuestions = await this._client.generateQuestions(built.prompt);
      } catch (err) {
        // Keep the log short and safe; the logger also redacts secrets.
        logger.warn(
          `generation attempt ${attempt} failed`,
          shortError(err),
        );
        // Count the shortfall as failures only on the final attempt.
        if (attempt >= MAX_ATTEMPTS) {
          failed += remaining;
        }
        continue;
      }

      for (const raw of rawQuestions) {
        if (saved.length >= quantity) break;

        const result = validateQuestion(raw, {
          theme: params.theme,
          subtopic: params.subtopic,
        });
        if (!result.valid) {
          failed++;
          logger.info('question rejected', result.errors.join('; '));
          continue;
        }

        const signature = statementSignature(result.value.statement);
        if (seenSignatures.has(signature)) {
          // Local duplicate — skip without counting as a hard failure.
          continue;
        }
        seenSignatures.add(signature);

        saved.push(toSavedQuestion(result.value, params, promptVersion));
      }
    }

    return { saved, failed, promptVersion };
  }
}

/**
 * Shapes a validated question into the payload the app persists. Field names
 * match the app's Question model (statement, codeSnippet, difficulty, options
 * with id/text/explanation/correct).
 */
function toSavedQuestion(valid, params, promptVersion) {
  return {
    id: randomUUID(),
    theme: params.theme,
    subtopic: params.subtopic,
    statement: valid.statement,
    codeSnippet: valid.codeSnippet,
    difficulty: valid.difficulty,
    options: valid.options,
    promptVersion,
  };
}

/**
 * Extracts a short, single-line description from an error for logging. Avoids
 * dumping large provider error objects (which could, in some cases, embed
 * sensitive data). The logger additionally redacts secrets.
 */
function shortError(err) {
  const raw =
    (err && typeof err === 'object' && 'message' in err
      ? String(err.message)
      : String(err)) || 'unknown error';
  const firstLine = raw.split('\n')[0];
  return firstLine.length > 200 ? `${firstLine.slice(0, 200)}…` : firstLine;
}

/** Factory used by the server to build a real, Gemini-backed generator. */
export function createGeminiQuestionGenerator() {
  return new QuestionGenerator({ client: new GeminiClient() });
}
