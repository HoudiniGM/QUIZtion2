import { buildPromptFromTemplate } from '../src/generation/prompt_builder.js';
import {
  DEFAULT_PROMPT_TEMPLATE,
  PROMPT_PLACEHOLDERS,
} from '../src/generation/prompt_base.js';

const params = {
  theme: 'Biologia',
  subtopic: 'Genética',
  difficulty: 'intermediate',
  quantity: 3,
  material: 'Mendel',
  existingSummaries: ['O que é um alelo?'],
};

describe('buildPromptFromTemplate', () => {
  it('substitutes all placeholders with real values', () => {
    const tpl =
        'T={{theme}} S={{subtopic}} D={{difficulty}} Q={{quantity}} ' +
        'M={{material}} E={{existing}}';
    const { prompt, promptVersion } = buildPromptFromTemplate(tpl, params);
    expect(promptVersion).toBe('custom');
    expect(prompt).toContain('T=Biologia');
    expect(prompt).toContain('S=Genética');
    expect(prompt).toContain('D=intermediário'); // label, not the id
    expect(prompt).toContain('Q=3');
    expect(prompt).toContain('M=Mendel');
    expect(prompt).toContain('O que é um alelo?');
    // No leftover placeholder tokens.
    expect(prompt).not.toMatch(/\{\{\s*\w+\s*\}\}/);
  });

  it('uses friendly fallbacks when material/existing are empty', () => {
    const tpl = 'M={{material}} E={{existing}}';
    const { prompt } = buildPromptFromTemplate(tpl, {
      ...params,
      material: '',
      existingSummaries: [],
    });
    expect(prompt).toContain('M=(nenhum)');
    expect(prompt).toContain('E=(nenhuma)');
  });

  it('leaves unknown placeholders untouched', () => {
    const { prompt } = buildPromptFromTemplate('X={{unknown}}', params);
    expect(prompt).toContain('X={{unknown}}');
  });

  it('the default template contains every documented placeholder', () => {
    for (const p of PROMPT_PLACEHOLDERS) {
      expect(DEFAULT_PROMPT_TEMPLATE).toContain(`{{${p}}}`);
    }
  });
});
