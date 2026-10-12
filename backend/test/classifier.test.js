import { jest } from '@jest/globals';

import { Classifier, buildClassifyPrompt } from '../src/generation/classifier.js';

describe('buildClassifyPrompt', () => {
  it('includes the user text and existing themes', () => {
    const prompt = buildClassifyPrompt({
      text: 'quero treinar herança e polimorfismo',
      existingThemes: [
        { theme: 'Java Core', topics: ['Collections', 'Exceções'] },
      ],
    });
    expect(prompt).toContain('herança e polimorfismo');
    expect(prompt).toContain('Java Core');
    expect(prompt).toContain('Collections');
  });

  it('notes when the user has no themes', () => {
    const prompt = buildClassifyPrompt({ text: 'x', existingThemes: [] });
    expect(prompt).toMatch(/ainda não tem temas/i);
  });
});

describe('Classifier', () => {
  it('returns the AI suggestion as new when nothing matches', async () => {
    const client = {
      classify: jest.fn(async () => ({ theme: 'Biologia', topic: 'Genética' })),
    };
    const c = new Classifier({ client });
    const out = await c.classify({ text: 'DNA e genes', existingThemes: [] });
    expect(out).toEqual({
      theme: 'Biologia',
      topic: 'Genética',
      themeExists: false,
      topicExists: false,
    });
  });

  it('reuses an existing theme/topic (case-insensitive)', async () => {
    const client = {
      classify: jest.fn(async () => ({
        theme: 'java core',
        topic: 'collections',
      })),
    };
    const c = new Classifier({ client });
    const out = await c.classify({
      text: 'listas e conjuntos',
      existingThemes: [
        { theme: 'Java Core', topics: ['Collections', 'Exceções'] },
      ],
    });
    expect(out.theme).toBe('Java Core');
    expect(out.topic).toBe('Collections');
    expect(out.themeExists).toBe(true);
    expect(out.topicExists).toBe(true);
  });

  it('reuses the theme but marks the topic as new', async () => {
    const client = {
      classify: jest.fn(async () => ({
        theme: 'Java Core',
        topic: 'Generics',
      })),
    };
    const c = new Classifier({ client });
    const out = await c.classify({
      text: 'tipos genéricos',
      existingThemes: [{ theme: 'Java Core', topics: ['Collections'] }],
    });
    expect(out.themeExists).toBe(true);
    expect(out.topicExists).toBe(false);
    expect(out.topic).toBe('Generics');
  });
});
