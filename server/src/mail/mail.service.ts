import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import nodemailer from 'nodemailer';

interface PasswordResetEmailPayload {
  to: string;
  fullName: string;
  resetUrl: string;
  expiresInMinutes: number;
}

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private readonly transporter;
  private readonly fromAddress?: string;

  constructor(private configService: ConfigService) {
    const host = this.configService.get<string>('SMTP_HOST');
    const port = Number(this.configService.get<string>('SMTP_PORT') ?? '587');
    const user = this.configService.get<string>('SMTP_USER');
    const pass = this.configService.get<string>('SMTP_PASS');
    const secure = (this.configService.get<string>('SMTP_SECURE') ?? 'false').toLowerCase() === 'true';
    this.fromAddress = this.configService.get<string>('SMTP_FROM') ?? undefined;

    if (host && this.fromAddress && Number.isFinite(port) && port > 0) {
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure,
        auth: user && pass ? { user, pass } : undefined,
      });
    }
  }

  async sendPasswordResetEmail(payload: PasswordResetEmailPayload) {
    const subject = 'Reset your BookieAI password';
    const text = [
      `Hi ${payload.fullName},`,
      '',
      `Use the link below to reset your BookieAI password. The link expires in ${payload.expiresInMinutes} minutes.`,
      payload.resetUrl,
      '',
      'If you did not request this, you can ignore this email.',
    ].join('\n');

    if (!this.transporter || !this.fromAddress) {
      this.logger.warn(
        `SMTP is not configured. Password reset link for ${payload.to}: ${payload.resetUrl}`,
      );
      return;
    }

    await this.transporter.sendMail({
      from: this.fromAddress,
      to: payload.to,
      subject,
      text,
      html: `<p>Hi ${payload.fullName},</p><p>Use the link below to reset your BookieAI password. The link expires in ${payload.expiresInMinutes} minutes.</p><p><a href="${payload.resetUrl}">${payload.resetUrl}</a></p><p>If you did not request this, you can ignore this email.</p>`,
    });
  }
}