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
import { GoalsService } from './goals.service.js';
import { CreateGoalDto } from './dto/create-goal.dto.js';
import { UpdateGoalDto } from './dto/update-goal.dto.js';
import { CreateContributionDto } from './dto/create-contribution.dto.js';

@ApiTags('goals')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('goals')
export class GoalsController {
  constructor(private goalsService: GoalsService) {}

  @Get()
  @ApiOperation({ summary: 'List all goals' })
  async findAll(@CurrentUser() user: { userId: string }) {
    return this.goalsService.findAll(user.userId);
  }

  @Post()
  @ApiOperation({ summary: 'Create a goal' })
  async create(
    @CurrentUser() user: { userId: string },
    @Body() dto: CreateGoalDto,
  ) {
    return this.goalsService.create(user.userId, dto);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get goal detail' })
  async findById(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: { userId: string },
  ) {
    return this.goalsService.findById(id, user.userId);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a goal' })
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: UpdateGoalDto,
  ) {
    return this.goalsService.update(id, user.userId, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a goal' })
  async delete(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: { userId: string },
  ) {
    return this.goalsService.delete(id, user.userId);
  }

  @Post(':id/contributions')
  @ApiOperation({ summary: 'Add a contribution to a goal' })
  async addContribution(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: CreateContributionDto,
  ) {
    return this.goalsService.addContribution(id, user.userId, dto);
  }

  @Get(':id/projection')
  @ApiOperation({ summary: 'Get goal projection and coaching' })
  async getProjection(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: { userId: string },
  ) {
    return this.goalsService.getProjection(id, user.userId);
  }
}
