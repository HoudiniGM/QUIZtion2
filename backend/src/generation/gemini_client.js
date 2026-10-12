import { GoogleGenAI, Type } from '@google/genai';

import { config } from '../config.js';

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
  constructor({ apiKey = config.geminiApiKey, model = config.geminiModel } = {}) {
    this._model = model;
    this._ai = new GoogleGenAI({ apiKey });
  }

  /**
   * Sends the prompt and returns parsed raw questions: Array<object>.
   * Throws on network/API errors or if the response is not parseable.
   */
  async generateQuestions(prompt) {
    const response = await this._ai.models.generateContent({
      model: this._model,
      contents: prompt,
      config: {
        responseMimeType: 'application/json',
        responseSchema: RESPONSE_SCHEMA,
        temperature: 0.7,
      },
    });

    const text = response?.text ?? '';
    let parsed;
    try {
      parsed = JSON.parse(text);
    } catch {
      throw new Error('A resposta da IA não é um JSON válido.');
    }

    const questions = parsed?.questions;
    if (!Array.isArray(questions)) {
      throw new Error('A resposta da IA não contém uma lista de questões.');
    }
    return questions;
  }
}
