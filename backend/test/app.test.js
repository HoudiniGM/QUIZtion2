import { jest } from '@jest/globals';
import request from 'supertest';

import { createApp } from '../src/app.js';

function validBody(overrides = {}) {
  return {
    theme: 'Java Core',
    subtopic: 'Collections',
    difficulty: 'basic',
    quantity: 3,
    ...overrides,
  };
}

describe('GET /health', () => {
  it('returns ok', async () => {
    const app = createApp({});
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body).toHaveProperty('geminiConfigured');
  });
});

describe('POST /generate validation', () => {
  const app = createApp({ generator: { generate: async () => ({ saved: [], failed: 0 }) } });

  it('rejects missing theme', async () => {
    const res = await request(app)
      .post('/generate')
      .send(validBody({ theme: '' }));
    expect(res.status).toBe(400);
    expect(res.body.error).toBe('validation_error');
    expect(res.body.messages.join(' ')).toMatch(/tema/i);
  });

  it('rejects missing subtopic', async () => {
    const res = await request(app)
      .post('/generate')
      .send(validBody({ subtopic: '' }));
    expect(res.status).toBe(400);
    expect(res.body.messages.join(' ')).toMatch(/subt[oó]pico/i);
  });

  it('rejects invalid difficulty', async () => {
    const res = await request(app)
      .post('/generate')
      .send(validBody({ difficulty: 'impossible' }));
    expect(res.status).toBe(400);
    expect(res.body.messages.join(' ')).toMatch(/dificuldade/i);
  });

  it('rejects quantity below 1', async () => {
    const res = await request(app)
      .post('/generate')
      .send(validBody({ quantity: 0 }));
    expect(res.status).toBe(400);
  });

  it('rejects quantity above the max', async () => {
    const res = await request(app)
      .post('/generate')
      .send(validBody({ quantity: 9999 }));
    expect(res.status).toBe(400);
  });
});

describe('POST /generate behavior', () => {
  it('responds 503 when no generator is configured', async () => {
    const app = createApp({});
    const res = await request(app).post('/generate').send(validBody());
    expect(res.status).toBe(503);
    expect(res.body.error).toBe('generator_unavailable');
  });

  it('returns saved questions and honest partial counts', async () => {
    const generator = {
      generate: jest.fn(async () => ({
        saved: [{ id: 'q1' }, { id: 'q2' }],
        failed: 1,
        promptVersion: 'v1',
      })),
    };
    const app = createApp({ generator });

    const res = await request(app)
      .post('/generate')
      .send(validBody({ quantity: 3 }));

    expect(res.status).toBe(200);
    expect(res.body.savedCount).toBe(2);
    expect(res.body.failedCount).toBe(1);
    expect(res.body.requested).toBe(3);
    expect(res.body.promptVersion).toBe('v1');
    expect(generator.generate).toHaveBeenCalledTimes(1);
  });

  it('returns 502 and no internal details when the generator throws', async () => {
    const generator = {
      generate: async () => {
        throw new Error('boom with AIzaSECRETKEY1234567890 inside');
      },
    };
    const app = createApp({ generator });

    const res = await request(app).post('/generate').send(validBody());
    expect(res.status).toBe(502);
    expect(res.body.error).toBe('generation_failed');
    expect(JSON.stringify(res.body)).not.toMatch(/AIza/);
  });
});
