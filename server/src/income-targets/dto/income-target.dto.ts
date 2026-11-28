import {
  IsDateString,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';

export class CreateIncomeTargetDto {
  @ApiProperty({ example: 'Monthly income goal' })
  @IsString()
  @MaxLength(120)
  title: string;

  @ApiProperty({
    example: 3500000,
    description: 'Per month, in the user primary currency',
  })
  @IsNumber()
  @Min(0)
  targetMonthlyIncome: number;

  @ApiPropertyOptional({ description: 'Defaults to the start of this month' })
  @IsOptional()
  @IsDateString()
  effectiveFrom?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  effectiveTo?: string;

  @ApiPropertyOptional({ example: 'To afford the car by June' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}

export class UpdateIncomeTargetDto extends PartialType(CreateIncomeTargetDto) {}
