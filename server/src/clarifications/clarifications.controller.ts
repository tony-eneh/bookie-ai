import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiTags,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { ClarificationsService } from './clarifications.service.js';
import { RespondClarificationDto } from './dto/respond-clarification.dto.js';
import type { ClarificationItemStatus } from '../../generated/prisma/client.js';

@ApiTags('clarifications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('clarifications')
export class ClarificationsController {
  constructor(private clarificationsService: ClarificationsService) {}

  @Get()
  @ApiOperation({ summary: 'List clarifications' })
  @ApiQuery({ name: 'status', required: false, enum: ['PENDING', 'ANSWERED', 'DISMISSED'] })
  async findAll(
    @CurrentUser() user: { userId: string },
    @Query('status') status?: ClarificationItemStatus,
  ) {
    return this.clarificationsService.findAll(user.userId, status);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get clarification detail' })
  async findById(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: { userId: string },
  ) {
    return this.clarificationsService.findById(id, user.userId);
  }

  @Post(':id/respond')
  @ApiOperation({ summary: 'Respond to a clarification' })
  async respond(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: RespondClarificationDto,
  ) {
    return this.clarificationsService.respond(id, user.userId, dto);
  }

  @Post(':id/dismiss')
  @ApiOperation({ summary: 'Dismiss a clarification' })
  async dismiss(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: { userId: string },
  ) {
    return this.clarificationsService.dismiss(id, user.userId);
  }
}
