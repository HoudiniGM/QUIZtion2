import { jest } from '@jest/globals';

import { QuestionGenerator } from '../src/generation/question_generator.js';

function rawQuestion(statement, { correctIndex = 0 } = {}) {
  return {
    statement,
    difficulty: 'basic',
    options: ['A', 'B', 'C', 'D'].map((t, i) => ({
      text: `${t} - ${statement}`,
      explanation: `exp ${t}`,
      correct: i === correctIndex,
    })),
  };
}

const baseParams = {
  theme: 'Biologia',
  subtopic: 'Genética',
  difficulty: 'basic',
  quantity: 2,
  material: '',
  existingSummaries: [],
};

describe('QuestionGenerator', () => {
  it('returns all questions when the AI output is fully valid', async () => {
    const client = {
      generateQuestions: jest.fn(async () => [
        rawQuestion('Pergunta 1'),
        rawQuestion('Pergunta 2'),
      ]),
    };
    const gen = new QuestionGenerator({ client });

    const out = await gen.generate(baseParams);

    expect(out.saved).toHaveLength(2);
    expect(out.failed).toBe(0);
    expect(out.promptVersion).toBe('v1');
    expect(client.generateQuestions).toHaveBeenCalledTimes(1);

    // Shape expected by the app.
    const q = out.saved[0];
    expect(q).toMatchObject({
      theme: 'Biologia',
      subtopic: 'Genética',
      difficulty: 'basic',
      promptVersion: 'v1',
    });
    expect(typeof q.id).toBe('string');
    expect(q.options).toHaveLength(4);
    expect(q.options.map((o) => o.id)).toEqual(['a', 'b', 'c', 'd']);
  });

  it('saves only valid questions and reports the failed count honestly',
    async () => {
    const invalid = rawQuestion('Inválida');
    invalid.options = invalid.options.slice(0, 3); // only 3 options -> invalid
    const client = {
      generateQuestions: jest.fn(async () => [
        rawQuestion('Boa 1'),
        invalid,
        rawQuestion('Boa 2'),
      ]),
    };
    const gen = new QuestionGenerator({ client });

    const out = await gen.generate({ ...baseParams, quantity: 2 });

    expect(out.saved.map((q) => q.statement)).toEqual(['Boa 1', 'Boa 2']);
    expect(out.failed).toBe(1);
  });

  it('skips questions duplicating an existing summary', async () => {
    const client = {
      generateQuestions: jest.fn(async () => [
        rawQuestion('O que é um alelo?'),
        rawQuestion('Pergunta nova'),
      ]),
    };
    const gen = new QuestionGenerator({ client });

    const out = await gen.generate({
      ...baseParams,
      quantity: 2,
      existingSummaries: ['O que é um alelo?'],
    });

    // The duplicate is skipped; only the new question is saved.
    expect(out.saved.map((q) => q.statement)).toEqual(['Pergunta nova']);
  });

  it('skips duplicates within the same batch', async () => {
    const client = {
      generateQuestions: jest.fn(async () => [
        rawQuestion('Mesma pergunta'),
        rawQuestion('Mesma pergunta'),
      ]),
    };
    const gen = new QuestionGenerator({ client });

    const out = await gen.generate({ ...baseParams, quantity: 2 });
    expect(out.saved).toHaveLength(1);
  });

  it('retries when the client throws, up to the attempt limit', async () => {
    let calls = 0;
    const client = {
      generateQuestions: jest.fn(async () => {
        calls++;
        if (calls === 1) throw new Error('temporary');
        return [rawQuestion('Depois da falha 1'), rawQuestion('Depois da falha 2')];
      }),
    };
    const gen = new QuestionGenerator({ client });

    const out = await gen.generate({ ...baseParams, quantity: 2 });
    expect(client.generateQuestions).toHaveBeenCalledTimes(2);
    expect(out.saved).toHaveLength(2);
  });

  it('does not loop forever and reports failures when the client keeps failing',
    async () => {
    const client = {
      generateQuestions: jest.fn(async () => {
        throw new Error('always down');
      }),
    };
    const gen = new QuestionGenerator({ client });

    const out = await gen.generate({ ...baseParams, quantity: 2 });
    expect(client.generateQuestions).toHaveBeenCalledTimes(3); // MAX_ATTEMPTS
    expect(out.saved).toHaveLength(0);
    expect(out.failed).toBe(2);
  });
});
