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
let classifier;
if (hasGeminiKey()) {
  const genMod = await import('../src/generation/question_generator.js');
  generator = genMod.createGeminiQuestionGenerator();
  const classifyMod = await import('../src/generation/classifier.js');
  classifier = classifyMod.createGeminiClassifier();
} else {
  logger.warn(
    'GEMINI_API_KEY not set; /generate and /classify will be unavailable.',
  );
}

const app = createApp({ generator, classifier });

export default app;
