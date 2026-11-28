import { ConfigService } from '@nestjs/config';
import { MailService } from './mail.service.js';

const config = (values: Record<string, string>) =>
  ({ get: (k: string) => values[k] }) as unknown as ConfigService;

const reset = {
  to: 'ada@example.com',
  fullName: 'Ada <b>',
  resetUrl: 'https://api.test/api/auth/reset-password?token=abc',
  expiresInMinutes: 30,
};

describe('MailService', () => {
  afterEach(() => jest.restoreAllMocks());

  it('sends through Resend when RESEND_API_KEY is set', async () => {
    const fetchSpy = jest
      .spyOn(global, 'fetch')
      .mockResolvedValue(new Response('{"id":"1"}', { status: 200 }));
    await new MailService(
      config({ RESEND_API_KEY: 're_test', MAIL_FROM: 'BookieAI <hi@joypinness.com>' }),
    ).sendPasswordResetEmail(reset);

    const [url, init] = fetchSpy.mock.calls[0];
    expect(url).toBe('https://api.resend.com/emails');
    const body = JSON.parse((init as RequestInit).body as string);
    expect(body).toMatchObject({
      from: 'BookieAI <hi@joypinness.com>',
      to: 'ada@example.com',
      subject: 'Reset your BookieAI password',
    });
    expect(body.html).toContain('Ada &lt;b&gt;'); // escaped
    expect((init as RequestInit).headers).toMatchObject({
      Authorization: 'Bearer re_test',
    });
  });

  it('sends replies to the support inbox, from the verified domain, by default', async () => {
    const fetchSpy = jest
      .spyOn(global, 'fetch')
      .mockResolvedValue(new Response('{"id":"1"}', { status: 200 }));
    await new MailService(config({ RESEND_API_KEY: 're_test' })).sendPasswordResetEmail(reset);

    const body = JSON.parse((fetchSpy.mock.calls[0][1] as RequestInit).body as string);
    expect(body.from).toBe('BookieAI <no-reply@mail.joypinness.com>');
    expect(body.reply_to).toBe('support@joypinness.com');
  });

  it('lets MAIL_REPLY_TO override the reply address', async () => {
    const fetchSpy = jest
      .spyOn(global, 'fetch')
      .mockResolvedValue(new Response('{"id":"1"}', { status: 200 }));
    await new MailService(
      config({ RESEND_API_KEY: 're_test', MAIL_REPLY_TO: 'help@example.com' }),
    ).sendPasswordResetEmail(reset);

    const body = JSON.parse((fetchSpy.mock.calls[0][1] as RequestInit).body as string);
    expect(body.reply_to).toBe('help@example.com');
  });

  it('surfaces Resend errors (e.g. unverified domain)', async () => {
    jest
      .spyOn(global, 'fetch')
      .mockResolvedValue(new Response('{"message":"domain not verified"}', { status: 403 }));
    await expect(
      new MailService(config({ RESEND_API_KEY: 're_test' })).sendPasswordResetEmail(reset),
    ).rejects.toThrow(/domain not verified/);
  });

  it('never logs the reset link in production when nothing is configured', async () => {
    const warn = jest.spyOn(console, 'warn').mockImplementation(() => undefined);
    const logSpy = jest.fn();
    const service = new MailService(config({ VERCEL: '1' }));
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    (service as any).logger = { warn: logSpy };
    await service.sendPasswordResetEmail(reset);
    expect(logSpy.mock.calls[0][0]).not.toContain('token=abc');
    warn.mockRestore();
  });
});
