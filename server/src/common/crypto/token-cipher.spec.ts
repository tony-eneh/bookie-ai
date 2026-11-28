import { TokenCipher } from './token-cipher.js';

describe('TokenCipher', () => {
  const cipher = new TokenCipher({ jwtSecret: 'test-secret' });

  it('round-trips and never stores the plaintext', () => {
    const stored = cipher.encrypt('ya29.secret-token');
    expect(stored).toMatch(/^v1:/);
    expect(stored).not.toContain('secret-token');
    expect(cipher.decrypt(stored)).toBe('ya29.secret-token');
  });

  it('uses a fresh IV each time', () => {
    expect(cipher.encrypt('same')).not.toBe(cipher.encrypt('same'));
  });

  it('passes through legacy plaintext and empty values', () => {
    expect(cipher.decrypt('legacy-plain')).toBe('legacy-plain');
    expect(cipher.encrypt(undefined)).toBeNull();
    expect(cipher.decrypt(null)).toBeNull();
  });

  it('cannot be read with a different key', () => {
    const other = new TokenCipher({ jwtSecret: 'other-secret' });
    expect(() => other.decrypt(cipher.encrypt('x'))).toThrow();
  });

  it('accepts an explicit 32-byte key and rejects bad lengths', () => {
    const key = Buffer.alloc(32, 7).toString('base64');
    const explicit = new TokenCipher({ encryptionKey: key });
    expect(explicit.decrypt(explicit.encrypt('t'))).toBe('t');
    expect(() => new TokenCipher({ encryptionKey: 'c2hvcnQ=' })).toThrow();
  });
});
