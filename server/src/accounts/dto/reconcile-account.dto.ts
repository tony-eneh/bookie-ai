import { IsNumber, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { ReconciliationSource } from '../../../generated/prisma/client.js';

export class ReconcileAccountDto {
  @ApiProperty({ example: 5000.0, description: 'Actual balance from external source' })
  @IsNumber()
  balance: number;

  @ApiProperty({ enum: ReconciliationSource, example: ReconciliationSource.MANUAL })
  @IsEnum(ReconciliationSource)
  source: ReconciliationSource;
}
