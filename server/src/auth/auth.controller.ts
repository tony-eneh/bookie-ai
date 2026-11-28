import {
  Body,
  Controller,
  Get,
  Header,
  Post,
  Req,
  Request,
  UseGuards,
} from '@nestjs/common';
import type { Request as ExpressRequest } from 'express';
import { Throttle } from '@nestjs/throttler';
import {
  ApiBearerAuth,
  ApiBody,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { RawResponse } from '../common/decorators/raw-response.decorator.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { AuthService } from './auth.service.js';
import { ForgotPasswordDto } from './dto/forgot-password.dto.js';
import { GoogleAuthDto } from './dto/google-auth.dto.js';
import { LoginDto } from './dto/login.dto.js';
import { RefreshDto } from './dto/refresh.dto.js';
import { RegisterDto } from './dto/register.dto.js';
import { ResetPasswordDto } from './dto/reset-password.dto.js';
import { LocalAuthGuard } from './guards/local-auth.guard.js';
import { RESET_PASSWORD_PAGE } from './reset-password-page.js';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('register')
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  @ApiOperation({ summary: 'Register a new user' })
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('login')
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @UseGuards(LocalAuthGuard)
  @ApiBody({ type: LoginDto })
  @ApiOperation({ summary: 'Login with email and password' })
  async login(@Request() req: { user: { id: string } }) {
    return this.authService.login(req.user.id);
  }

  @Post('google')
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @ApiOperation({
    summary: 'Authenticate with Google using a verified Google ID token',
  })
  google(@Body() dto: GoogleAuthDto) {
    return this.authService.googleAuth(dto);
  }

  @Post('refresh')
  @ApiOperation({ summary: 'Refresh access token' })
  refresh(@Body() dto: RefreshDto) {
    return this.authService.refreshTokens(dto.refreshToken);
  }

  @Post('logout')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Logout and invalidate refresh token' })
  logout(
    @CurrentUser() user: { userId: string },
    @Body() body: RefreshDto,
  ) {
    return this.authService.logout(user.userId, body.refreshToken);
  }

  @Post('forgot-password')
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  @ApiOperation({
    summary: 'Request a password reset email',
  })
  forgotPassword(@Body() dto: ForgotPasswordDto, @Req() req: ExpressRequest) {
    // The emailed link opens the page below, served from this same API.
    const proto = (req.get('x-forwarded-proto') ?? req.protocol).split(',')[0];
    const pageUrl = `${proto}://${req.get('host')}${req.originalUrl.replace(
      /forgot-password.*$/,
      'reset-password',
    )}`;
    return this.authService.forgotPassword(dto.email, pageUrl);
  }

  @Get('reset-password')
  @ApiOperation({ summary: 'Password reset page (opened from the email)' })
  @Header('Content-Type', 'text/html; charset=utf-8')
  @Header('Cache-Control', 'no-store')
  @Header('Referrer-Policy', 'no-referrer')
  @RawResponse()
  resetPasswordPage() {
    return RESET_PASSWORD_PAGE;
  }

  @Post('reset-password')
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @ApiOperation({
    summary: 'Reset password using a valid reset token',
  })
  resetPassword(@Body() dto: ResetPasswordDto) {
    return this.authService.resetPassword(dto.token, dto.newPassword);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current authenticated user' })
  me(@CurrentUser() user: { userId: string }) {
    return this.authService.getCurrentUser(user.userId);
  }
}
