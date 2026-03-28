import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { InsightsService } from './insights.service.js';
import { MonthlyQueryDto } from './dto/monthly-query.dto.js';

@ApiTags('insights')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('insights')
export class InsightsController {
  constructor(private insightsService: InsightsService) {}

  @Get('dashboard')
  @ApiOperation({ summary: 'Get financial dashboard overview' })
  async getDashboard(@CurrentUser() user: { userId: string }) {
    return this.insightsService.getDashboard(user.userId);
  }

  @Get('weekly')
  @ApiOperation({ summary: 'Get weekly financial summary' })
  async getWeeklySummary(@CurrentUser() user: { userId: string }) {
    return this.insightsService.getWeeklySummary(user.userId);
  }

  @Get('monthly')
  @ApiOperation({ summary: 'Get monthly financial summary' })
  async getMonthlySummary(
    @CurrentUser() user: { userId: string },
    @Query() query: MonthlyQueryDto,
  ) {
    return this.insightsService.getMonthlySummary(
      user.userId,
      query.month,
      query.year,
    );
  }
}
