import { IsString, IsEnum, IsOptional, IsUUID } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  AnswerSource,
  TransactionType,
} from '@prisma/client';

export class RespondClarificationDto {
  @ApiProperty({ example: 'This was for groceries' })
  @IsString()
  answerText: string;

  @ApiProperty({ enum: AnswerSource, example: AnswerSource.TEXT })
  @IsEnum(AnswerSource)
  answerSource: AnswerSource;

  @ApiPropertyOptional({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @ApiPropertyOptional({ enum: TransactionType, example: TransactionType.EXPENSE })
  @IsOptional()
  @IsEnum(TransactionType)
  transactionType?: TransactionType;
}
