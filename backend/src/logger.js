/**
 * Minimal logger that redacts anything resembling a secret.
 *
 * Technical logs must never reveal API keys, secrets or sensitive config
 * (requirements, sections 16 and 17).
 */
const SECRET_PATTERNS = [
  // Google API key shape: redact the whole token.
  { re: /AIza[0-9A-Za-z\-_]{10,}/g, replace: () => '[REDACTED]' },
  // key/value secret pairs: keep the key prefix, redact only the value.
  {
    re: /("?(?:api[_-]?key|authorization|token|secret)"?\s*[:=]\s*"?)[^"\s,}]+/gi,
    replace: (_m, prefix) => `${prefix}[REDACTED]`,
  },
];

export function redact(input) {
  let text = typeof input === 'string' ? input : safeStringify(input);
  for (const { re, replace } of SECRET_PATTERNS) {
    text = text.replace(re, replace);
  }
  return text;
}

function safeStringify(value) {
  try {
    return JSON.stringify(value);
  } catch {
    return String(value);
  }
}

export const logger = {
  info(message, meta) {
    console.log(redact(message), meta ? redact(meta) : '');
  },
  warn(message, meta) {
    console.warn(redact(message), meta ? redact(meta) : '');
  },
  error(message, meta) {
    console.error(redact(message), meta ? redact(meta) : '');
  },
};
