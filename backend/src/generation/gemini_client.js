import { GoogleGenAI, Type } from '@google/genai';

import { config } from '../config.js';
import { logger } from '../logger.js';

/**
 * JSON schema describing the structured output we want from the model:
 * an array of questions, each with a statement, optional code snippet,
 * difficulty and exactly four options (text, explanation, correct).
 *
 * Using a response schema makes the model return parseable JSON instead of
 * free-form text, which is far more reliable to validate.
 */
const RESPONSE_SCHEMA = {
  type: Type.OBJECT,
  properties: {
    questions: {
      type: Type.ARRAY,
      items: {
        type: Type.OBJECT,
        properties: {
          statement: { type: Type.STRING },
          codeSnippet: { type: Type.STRING, nullable: true },
          difficulty: {
            type: Type.STRING,
            enum: ['basic', 'intermediate', 'advanced'],
          },
          options: {
            type: Type.ARRAY,
            items: {
              type: Type.OBJECT,
              properties: {
                text: { type: Type.STRING },
                explanation: { type: Type.STRING },
                correct: { type: Type.BOOLEAN },
              },
              required: ['text', 'explanation', 'correct'],
            },
          },
        },
        required: ['statement', 'difficulty', 'options'],
      },
    },
  },
  required: ['questions'],
};

/**
 * Thin wrapper over the Gemini API that returns an array of raw question
 * objects for a given prompt. It does NOT validate the questions — validation
 * is a separate, explicit step.
 *
 * The API key is read from config (env) and never leaves the server.
 */
export class GeminiClient {
  constructor({
    apiKey = config.geminiApiKey,
    model = config.geminiModel,
    timeoutMs = 45000,
  } = {}) {
    this._model = model;
    this._timeoutMs = timeoutMs;
    this._ai = new GoogleGenAI({ apiKey });
  }

  /**
   * Sends a prompt expecting structured JSON matching [schema] and returns the
   * parsed object. Throws on network/API errors, timeout, or invalid JSON.
   */
  async generateJson(prompt, schema, { temperature = 0.7 } = {}) {
    const started = Date.now();
    logger.info(`gemini call started (model=${this._model})`);

    let response;
    try {
      response = await withTimeout(
        this._ai.models.generateContent({
          model: this._model,
          contents: prompt,
          config: {
            responseMimeType: 'application/json',
            responseSchema: schema,
            temperature,
            // Gemini 3.x models reason internally by default, which can add
            // very high latency. "low" keeps responses fast. (On Gemini 3,
            // thinkingLevel is the supported control; thinkingBudget is
            // ignored.)
            thinkingConfig: { thinkingLevel: 'low' },
          },
        }),
        this._timeoutMs,
      );
    } finally {
      logger.info(`gemini call finished in ${Date.now() - started}ms`);
    }

    const text = response?.text ?? '';
    try {
      return JSON.parse(text);
    } catch {
      throw new Error('A resposta da IA não é um JSON válido.');
    }
  }

  /**
   * Sends the prompt and returns parsed raw questions: Array<object>.
   */
  async generateQuestions(prompt) {
    const parsed = await this.generateJson(prompt, RESPONSE_SCHEMA);
    const questions = parsed?.questions;
    if (!Array.isArray(questions)) {
      throw new Error('A resposta da IA não contém uma lista de questões.');
    }
    return questions;
  }

  /**
   * Classifies free text into a suggested theme and topic.
   * Returns { theme, topic } (strings).
   */
  async classify(prompt) {
    const parsed = await this.generateJson(prompt, CLASSIFY_SCHEMA, {
      temperature: 0.2,
    });
    const theme = typeof parsed?.theme === 'string' ? parsed.theme.trim() : '';
    const topic = typeof parsed?.topic === 'string' ? parsed.topic.trim() : '';
    if (theme === '' || topic === '') {
      throw new Error('A IA não retornou tema e tópico válidos.');
    }
    return { theme, topic };
  }
}

/// Schema for the classification response.
const CLASSIFY_SCHEMA = {
  type: Type.OBJECT,
  properties: {
    theme: { type: Type.STRING },
    topic: { type: Type.STRING },
  },
  required: ['theme', 'topic'],
};

/** Rejects if the promise does not settle within `ms` milliseconds. */
function withTimeout(promise, ms) {
  let timer;
  const timeout = new Promise((_resolve, reject) => {
    timer = setTimeout(
      () => reject(new Error(`Tempo limite de ${ms}ms excedido na IA.`)),
      ms,
    );
  });
  return Promise.race([promise, timeout]).finally(() => clearTimeout(timer));
}
