import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiTags,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { FxRatesService } from './fx-rates.service.js';
import { ConvertQueryDto } from './dto/convert-query.dto.js';

@ApiTags('fx')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('fx')
export class FxRatesController {
  constructor(private fxRatesService: FxRatesService) {}

  @Get('rates')
  @ApiOperation({ summary: 'Get all cached FX rates' })
  @ApiQuery({ name: 'baseCurrency', required: false, type: String })
  async getRates(@Query('baseCurrency') baseCurrency?: string) {
    if (baseCurrency) {
      return this.fxRatesService.getAllRatesForCurrency(baseCurrency);
    }
    return this.fxRatesService.getLatestRates();
  }

  @Get('convert')
  @ApiOperation({ summary: 'Convert an amount between currencies' })
  async convert(@Query() query: ConvertQueryDto) {
    return this.fxRatesService.convert(query.amount, query.from, query.to);
  }
}
