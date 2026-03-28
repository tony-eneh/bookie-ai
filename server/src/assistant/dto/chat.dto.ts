import { IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ChatDto {
  @ApiProperty({ example: 'How much did I spend on food this month?' })
  @IsString()
  message: string;
}
