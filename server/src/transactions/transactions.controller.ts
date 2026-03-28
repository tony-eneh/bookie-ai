import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  ParseIntPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { TransactionsService } from './transactions.service.js';
import { CreateTransactionDto } from './dto/create-transaction.dto.js';
import { UpdateTransactionDto } from './dto/update-transaction.dto.js';
import { TransactionFilterDto } from './dto/transaction-filter.dto.js';

@ApiTags('transactions')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('transactions')
export class TransactionsController {
  constructor(private transactionsService: TransactionsService) {}

  @Get()
  @ApiOperation({ summary: 'List transactions with filters and pagination' })
  async findAll(
    @CurrentUser() user: { userId: string },
    @Query() filters: TransactionFilterDto,
  ) {
    return this.transactionsService.findAll(user.userId, filters);
  }

  @Post()
  @ApiOperation({ summary: 'Create a new transaction' })
  async create(
    @CurrentUser() user: { userId: string },
    @Body() dto: CreateTransactionDto,
  ) {
    return this.transactionsService.create(user.userId, dto);
  }

  @Get('stats/monthly')
  @ApiOperation({ summary: 'Get monthly income/expense stats' })
  @ApiQuery({ name: 'month', type: Number, example: 1 })
  @ApiQuery({ name: 'year', type: Number, example: 2024 })
  async getMonthlyStats(
    @CurrentUser() user: { userId: string },
    @Query('month', ParseIntPipe) month: number,
    @Query('year', ParseIntPipe) year: number,
  ) {
    return this.transactionsService.getMonthlyStats(user.userId, month, year);
  }

  @Get('stats/categories')
  @ApiOperation({ summary: 'Get spending breakdown by category' })
  @ApiQuery({ name: 'month', type: Number, example: 1 })
  @ApiQuery({ name: 'year', type: Number, example: 2024 })
  async getCategoryBreakdown(
    @CurrentUser() user: { userId: string },
    @Query('month', ParseIntPipe) month: number,
    @Query('year', ParseIntPipe) year: number,
  ) {
    return this.transactionsService.getCategoryBreakdown(
      user.userId,
      month,
      year,
    );
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get transaction details' })
  async findById(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: { userId: string },
  ) {
    return this.transactionsService.findById(id, user.userId);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a transaction' })
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: UpdateTransactionDto,
  ) {
    return this.transactionsService.update(id, user.userId, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a transaction' })
  async delete(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: { userId: string },
  ) {
    return this.transactionsService.delete(id, user.userId);
  }
}
