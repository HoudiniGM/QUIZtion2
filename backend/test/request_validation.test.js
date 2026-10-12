import { validateGenerateRequest } from '../src/validation/request_validation.js';

describe('validateGenerateRequest', () => {
  const base = {
    theme: 'Biologia',
    subtopic: 'Genética',
    difficulty: 'intermediate',
    quantity: 5,
  };

  it('accepts a well-formed request and normalizes it', () => {
    const r = validateGenerateRequest({
      ...base,
      theme: '  Biologia  ',
      material: '  texto  ',
    });
    expect(r.valid).toBe(true);
    expect(r.value.theme).toBe('Biologia');
    expect(r.value.material).toBe('texto');
    expect(r.value.existingSummaries).toEqual([]);
  });

  it('collects all errors when multiple fields are invalid', () => {
    const r = validateGenerateRequest({});
    expect(r.valid).toBe(false);
    expect(r.errors.length).toBeGreaterThanOrEqual(3);
  });

  it('keeps at most 50 existing summaries', () => {
    const summaries = Array.from({ length: 80 }, (_, i) => `q${i}`);
    const r = validateGenerateRequest({ ...base, existingSummaries: summaries });
    expect(r.valid).toBe(true);
    expect(r.value.existingSummaries.length).toBe(50);
  });

  it('rejects a non-integer quantity', () => {
    const r = validateGenerateRequest({ ...base, quantity: 2.5 });
    expect(r.valid).toBe(false);
  });
});
