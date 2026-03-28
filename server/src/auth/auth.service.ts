import {
  ConflictException,
  Injectable,
  Logger,
  NotImplementedException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { hash, compare } from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';
import { PrismaService } from '../prisma/prisma.service.js';
import { UsersService } from '../users/users.service.js';
import type { GoogleAuthDto } from './dto/google-auth.dto.js';
import type { RegisterDto } from './dto/register.dto.js';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private prisma: PrismaService,
    private usersService: UsersService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  async register(dto: RegisterDto) {
    const existing = await this.usersService.findByEmail(dto.email);
    if (existing) {
      throw new ConflictException('Email already registered');
    }

    const passwordHash = await hash(dto.password, 12);

    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        passwordHash,
        fullName: dto.fullName,
      },
    });

    // Create default account for the user
    await this.prisma.account.create({
      data: {
        userId: user.id,
        name: 'Main Account',
        type: 'BANK',
        currency: user.primaryCurrency,
        isPrimary: true,
      },
    });

    const tokens = await this.generateTokens(user.id, user.email);
    return {
      user: { id: user.id, email: user.email, fullName: user.fullName },
      ...tokens,
    };
  }

  async login(userId: string) {
    const user = await this.usersService.findById(userId);
    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    const tokens = await this.generateTokens(user.id, user.email);
    return {
      user: { id: user.id, email: user.email, fullName: user.fullName },
      ...tokens,
    };
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

  async forgotPassword(email: string) {
    const user = await this.usersService.findByEmail(email);
    if (!user) {
      // Return success even if user not found to prevent email enumeration
      return { message: 'If the email exists, a reset link has been sent' };
    }

    this.logger.warn(
      `Password reset requested for ${email}, but email delivery is not configured yet`,
    );
    return { message: 'If the email exists, a reset link has been sent' };
  }

  async resetPassword(_token: string, _newPassword: string) {
    this.logger.warn(
      'Password reset attempted before reset-token validation was implemented',
    );
    throw new NotImplementedException(
      'Password reset token validation is not implemented yet.',
    );
  }

  async googleAuth(_dto: GoogleAuthDto) {
    this.logger.warn(
      'Google auth requested before ID token verification was implemented',
    );
    throw new NotImplementedException(
      'Google OAuth is not enabled until ID token verification is implemented.',
    );
  }

  async generateTokens(userId: string, email: string) {
    const payload = { sub: userId, email };

    const accessToken = this.jwtService.sign(payload);

    const refreshToken = uuidv4();
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
}
