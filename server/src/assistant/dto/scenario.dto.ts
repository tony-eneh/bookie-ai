import { IsString, IsObject } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ScenarioDto {
  @ApiProperty({ example: 'salary_increase' })
  @IsString()
  scenarioType: string;

  @ApiProperty({ example: { currentBalance: 5000, monthlyChange: 500 } })
  @IsObject()
  parameters: Record<string, unknown>;
}
