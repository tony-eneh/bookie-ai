import { IsNumber, IsString, IsDateString, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class GoalPlanningDto {
  @ApiProperty({ example: 10000 })
  @IsNumber()
  targetAmount: number;

  @ApiProperty({ example: '2025-12-31' })
  @IsDateString()
  targetDate: string;

  @ApiProperty({ example: 2000 })
  @IsNumber()
  currentSavings: number;

  @ApiProperty({ example: 3000 })
  @IsNumber()
  monthlyExpenses: number;

  @ApiProperty({ example: 5000 })
  @IsNumber()
  averageIncome: number;
}
