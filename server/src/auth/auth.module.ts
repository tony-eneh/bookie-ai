import { Module } from '@nestjs/common';
import { JwtModule, type JwtModuleOptions } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service.js';
import { AuthController } from './auth.controller.js';
import { JwtStrategy } from './strategies/jwt.strategy.js';
import { LocalStrategy } from './strategies/local.strategy.js';
import { UsersModule } from '../users/users.module.js';

function getPositiveNumberEnv(
  configService: ConfigService,
  key: string,
  fallback: number,
) {
  const value = Number(configService.get<string>(key) ?? fallback.toString());
  if (!Number.isFinite(value) || value <= 0) {
    throw new Error(`${key} must be a positive number`);
  }
  return value;
}

@Module({
  imports: [
    PassportModule,
    JwtModule.registerAsync({
      useFactory: (configService: ConfigService): JwtModuleOptions => {
        const jwtSecret = configService.getOrThrow<string>('JWT_SECRET');

        return {
          secret: jwtSecret,
          signOptions: {
            expiresIn: getPositiveNumberEnv(
              configService,
              'JWT_EXPIRATION_SECONDS',
              900,
            ),
          },
        };
      },
      inject: [ConfigService],
    }),
    UsersModule,
  ],
  providers: [AuthService, JwtStrategy, LocalStrategy],
  controllers: [AuthController],
  exports: [AuthService],
})
export class AuthModule {}
