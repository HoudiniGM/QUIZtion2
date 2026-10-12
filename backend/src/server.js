import { createApp } from './app.js';
import { config, hasGeminiKey } from './config.js';
import { logger } from './logger.js';

// The real Gemini-backed generator is wired in sub-step 2.3. Until then the
// server starts without a generator and /generate responds 503.
let generator;
try {
  const mod = await import('./generation/question_generator.js');
  if (hasGeminiKey()) {
    generator = mod.createGeminiQuestionGenerator();
  } else {
    logger.warn(
      'GEMINI_API_KEY not set; /generate will be unavailable until configured.',
    );
  }
} catch {
  // Generator module not present yet (early stages).
}

const app = createApp({ generator });

app.listen(config.port, () => {
  logger.info(`QUIZtion backend listening on port ${config.port}`);
  logger.info(`Gemini configured: ${hasGeminiKey()}`);
});
