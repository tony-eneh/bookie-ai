import { IsString, IsUUID } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ClarifyTransactionDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsUUID()
  transactionId: string;

  @ApiProperty({ example: 'This was a grocery expense at ShopRite' })
  @IsString()
  userInput: string;
}
