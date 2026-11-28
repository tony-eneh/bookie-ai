import { IsBoolean, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ImportCsvDto {
  @ApiProperty()
  @IsUUID()
  accountId!: string;

  @ApiProperty({ description: 'The CSV file contents (max ~2 MB)' })
  @IsString()
  @MaxLength(2_000_000)
  csv!: string;

  @ApiPropertyOptional({ example: 'gtbank-nov-2026.csv' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  fileName?: string;

  @ApiPropertyOptional({
    default: false,
    description: 'Also apply the rows to the account balance',
  })
  @IsOptional()
  @IsBoolean()
  adjustBalance?: boolean;
}
