import { IsString, IsOptional, IsUUID } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ParseSmsDto {
  @ApiProperty({ example: 'You have spent 150.00 NGN at ShopRite on 15/01/2024' })
  @IsString()
  rawText: string;

  @ApiPropertyOptional({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsOptional()
  @IsUUID()
  accountId?: string;
}
