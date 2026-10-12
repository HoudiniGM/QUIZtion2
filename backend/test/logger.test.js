import { redact } from '../src/logger.js';

describe('redact', () => {
  it('masks Google API keys', () => {
    const out = redact('key is AIzaSyA1234567890abcdefghijklmnop here');
    expect(out).not.toMatch(/AIzaSy/);
    expect(out).toMatch(/REDACTED/);
  });

  it('masks key/value secret pairs', () => {
    const out = redact('{"api_key":"super-secret-value","x":1}');
    expect(out).not.toMatch(/super-secret-value/);
  });

  it('leaves ordinary text untouched', () => {
    expect(redact('generation failed: timeout')).toBe(
      'generation failed: timeout',
    );
  });
});
