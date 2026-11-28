import {
  Body,
  Controller,
  Get,
  HttpCode,
  NotFoundException,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { DeleteAccountDto } from './dto/delete-account.dto.js';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { UsersService } from './users.service.js';
import { UpdateUserDto } from './dto/update-user.dto.js';
import { UpdatePreferencesDto } from './dto/update-preferences.dto.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';

@ApiTags('users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Get('me')
  @ApiOperation({ summary: 'Get current user profile' })
  async getProfile(@CurrentUser() user: { userId: string }) {
    const found = await this.usersService.findById(user.userId);
    if (!found) {
      throw new NotFoundException('User not found');
    }
    const { passwordHash: _, ...result } = found;
    return result;
  }

  @Get('me/export')
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  @ApiOperation({ summary: 'Download all of my data (JSON)' })
  exportData(@CurrentUser() user: { userId: string }) {
    return this.usersService.exportData(user.userId);
  }

  @Post('me/delete')
  @HttpCode(200)
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  @ApiOperation({ summary: 'Permanently delete my account and all data' })
  deleteAccount(
    @CurrentUser() user: { userId: string },
    @Body() dto: DeleteAccountDto,
  ) {
    return this.usersService.deleteAccount(user.userId, dto.password);
  }

  @Patch('me')
  @ApiOperation({ summary: 'Update current user profile' })
  async updateProfile(
    @CurrentUser() user: { userId: string },
    @Body() dto: UpdateUserDto,
  ) {
    const updated = await this.usersService.update(user.userId, dto);
    const { passwordHash: _, ...result } = updated;
    return result;
  }

  @Patch('preferences')
  @ApiOperation({ summary: 'Update user preferences' })
  async updatePreferences(
    @CurrentUser() user: { userId: string },
    @Body() dto: UpdatePreferencesDto,
  ) {
    const updated = await this.usersService.updatePreferences(
      user.userId,
      dto,
    );
    const { passwordHash: _, ...result } = updated;
    return result;
  }
}
