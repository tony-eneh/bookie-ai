import { IsString, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ResetPasswordDto {
  @ApiProperty({ example: 'reset-token-from-email' })
  @IsString()
  token: string;

  @ApiProperty({ example: 'strong-password-123', minLength: 8 })
  @IsString()
  @MinLength(8)
  newPassword: string;
}