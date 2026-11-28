import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import nodemailer from 'nodemailer';

interface PasswordResetEmailPayload {
  to: string;
  fullName: string;
  resetUrl: string;
  expiresInMinutes: number;
}

interface OutgoingEmail {
  to: string;
  subject: string;
  text: string;
  html: string;
}

// mail.joypinness.com is the domain verified with Resend; the bare
// joypinness.com belongs to the Lark mailboxes and is not.
const DEFAULT_FROM = 'BookieAI <no-reply@mail.joypinness.com>';
// Nobody reads no-reply, so replies go to the shared Lark support inbox.
const DEFAULT_REPLY_TO = 'support@joypinness.com';

/**
 * Sends email through Resend (RESEND_API_KEY) when configured, otherwise
 * SMTP (SMTP_HOST etc.). With neither, nothing is sent and, outside
 * production, the content is logged for local development.
 */
@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private readonly transporter;
  private readonly resendApiKey?: string;
  private readonly fromAddress: string;
  private readonly replyTo: string;

  constructor(private configService: ConfigService) {
    this.resendApiKey = this.configService.get<string>('RESEND_API_KEY') || undefined;
    this.fromAddress =
      this.configService.get<string>('MAIL_FROM') ||
      this.configService.get<string>('SMTP_FROM') ||
      DEFAULT_FROM;
    this.replyTo = this.configService.get<string>('MAIL_REPLY_TO') || DEFAULT_REPLY_TO;

    const host = this.configService.get<string>('SMTP_HOST');
    const port = Number(this.configService.get<string>('SMTP_PORT') ?? '587');
    const user = this.configService.get<string>('SMTP_USER');
    const pass = this.configService.get<string>('SMTP_PASS');
    const secure =
      (this.configService.get<string>('SMTP_SECURE') ?? 'false').toLowerCase() === 'true';
    if (!this.resendApiKey && host && Number.isFinite(port) && port > 0) {
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure,
        auth: user && pass ? { user, pass } : undefined,
      });
    }
  }

  async sendPasswordResetEmail(payload: PasswordResetEmailPayload) {
    const intro = `Use the link below to reset your BookieAI password. The link expires in ${payload.expiresInMinutes} minutes.`;
    await this.send(
      {
        to: payload.to,
        subject: 'Reset your BookieAI password',
        text: [
          `Hi ${payload.fullName},`,
          '',
          intro,
          payload.resetUrl,
          '',
          'If you did not request this, you can ignore this email.',
        ].join('\n'),
        html: `<p>Hi ${escapeHtml(payload.fullName)},</p><p>${intro}</p><p><a href="${escapeHtml(payload.resetUrl)}">Reset my password</a></p><p>If you did not request this, you can ignore this email.</p>`,
      },
      // The link carries a live reset token.
      { secretInBody: true },
    );
  }

  private async send(email: OutgoingEmail, { secretInBody = false } = {}) {
    if (this.resendApiKey) {
      const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.resendApiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ from: this.fromAddress, reply_to: this.replyTo, ...email }),
        signal: AbortSignal.timeout(10_000),
      });
      if (!response.ok) {
        // Resend explains e.g. an unverified sender domain in the body.
        const detail = await response.text().catch(() => '');
        throw new Error(`Resend rejected the email (${response.status}): ${detail.slice(0, 300)}`);
      }
      return;
    }

    if (this.transporter) {
      await this.transporter.sendMail({ from: this.fromAddress, replyTo: this.replyTo, ...email });
      return;
    }

    const isProduction =
      this.configService.get<string>('NODE_ENV') === 'production' ||
      Boolean(this.configService.get<string>('VERCEL'));
    this.logger.warn(
      isProduction || !secretInBody
        ? `No email provider configured (set RESEND_API_KEY). "${email.subject}" to ${email.to} was not sent.`
        : `No email provider configured. "${email.subject}" to ${email.to}:\n${email.text}`,
    );
  }
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}
