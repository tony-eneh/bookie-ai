import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { IngestionService } from './ingestion.service.js';
import { ParseSmsDto } from './dto/parse-sms.dto.js';
import { ParseEmailDto } from './dto/parse-email.dto.js';
import { VoiceLogDto } from './dto/voice-log.dto.js';
import { ManualEntryDto } from './dto/manual-entry.dto.js';

@ApiTags('ingestion')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('ingestion')
export class IngestionController {
  constructor(private ingestionService: IngestionService) {}

  @Post('sms/parse')
  @ApiOperation({ summary: 'Parse an SMS message into a transaction' })
  async parseSms(
    @CurrentUser() user: { userId: string },
    @Body() dto: ParseSmsDto,
  ) {
    return this.ingestionService.parseSms(user.userId, dto);
  }

  @Post('email/parse')
  @ApiOperation({ summary: 'Parse an email message into a transaction' })
  async parseEmail(
    @CurrentUser() user: { userId: string },
    @Body() dto: ParseEmailDto,
  ) {
    return this.ingestionService.parseEmail(user.userId, dto);
  }

  @Post('voice-log')
  @ApiOperation({ summary: 'Parse voice text into a transaction' })
  async voiceLog(
    @CurrentUser() user: { userId: string },
    @Body() dto: VoiceLogDto,
  ) {
    return this.ingestionService.voiceLog(user.userId, dto);
  }

  @Post('manual-entry')
  @ApiOperation({ summary: 'Create a transaction from manual entry' })
  async manualEntry(
    @CurrentUser() user: { userId: string },
    @Body() dto: ManualEntryDto,
  ) {
    return this.ingestionService.manualEntry(user.userId, dto);
  }
}
