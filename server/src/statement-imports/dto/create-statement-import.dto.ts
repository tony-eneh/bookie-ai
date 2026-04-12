import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsDateString,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Min,
  ValidateNested,
} from 'class-validator';
import { TransactionType } from '@prisma/client';

const supportedStatementImportTransactionTypes = [
  TransactionType.INCOME,
  TransactionType.EXPENSE,
] as const;

class StatementImportTransactionDto {
  @ApiProperty({
    enum: supportedStatementImportTransactionTypes,
    example: TransactionType.EXPENSE,
  })
  @IsIn(supportedStatementImportTransactionTypes, {
    message: 'Statement imports currently support only INCOME and EXPENSE transactions',
  })
  type!: TransactionType;

  @ApiProperty({ example: 125.5 })
  @IsNumber()
  @Min(0)
  amount!: number;

  @ApiProperty({ example: 'USD' })
  @IsString()
  currency!: string;

  @ApiProperty({ example: '2026-03-01T12:00:00.000Z' })
  @IsDateString()
  occurredAt!: string;

  @ApiProperty({ example: 'POS purchase at grocery store' })
  @IsString()
  description!: string;

  @ApiProperty({ example: 'Whole Foods', required: false })
  @IsOptional()
  @IsString()
  merchantName?: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000', required: false })
  @IsOptional()
  @IsUUID()
  categoryId?: string;
}

export class CreateStatementImportDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsUUID()
  accountId!: string;

  @ApiProperty({ example: 'bank_statement_upload' })
  @IsString()
  source!: string;

  @ApiProperty({ example: 'csv' })
  @IsString()
  fileType!: string;

  @ApiProperty({ type: [StatementImportTransactionDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => StatementImportTransactionDto)
  transactions!: StatementImportTransactionDto[];
}