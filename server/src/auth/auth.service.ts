import {
  BadRequestException,
  ConflictException,
  Injectable,
  ServiceUnavailableException,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { hash, compare } from 'bcryptjs';
import { OAuth2Client, type TokenPayload } from 'google-auth-library';
import { EmailQueueService } from '../mail/email-queue.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { UsersService } from '../users/users.service.js';
import type { GoogleAuthDto } from './dto/google-auth.dto.js';
import type { RegisterDto } from './dto/register.dto.js';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private readonly googleClient = new OAuth2Client();

  constructor(
    private prisma: PrismaService,
    private usersService: UsersService,
    private jwtService: JwtService,
    private configService: ConfigService,
    private emailQueueService: EmailQueueService,
  ) {}

  async register(dto: RegisterDto) {
    const existing = await this.usersService.findByEmail(dto.email);
    if (existing) {
      throw new ConflictException('Email already registered');
    }

    const passwordHash = await hash(dto.password, 12);

    const user = await this.prisma.$transaction(async (tx) => {
      const created = await tx.user.create({
        data: {
          email: dto.email.trim().toLowerCase(),
          passwordHash,
          fullName: dto.fullName,
          primaryCurrency: dto.primaryCurrency,
          incomeStyle: dto.incomeStyle,
          financialPersonality: dto.financialPersonality,
          onboardingCompleted: true,
        },
      });

      // Every user starts with one account in their own currency.
      await tx.account.create({
        data: {
          userId: created.id,
          name: 'Main Account',
          type: 'BANK',
          currency: created.primaryCurrency,
          isPrimary: true,
        },
      });
      return created;
    });

    const tokens = await this.generateTokens(user.id, user.email);
    return { user: publicUser(user), ...tokens };
  }

  async login(userId: string) {
    const user = await this.usersService.findById(userId);
    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    const tokens = await this.generateTokens(user.id, user.email);
    return { user: publicUser(user), ...tokens };
  }

  async validateUser(email: string, password: string) {
    const user = await this.usersService.findByEmail(email);
    if (!user || !user.passwordHash) {
      return null;
    }

    const isValid = await compare(password, user.passwordHash);
    if (!isValid) {
      return null;
    }

    return { id: user.id, email: user.email, fullName: user.fullName };
  }

  async refreshTokens(refreshToken: string) {
    const stored = await this.prisma.refreshToken.findUnique({
      where: { token: refreshToken },
      include: { user: true },
    });

    if (!stored || stored.expiresAt < new Date()) {
      if (stored) {
        await this.prisma.refreshToken.delete({ where: { id: stored.id } });
      }
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    // Delete old token
    await this.prisma.refreshToken.delete({ where: { id: stored.id } });

    // Generate new token pair
    return this.generateTokens(stored.user.id, stored.user.email);
  }

  async logout(userId: string, refreshToken: string) {
    await this.prisma.refreshToken.deleteMany({
      where: { userId, token: refreshToken },
    });
    return { message: 'Logged out successfully' };
  }

  /**
   * [defaultPageUrl] is the reset page served by this API; PASSWORD_RESET_URL
   * overrides it (e.g. for a future web app).
   */
  async forgotPassword(email: string, defaultPageUrl?: string) {
    const user = await this.usersService.findByEmail(email);
    if (!user) {
      return { message: 'If the email exists, a reset link has been sent' };
    }

    const expiresInMinutes = this.getPositiveNumberEnv(
      'RESET_PASSWORD_EXPIRATION_MINUTES',
      30,
    );
    const resetToken = randomBytes(32).toString('hex');
    const tokenHash = this.hashOpaqueToken(resetToken);
    const pageUrl =
      this.configService.get<string>('PASSWORD_RESET_URL') ??
      defaultPageUrl ??
      'http://localhost:3000/api/auth/reset-password';
    const resetUrl = `${pageUrl}?token=${resetToken}`;

    await this.prisma.$transaction(async (tx) => {
      await tx.passwordResetToken.deleteMany({
        where: { userId: user.id, usedAt: null },
      });

      await tx.passwordResetToken.create({
        data: {
          userId: user.id,
          tokenHash,
          expiresAt: new Date(Date.now() + expiresInMinutes * 60 * 1000),
        },
      });
    });

    await this.emailQueueService.enqueuePasswordResetEmail({
      to: user.email,
      fullName: user.fullName,
      resetUrl,
      expiresInMinutes,
    });

    return { message: 'If the email exists, a reset link has been sent' };
  }

  async resetPassword(token: string, newPassword: string) {
    const tokenHash = this.hashOpaqueToken(token);
    const storedToken = await this.prisma.passwordResetToken.findUnique({
      where: { tokenHash },
      include: { user: true },
    });

    if (!storedToken || storedToken.usedAt || storedToken.expiresAt < new Date()) {
      throw new BadRequestException('Invalid or expired password reset token');
    }

    const passwordHash = await hash(newPassword, 12);

    await this.prisma.$transaction(async (tx) => {
      await tx.user.update({
        where: { id: storedToken.userId },
        data: { passwordHash },
      });

      await tx.refreshToken.deleteMany({
        where: { userId: storedToken.userId },
      });

      await tx.passwordResetToken.update({
        where: { id: storedToken.id },
        data: { usedAt: new Date() },
      });

      await tx.passwordResetToken.deleteMany({
        where: {
          userId: storedToken.userId,
          id: { not: storedToken.id },
        },
      });
    });

    return { message: 'Password reset successfully' };
  }

  async googleAuth(dto: GoogleAuthDto) {
    const allowedClientIds = (this.configService.get<string>('GOOGLE_CLIENT_ID') ?? '')
      .split(',')
      .map((value) => value.trim())
      .filter(Boolean);

    if (allowedClientIds.length === 0) {
      throw new ServiceUnavailableException(
        'Google sign-in is not available right now',
      );
    }

    let payload: TokenPayload | undefined;
    try {
      const ticket = await this.googleClient.verifyIdToken({
        idToken: dto.idToken,
        audience: allowedClientIds,
      });
      payload = ticket.getPayload();
    } catch {
      // Expired, malformed or wrong-audience tokens are the client's problem.
      throw new UnauthorizedException('Invalid Google sign-in token');
    }

    if (!payload?.email || !payload.email_verified) {
      throw new UnauthorizedException('Google account email is not verified');
    }

    if (dto.email && dto.email.toLowerCase() !== payload.email.toLowerCase()) {
      throw new BadRequestException('Provided email does not match the verified Google token');
    }

    let user = await this.usersService.findByEmail(payload.email);

    if (!user) {
      user = await this.prisma.$transaction(async (tx) => {
        const createdUser = await tx.user.create({
          data: {
            email: payload.email!.toLowerCase(),
            fullName: dto.fullName ?? payload.name ?? 'Google User',
          },
        });

        await tx.account.create({
          data: {
            userId: createdUser.id,
            name: 'Main Account',
            type: 'BANK',
            currency: createdUser.primaryCurrency,
            isPrimary: true,
          },
        });

        return createdUser;
      });
    }

    const connectedAccount = await this.prisma.connectedAccount.findFirst({
      where: {
        userId: user.id,
        providerType: 'google',
        providerEmail: payload.email,
      },
    });

    if (connectedAccount) {
      await this.prisma.connectedAccount.update({
        where: { id: connectedAccount.id },
        data: { status: 'ACTIVE' },
      });
    } else {
      await this.prisma.connectedAccount.create({
        data: {
          userId: user.id,
          providerType: 'google',
          providerEmail: payload.email,
        },
      });
    }

    return this.login(user.id);
  }

  async generateTokens(userId: string, email: string) {
    const payload = { sub: userId, email };

    const accessToken = this.jwtService.sign(payload);

    const refreshToken = randomUUID();
    const refreshExpirationDays = Number(
      this.configService.get<string>('JWT_REFRESH_EXPIRATION_DAYS') ?? '7',
    );

    if (!Number.isFinite(refreshExpirationDays) || refreshExpirationDays <= 0) {
      throw new Error('JWT_REFRESH_EXPIRATION_DAYS must be a positive number');
    }

    await this.prisma.refreshToken.create({
      data: {
        userId,
        token: refreshToken,
        expiresAt: new Date(
          Date.now() + refreshExpirationDays * 24 * 60 * 60 * 1000,
        ),
      },
    });

    return { accessToken, refreshToken };
  }

  async getCurrentUser(userId: string) {
    const user = await this.usersService.findById(userId);
    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    const { passwordHash: _, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }

  private hashOpaqueToken(token: string) {
    return createHash('sha256').update(token).digest('hex');
  }

  private getPositiveNumberEnv(key: string, fallback: number) {
    const rawValue = this.configService.get<string>(key) ?? fallback.toString();
    const parsedValue = Number(rawValue);

    if (!Number.isFinite(parsedValue) || parsedValue <= 0) {
      throw new Error(`${key} must be a positive number`);
    }

    return parsedValue;
  }
}

/** The user's profile as returned to clients (never the password hash). */
function publicUser<T extends { passwordHash?: string | null }>(
  user: T,
): Omit<T, 'passwordHash'> {
  const rest = { ...user };
  delete rest.passwordHash;
  return rest;
}
