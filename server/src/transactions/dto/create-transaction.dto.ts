import {
  IsString,
  IsEnum,
  IsOptional,
  IsNumber,
  IsUUID,
  IsDateString,
  Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  TransactionType,
  SourceType,
} from '@prisma/client';

export class CreateTransactionDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsUUID()
  accountId: string;

  @ApiProperty({ enum: TransactionType, example: TransactionType.EXPENSE })
  @IsEnum(TransactionType)
  type: TransactionType;

  @ApiProperty({ example: 49.99 })
  @IsNumber()
  @Min(0)
  amount: number;

  @ApiProperty({ example: 'USD' })
  @IsString()
  currency: string;

  @ApiProperty({ example: '2024-01-15T10:30:00Z' })
  @IsDateString()
  occurredAt: string;

  @ApiPropertyOptional({ example: 'Lunch at cafe' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ example: 'Starbucks' })
  @IsOptional()
  @IsString()
  merchantName?: string;

  @ApiPropertyOptional({ example: 'John Doe' })
  @IsOptional()
  @IsString()
  counterparty?: string;

  @ApiPropertyOptional({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @ApiPropertyOptional({ example: 'Coffee' })
  @IsOptional()
  @IsString()
  subcategory?: string;

  @ApiProperty({ enum: SourceType, example: SourceType.MANUAL })
  @IsEnum(SourceType)
  sourceType: SourceType;

  @ApiPropertyOptional({ example: 'Raw SMS content...' })
  @IsOptional()
  @IsString()
  rawContent?: string;

  @ApiPropertyOptional({ example: 'Monthly subscription' })
  @IsOptional()
  @IsString()
  note?: string;

  @ApiPropertyOptional({ example: 0.95 })
  @IsOptional()
  @IsNumber()
  parseConfidence?: number;

  @ApiPropertyOptional({ example: 0.85 })
  @IsOptional()
  @IsNumber()
  categoryConfidence?: number;
}
