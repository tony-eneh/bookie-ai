import { IsString, IsOptional, IsUUID } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class VoiceLogDto {
  @ApiProperty({ example: 'I spent 20 dollars on lunch at the cafeteria today' })
  @IsString()
  text: string;

  @ApiPropertyOptional({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsOptional()
  @IsUUID()
  accountId?: string;
}
