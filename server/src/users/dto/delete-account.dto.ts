import { Equals, IsOptional, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class DeleteAccountDto {
  @ApiProperty({ example: 'DELETE', description: 'Must be exactly DELETE' })
  @Equals('DELETE', { message: 'Type DELETE to confirm' })
  confirm: string;

  @ApiPropertyOptional({
    description: 'Required for accounts that have a password',
  })
  @IsOptional()
  @IsString()
  password?: string;
}
