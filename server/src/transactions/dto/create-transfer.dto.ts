import {
  IsDateString,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateTransferDto {
  @ApiProperty()
  @IsUUID()
  fromAccountId!: string;

  @ApiProperty()
  @IsUUID()
  toAccountId!: string;

  @ApiProperty({ example: 50000, description: 'In the source account currency' })
  @IsNumber()
  @IsPositive()
  amount!: number;

  @ApiPropertyOptional({
    example: 48500,
    description:
      'What arrived, in the destination currency. Defaults to amount converted at the current rate.',
  })
  @IsOptional()
  @IsNumber()
  @IsPositive()
  receivedAmount?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  occurredAt?: string;

  @ApiPropertyOptional({ example: 'Top up wallet' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  description?: string;
}
