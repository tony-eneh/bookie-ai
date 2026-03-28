import { IsNumber, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class FxSimulationDto {
  @ApiProperty({ example: 1000 })
  @IsNumber()
  amount: number;

  @ApiProperty({ example: 'USD' })
  @IsString()
  sourceCurrency: string;

  @ApiProperty({ example: 'EUR' })
  @IsString()
  targetCurrency: string;
}
