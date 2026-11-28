import {
  createCipheriv,
  createDecipheriv,
  hkdfSync,
  randomBytes,
} from 'node:crypto';

const PREFIX = 'v1:';

/**
 * AES-256-GCM encryption for third-party OAuth tokens stored in the
 * database. The key is TOKEN_ENCRYPTION_KEY (32 bytes, base64) when set,
 * otherwise derived from JWT_SECRET with HKDF so no new secret is required.
 * Rotating either secret makes stored tokens unreadable (users reconnect).
 */
export class TokenCipher {
  private readonly key: Buffer;

  constructor(secrets: { encryptionKey?: string; jwtSecret?: string }) {
    if (secrets.encryptionKey) {
      const key = Buffer.from(secrets.encryptionKey, 'base64');
      if (key.length !== 32) {
        throw new Error('TOKEN_ENCRYPTION_KEY must be 32 bytes, base64-encoded');
      }
      this.key = key;
    } else if (secrets.jwtSecret) {
      this.key = Buffer.from(
        hkdfSync(
          'sha256',
          secrets.jwtSecret,
          'bookie-ai',
          'connected-account-tokens',
          32,
        ),
      );
    } else {
      throw new Error('TOKEN_ENCRYPTION_KEY or JWT_SECRET must be set');
    }
  }

  encrypt(plain: string): string;
  encrypt(plain: string | null | undefined): string | null;
  encrypt(plain: string | null | undefined): string | null {
    if (plain == null || plain === '') return null;
    const iv = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', this.key, iv);
    const body = Buffer.concat([cipher.update(plain, 'utf8'), cipher.final()]);
    const tag = cipher.getAuthTag();
    return PREFIX + Buffer.concat([iv, tag, body]).toString('base64');
  }

  /** Decrypts a stored value; values saved before encryption pass through. */
  decrypt(stored: string | null | undefined): string | null {
    if (stored == null || stored === '') return null;
    if (!stored.startsWith(PREFIX)) return stored;
    const raw = Buffer.from(stored.slice(PREFIX.length), 'base64');
    const decipher = createDecipheriv('aes-256-gcm', this.key, raw.subarray(0, 12));
    decipher.setAuthTag(raw.subarray(12, 28));
    return Buffer.concat([
      decipher.update(raw.subarray(28)),
      decipher.final(),
    ]).toString('utf8');
  }
}
