import {
  IsString,
  IsEnum,
  IsOptional,
  IsNumber,
  IsBoolean,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { AccountType } from '@prisma/client';

export class CreateAccountDto {
  @ApiProperty({ example: 'Main Checking' })
  @IsString()
  name: string;

  @ApiProperty({ enum: AccountType, example: AccountType.BANK })
  @IsEnum(AccountType)
  type: AccountType;

  // No default initializer here: UpdateAccountDto extends this via
  // PartialType, and a default would overwrite the currency on every edit.
  @ApiPropertyOptional({
    example: 'NGN',
    description: "Defaults to the user's primary currency",
  })
  @IsOptional()
  @IsString()
  currency?: string;

  @ApiPropertyOptional({ example: 1000.0 })
  @IsOptional()
  @IsNumber()
  initialBalance?: number;

  @ApiPropertyOptional({ example: false, default: false })
  @IsOptional()
  @IsBoolean()
  isPrimary?: boolean;
}
