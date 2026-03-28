import { IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class VoiceQueryDto {
  @ApiProperty({ example: 'What is my savings rate this month?' })
  @IsString()
  text: string;
}
