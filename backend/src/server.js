import { createApp } from './app.js';
import { config, hasGeminiKey } from './config.js';
import { logger } from './logger.js';

// Real Gemini-backed services are wired only when a key is configured.
let generator;
let classifier;
if (hasGeminiKey()) {
  const genMod = await import('./generation/question_generator.js');
  generator = genMod.createGeminiQuestionGenerator();
  const classifyMod = await import('./generation/classifier.js');
  classifier = classifyMod.createGeminiClassifier();
} else {
  logger.warn(
    'GEMINI_API_KEY not set; /generate and /classify will be unavailable ' +
      'until configured.',
  );
}

const app = createApp({ generator, classifier });

app.listen(config.port, () => {
  logger.info(`QUIZtion backend listening on port ${config.port}`);
  logger.info(`Gemini configured: ${hasGeminiKey()}`);
});
