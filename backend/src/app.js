import express from 'express';
import cors from 'cors';

import { hasGeminiKey } from './config.js';
import { logger } from './logger.js';
import { validateClassifyRequest } from './validation/classify_validation.js';
import { validateGenerateRequest } from './validation/request_validation.js';

/**
 * Builds the Express app.
 *
 * The question generator is injected so it can be mocked in tests and swapped
 * for the real Gemini-backed implementation in production. It must expose:
 *   async generate(params) -> { saved: Question[], failed: number, promptVersion }
 */
export function createApp({ generator, classifier } = {}) {
  const app = express();

  // Allow all origins (personal MVP). Explicitly enable preflight for all
  // routes so browser (Flutter web) cross-origin POSTs with JSON work.
  app.use(cors());
  app.options('*', cors());
  app.use(express.json({ limit: '256kb' }));

  // Lightweight request log so it is visible in the terminal whether the
  // app's requests are reaching the server at all (helps diagnose connection
  // vs. CORS issues). Does not log bodies/secrets.
  app.use((req, _res, next) => {
    logger.info(`${req.method} ${req.path} from ${req.ip}`);
    next();
  });

  // Health check — never reveals secrets, only whether a key is configured.
  app.get('/health', (_req, res) => {
    res.json({
      status: 'ok',
      geminiConfigured: hasGeminiKey(),
    });
  });

  app.post('/generate', async (req, res) => {
    const result = validateGenerateRequest(req.body);
    if (!result.valid) {
      return res.status(400).json({
        error: 'validation_error',
        messages: result.errors,
      });
    }

    if (!generator) {
      return res.status(503).json({
        error: 'generator_unavailable',
        messages: ['O serviço de geração não está disponível no momento.'],
      });
    }

    try {
      const output = await generator.generate(result.value);
      // Honest partial-generation reporting (requirements, section 12).
      return res.status(200).json({
        saved: output.saved,
        savedCount: output.saved.length,
        failedCount: output.failed ?? 0,
        requested: result.value.quantity,
        promptVersion: output.promptVersion ?? null,
      });
    } catch (err) {
      // Log for diagnosis (redacted), but never leak secrets or internal
      // details to the client.
      logger.error('generation_failed', err?.message ?? String(err));
      return res.status(502).json({
        error: 'generation_failed',
        messages: [
          'Não foi possível gerar as questões agora. Tente novamente.',
        ],
      });
    }
  });

  app.post('/classify', async (req, res) => {
    const result = validateClassifyRequest(req.body);
    if (!result.valid) {
      return res.status(400).json({
        error: 'validation_error',
        messages: result.errors,
      });
    }

    if (!classifier) {
      return res.status(503).json({
        error: 'classifier_unavailable',
        messages: ['O serviço de sugestão não está disponível no momento.'],
      });
    }

    try {
      const suggestion = await classifier.classify(result.value);
      return res.status(200).json(suggestion);
    } catch (err) {
      logger.error('classify_failed', err?.message ?? String(err));
      return res.status(502).json({
        error: 'classify_failed',
        messages: [
          'Não foi possível sugerir um tema agora. Tente novamente.',
        ],
      });
    }
  });

  // 404 fallback.
  app.use((_req, res) => {
    res.status(404).json({ error: 'not_found' });
  });

  return app;
}
