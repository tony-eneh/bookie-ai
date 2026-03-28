import {
  Body,
  Controller,
  Get,
  Patch,
  UseGuards,
} from '@nestjs/common';
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
      throw new (await import('@nestjs/common')).NotFoundException(
        'User not found',
      );
    }
    const { passwordHash: _, ...result } = found;
    return result;
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
