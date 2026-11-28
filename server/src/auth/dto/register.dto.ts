import {
  IsEmail,
  IsEnum,
  IsOptional,
  IsString,
  Matches,
  MinLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { FinancialPersonality, IncomeStyle } from '@prisma/client';

export class RegisterDto {
  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'password123', minLength: 6 })
  @IsString()
  @MinLength(6)
  password: string;

  @ApiProperty({ example: 'John Doe' })
  @IsString()
  fullName: string;

  // Choices made during onboarding, before the account existed.
  @ApiPropertyOptional({ example: 'NGN' })
  @IsOptional()
  @Matches(/^[A-Z]{3}$/, { message: 'primaryCurrency must be an ISO code' })
  primaryCurrency?: string;

  @ApiPropertyOptional({ enum: IncomeStyle })
  @IsOptional()
  @IsEnum(IncomeStyle)
  incomeStyle?: IncomeStyle;

  @ApiPropertyOptional({ enum: FinancialPersonality })
  @IsOptional()
  @IsEnum(FinancialPersonality)
  financialPersonality?: FinancialPersonality;
}
