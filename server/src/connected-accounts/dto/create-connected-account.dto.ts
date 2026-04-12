import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class CreateConnectedAccountDto {
  @ApiProperty({ example: 'google' })
  @IsString()
  providerType: string;

  @ApiProperty({ example: 'user@gmail.com' })
  @IsString()
  providerEmail: string;

  @ApiPropertyOptional({ example: 'oauth-access-token' })
  @IsOptional()
  @IsString()
  accessToken?: string;

  @ApiPropertyOptional({ example: 'oauth-refresh-token' })
  @IsOptional()
  @IsString()
  refreshToken?: string;

  @ApiPropertyOptional({ example: 'openid email profile' })
  @IsOptional()
  @IsString()
  scopes?: string;
}