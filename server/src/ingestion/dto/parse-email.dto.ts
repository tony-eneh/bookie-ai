import { IsString, IsOptional, IsUUID } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ParseEmailDto {
  @ApiProperty({ example: 'Your account has been debited 500.00 USD for Netflix subscription' })
  @IsString()
  rawText: string;

  @ApiPropertyOptional({ example: 'Payment Notification' })
  @IsOptional()
  @IsString()
  subject?: string;

  @ApiPropertyOptional({ example: 'alerts@bank.com' })
  @IsOptional()
  @IsString()
  from?: string;

  @ApiPropertyOptional({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsOptional()
  @IsUUID()
  accountId?: string;
}
