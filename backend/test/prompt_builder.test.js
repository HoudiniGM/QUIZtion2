import { buildPrompt } from '../src/generation/prompt_builder.js';
import { BASE_PROMPT, PROMPT_VERSION } from '../src/generation/prompt_base.js';

const base = {
  theme: 'Biologia',
  subtopic: 'Genética',
  difficulty: 'intermediate',
  quantity: 3,
};

describe('buildPrompt', () => {
  it('returns the current prompt version', () => {
    const { promptVersion } = buildPrompt(base);
    expect(promptVersion).toBe(PROMPT_VERSION);
  });

  it('includes the permanent generic base prompt', () => {
    const { prompt } = buildPrompt(base);
    expect(prompt).toContain(BASE_PROMPT);
  });

  it('base prompt is generic: does not hardcode a discipline like Java', () => {
    // The base prompt itself must not fix any subject.
    expect(BASE_PROMPT).not.toMatch(/\bJava\b/);
    expect(BASE_PROMPT.toLowerCase()).toContain('qualquer área');
  });

  it('injects theme and subtopic dynamically', () => {
    const { prompt } = buildPrompt(base);
    expect(prompt).toContain('Biologia');
    expect(prompt).toContain('Genética');
    expect(prompt).toMatch(/especialista em "Biologia".*foco em "Genética"/s);
  });

  it('states the requested quantity and difficulty', () => {
    const { prompt } = buildPrompt({ ...base, quantity: 5 });
    expect(prompt).toMatch(/Gere 5 quest/);
    expect(prompt).toContain('intermediário');
  });

  it('includes complementary material when provided', () => {
    const { prompt } = buildPrompt({ ...base, material: 'Mendel e ervilhas' });
    expect(prompt).toContain('Mendel e ervilhas');
    expect(prompt).toMatch(/não é a única fonte permitida/i);
  });

  it('notes absence of material when none is given', () => {
    const { prompt } = buildPrompt({ ...base, material: '   ' });
    expect(prompt).toMatch(/Nenhum material complementar/i);
  });

  it('lists existing-question summaries to avoid duplicates', () => {
    const { prompt } = buildPrompt({
      ...base,
      existingSummaries: ['O que é um alelo?', 'Lei da segregação'],
    });
    expect(prompt).toMatch(/evitar duplicatas/i);
    expect(prompt).toContain('O que é um alelo?');
    expect(prompt).toContain('Lei da segregação');
  });

  it('clamps very long material', () => {
    const long = 'x'.repeat(10000);
    const { prompt } = buildPrompt({ ...base, material: long });
    expect(prompt).toContain('material truncado');
    expect(prompt.length).toBeLessThan(BASE_PROMPT.length + 9000);
  });
});
