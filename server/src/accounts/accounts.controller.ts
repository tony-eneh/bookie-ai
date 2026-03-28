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
import { AccountsService } from './accounts.service.js';
import { CreateAccountDto } from './dto/create-account.dto.js';
import { UpdateAccountDto } from './dto/update-account.dto.js';
import { ReconcileAccountDto } from './dto/reconcile-account.dto.js';

@ApiTags('accounts')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('accounts')
export class AccountsController {
  constructor(private accountsService: AccountsService) {}

  @Get()
  @ApiOperation({ summary: 'List all user accounts' })
  async findAll(@CurrentUser() user: { userId: string }) {
    return this.accountsService.findAll(user.userId);
  }

  @Post()
  @ApiOperation({ summary: 'Create a new account' })
  async create(
    @CurrentUser() user: { userId: string },
    @Body() dto: CreateAccountDto,
  ) {
    return this.accountsService.create(user.userId, dto);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get account details' })
  async findById(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: { userId: string },
  ) {
    return this.accountsService.findById(id, user.userId);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update an account' })
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: UpdateAccountDto,
  ) {
    return this.accountsService.update(id, user.userId, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Deactivate an account' })
  async delete(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: { userId: string },
  ) {
    return this.accountsService.delete(id, user.userId);
  }

  @Post(':id/reconcile')
  @ApiOperation({ summary: 'Reconcile account balance' })
  async reconcile(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: ReconcileAccountDto,
  ) {
    return this.accountsService.reconcile(id, user.userId, dto);
  }

  @Get(':id/reconciliations')
  @ApiOperation({ summary: 'Get reconciliation history' })
  async getReconciliations(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: { userId: string },
  ) {
    return this.accountsService.getReconciliations(id, user.userId);
  }
}
