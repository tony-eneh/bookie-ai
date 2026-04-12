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
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { ConnectedAccountsService } from './connected-accounts.service.js';
import { CreateConnectedAccountDto } from './dto/create-connected-account.dto.js';

@ApiTags('connected-accounts')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('connected-accounts')
export class ConnectedAccountsController {
  constructor(
    private readonly connectedAccountsService: ConnectedAccountsService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'List connected external accounts' })
  findAll(@CurrentUser() user: { userId: string }) {
    return this.connectedAccountsService.findAll(user.userId);
  }

  @Post()
  @ApiOperation({ summary: 'Create or refresh a connected external account record' })
  create(
    @CurrentUser() user: { userId: string },
    @Body() dto: CreateConnectedAccountDto,
  ) {
    return this.connectedAccountsService.create(user.userId, dto);
  }

  @Patch(':id/revoke')
  @ApiOperation({ summary: 'Revoke a connected external account' })
  revoke(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: { userId: string },
  ) {
    return this.connectedAccountsService.revoke(id, user.userId);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a connected external account record' })
  delete(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: { userId: string },
  ) {
    return this.connectedAccountsService.delete(id, user.userId);
  }
}