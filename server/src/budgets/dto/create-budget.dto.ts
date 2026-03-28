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
import { BudgetPeriodType } from '../../../generated/prisma/client.js';

export class CreateBudgetDto {
  @ApiProperty({ example: 'Groceries Budget' })
  @IsString()
  name: string;

  @ApiPropertyOptional({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @ApiProperty({ enum: BudgetPeriodType, example: BudgetPeriodType.MONTHLY })
  @IsEnum(BudgetPeriodType)
  periodType: BudgetPeriodType;

  @ApiProperty({ example: 500 })
  @IsNumber()
  @Min(0)
  amount: number;

  @ApiProperty({ example: 'USD' })
  @IsString()
  currency: string;

  @ApiProperty({ example: '2024-01-01' })
  @IsDateString()
  startDate: string;
}
