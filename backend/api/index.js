// Vercel serverless entry point.
//
// Vercel runs each file in `api/` as a serverless function. We build the same
// Express app used locally and export it as the handler, so routes like
// /health and /generate work unchanged. `vercel.json` rewrites all paths here.
//
// The Gemini API key is read from the environment (configured in the Vercel
// project settings) — never committed to the repo or sent to the app.

import { createApp } from '../src/app.js';
import { hasGeminiKey } from '../src/config.js';
import { logger } from '../src/logger.js';

let generator;
if (hasGeminiKey()) {
  const mod = await import('../src/generation/question_generator.js');
  generator = mod.createGeminiQuestionGenerator();
} else {
  logger.warn(
    'GEMINI_API_KEY not set; /generate will be unavailable until configured.',
  );
}

const app = createApp({ generator });

export default app;
