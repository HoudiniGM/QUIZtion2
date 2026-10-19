import {
  validateQuestion,
  statementSignature,
} from '../src/generation/question_validation.js';

function validRaw(overrides = {}) {
  return {
    statement: 'Qual estrutura mantém a ordem de inserção?',
    difficulty: 'basic',
    options: [
      { text: 'ArrayList', explanation: 'Correta.', correct: true },
      { text: 'HashSet', explanation: 'Não mantém ordem.', correct: false },
      { text: 'HashMap', explanation: 'É um mapa.', correct: false },
      { text: 'TreeSet', explanation: 'Ordena por comparação.', correct: false },
    ],
    ...overrides,
  };
}

describe('validateQuestion', () => {
  it('accepts a well-formed question and assigns stable option ids', () => {
    const r = validateQuestion(validRaw(), {
      theme: 'Java Core',
      subtopic: 'Collections',
    });
    expect(r.valid).toBe(true);
    expect(r.value.options.map((o) => o.id)).toEqual(['a', 'b', 'c', 'd']);
    expect(r.value.options.filter((o) => o.correct)).toHaveLength(1);
    expect(r.value.theme).toBe('Java Core');
    expect(r.value.subtopic).toBe('Collections');
  });

  it('rejects when there are not exactly 4 options', () => {
    const r = validateQuestion(
      validRaw({ options: validRaw().options.slice(0, 3) }),
    );
    expect(r.valid).toBe(false);
    expect(r.errors.join(' ')).toMatch(/4 alternativas/);
  });

  it('rejects when no option is correct', () => {
    const opts = validRaw().options.map((o) => ({ ...o, correct: false }));
    const r = validateQuestion(validRaw({ options: opts }));
    expect(r.valid).toBe(false);
    expect(r.errors.join(' ')).toMatch(/pelo menos 1 alternativa correta/);
  });

  it('accepts a question with more than one correct option', () => {
    const opts = validRaw().options.map((o, i) => ({
      ...o,
      correct: i < 2, // two correct
    }));
    const r = validateQuestion(validRaw({ options: opts }), {
      theme: 'Java Core',
      subtopic: 'Collections',
    });
    expect(r.valid).toBe(true);
    expect(r.value.options.filter((o) => o.correct)).toHaveLength(2);
  });

  it('rejects when all options are correct', () => {
    const opts = validRaw().options.map((o) => ({ ...o, correct: true }));
    const r = validateQuestion(validRaw({ options: opts }));
    expect(r.valid).toBe(false);
    expect(r.errors.join(' ')).toMatch(/todas as alternativas/);
  });

  it('rejects an option without explanation', () => {
    const opts = validRaw().options;
    opts[1] = { ...opts[1], explanation: '' };
    const r = validateQuestion(validRaw({ options: opts }));
    expect(r.valid).toBe(false);
    expect(r.errors.join(' ')).toMatch(/sem explicação/);
  });

  it('rejects an empty statement', () => {
    const r = validateQuestion(validRaw({ statement: '  ' }));
    expect(r.valid).toBe(false);
  });

  it('rejects an invalid difficulty', () => {
    const r = validateQuestion(validRaw({ difficulty: 'hardcore' }));
    expect(r.valid).toBe(false);
  });

  it('rejects duplicate option texts', () => {
    const opts = validRaw().options;
    opts[2] = { ...opts[2], text: 'ArrayList' };
    const r = validateQuestion(validRaw({ options: opts }));
    expect(r.valid).toBe(false);
    expect(r.errors.join(' ')).toMatch(/duplicadas/);
  });

  it('rejects forbidden "all/none of the above" phrasings', () => {
    const opts = validRaw().options;
    opts[3] = {
      text: 'Nenhuma das alternativas',
      explanation: '...',
      correct: false,
    };
    const r = validateQuestion(validRaw({ options: opts }));
    expect(r.valid).toBe(false);
    expect(r.errors.join(' ')).toMatch(/todas.*nenhuma/i);
  });

  it('keeps a non-empty codeSnippet and nulls an empty one', () => {
    const withCode = validateQuestion(validRaw({ codeSnippet: 'x=1' }));
    expect(withCode.value.codeSnippet).toBe('x=1');
    const withoutCode = validateQuestion(validRaw({ codeSnippet: '   ' }));
    expect(withoutCode.value.codeSnippet).toBeNull();
  });
});

describe('statementSignature', () => {
  it('normalizes case, spaces and punctuation', () => {
    expect(statementSignature('  O que  é  um  Alelo? ')).toBe(
      statementSignature('o que é um alelo'),
    );
  });

  it('ignores only punctuation and extra whitespace, not letters', () => {
    expect(statementSignature('Lei da segregação!!!')).toBe(
      'lei da segregação',
    );
  });
});
