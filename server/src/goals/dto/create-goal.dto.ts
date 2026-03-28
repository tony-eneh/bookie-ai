import {
  IsString,
  IsOptional,
  IsNumber,
  IsDateString,
  IsEnum,
  Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { GoalPriority } from '../../../generated/prisma/client.js';

export class CreateGoalDto {
  @ApiProperty({ example: 'Emergency Fund' })
  @IsString()
  title: string;

  @ApiPropertyOptional({ example: 'Save 6 months of expenses' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ example: 10000 })
  @IsNumber()
  @Min(0)
  targetAmount: number;

  @ApiProperty({ example: 'USD' })
  @IsString()
  targetCurrency: string;

  @ApiProperty({ example: '2025-12-31' })
  @IsDateString()
  targetDate: string;

  @ApiPropertyOptional({ enum: GoalPriority, example: GoalPriority.HIGH })
  @IsOptional()
  @IsEnum(GoalPriority)
  priority?: GoalPriority;

  @ApiPropertyOptional({ example: 'reduce-dining-out' })
  @IsOptional()
  @IsString()
  linkedBudgetStrategy?: string;
}
