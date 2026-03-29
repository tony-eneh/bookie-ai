import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { StatementImportsService } from './statement-imports.service.js';
import { CreateStatementImportDto } from './dto/create-statement-import.dto.js';

@ApiTags('statement-imports')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('statement-imports')
export class StatementImportsController {
  constructor(private readonly statementImportsService: StatementImportsService) {}

  @Get()
  @ApiOperation({ summary: 'List imported statements' })
  findAll(@CurrentUser() user: { userId: string }) {
    return this.statementImportsService.findAll(user.userId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get imported statement details' })
  findById(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: { userId: string },
  ) {
    return this.statementImportsService.findById(id, user.userId);
  }

  @Post()
  @ApiOperation({ summary: 'Import parsed statement transactions into an account' })
  create(
    @CurrentUser() user: { userId: string },
    @Body() dto: CreateStatementImportDto,
  ) {
    return this.statementImportsService.create(user.userId, dto);
  }
}