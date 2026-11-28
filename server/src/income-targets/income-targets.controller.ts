import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { IncomeTargetsService } from './income-targets.service.js';
import {
  CreateIncomeTargetDto,
  UpdateIncomeTargetDto,
} from './dto/income-target.dto.js';

@ApiTags('income-targets')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('income-targets')
export class IncomeTargetsController {
  constructor(private service: IncomeTargetsService) {}

  @Get()
  @ApiOperation({ summary: 'List income targets' })
  findAll(@CurrentUser() user: { userId: string }) {
    return this.service.findAll(user.userId);
  }

  @Get('current')
  @ApiOperation({ summary: 'Progress this month against the active target' })
  current(@CurrentUser() user: { userId: string }) {
    return this.service.current(user.userId);
  }

  @Post()
  @ApiOperation({ summary: 'Create an income target' })
  create(
    @CurrentUser() user: { userId: string },
    @Body() dto: CreateIncomeTargetDto,
  ) {
    return this.service.create(user.userId, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update an income target' })
  update(
    @CurrentUser() user: { userId: string },
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateIncomeTargetDto,
  ) {
    return this.service.update(id, user.userId, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete an income target' })
  remove(
    @CurrentUser() user: { userId: string },
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.service.remove(id, user.userId);
  }
}
