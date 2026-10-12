import dotenv from 'dotenv';

dotenv.config();

/**
 * Centralized configuration, read from environment variables.
 *
 * The Gemini API key is intentionally NOT exported anywhere that could reach a
 * client. It is read here and used only by the server-side Gemini client.
 */
export const config = {
  port: Number(process.env.PORT) || 3000,
  geminiApiKey: process.env.GEMINI_API_KEY || '',
  geminiModel: process.env.GEMINI_MODEL || 'gemini-3.8-flash',
  maxQuestionsPerRequest: Number(process.env.MAX_QUESTIONS_PER_REQUEST) || 10,
};

/** Whether a Gemini API key is configured (without revealing it). */
export function hasGeminiKey() {
  return config.geminiApiKey.trim().length > 0;
}
