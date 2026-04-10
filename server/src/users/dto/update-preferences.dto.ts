import { IsEnum, IsOptional } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  NotificationMode,
  FinancialPersonality,
  FxPreference,
  IncomeStyle,
} from '@prisma/client';

export class UpdatePreferencesDto {
  @ApiPropertyOptional({ enum: NotificationMode })
  @IsOptional()
  @IsEnum(NotificationMode)
  notificationMode?: NotificationMode;

  @ApiPropertyOptional({ enum: FinancialPersonality })
  @IsOptional()
  @IsEnum(FinancialPersonality)
  financialPersonality?: FinancialPersonality;

  @ApiPropertyOptional({ enum: FxPreference })
  @IsOptional()
  @IsEnum(FxPreference)
  fxPreference?: FxPreference;

  @ApiPropertyOptional({ enum: IncomeStyle })
  @IsOptional()
  @IsEnum(IncomeStyle)
  incomeStyle?: IncomeStyle;
}
