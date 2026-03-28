import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { AssistantService } from './assistant.service.js';
import { ChatDto } from './dto/chat.dto.js';
import { VoiceQueryDto } from './dto/voice-query.dto.js';
import { ClarifyTransactionDto } from './dto/clarify-transaction.dto.js';
import { GoalPlanningDto } from './dto/goal-planning.dto.js';
import { ScenarioDto } from './dto/scenario.dto.js';
import { FxSimulationDto } from './dto/fx-simulation.dto.js';

@ApiTags('assistant')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('assistant')
export class AssistantController {
  constructor(private assistantService: AssistantService) {}

  @Post('chat')
  @ApiOperation({ summary: 'Chat with the AI financial assistant' })
  async chat(
    @CurrentUser() user: { userId: string },
    @Body() dto: ChatDto,
  ) {
    return this.assistantService.chat(user.userId, dto.message);
  }

  @Post('voice-query')
  @ApiOperation({ summary: 'Voice-based query to the assistant' })
  async voiceQuery(
    @CurrentUser() user: { userId: string },
    @Body() dto: VoiceQueryDto,
  ) {
    return this.assistantService.voiceQuery(user.userId, dto.text);
  }

  @Post('clarify-transaction')
  @ApiOperation({ summary: 'Clarify an ambiguous transaction' })
  async clarifyTransaction(
    @CurrentUser() user: { userId: string },
    @Body() dto: ClarifyTransactionDto,
  ) {
    return this.assistantService.clarifyTransaction(
      user.userId,
      dto.transactionId,
      dto.userInput,
    );
  }

  @Post('goal-planning')
  @ApiOperation({ summary: 'AI-powered goal planning analysis' })
  async goalPlanning(
    @CurrentUser() user: { userId: string },
    @Body() dto: GoalPlanningDto,
  ) {
    return this.assistantService.goalPlanning(user.userId, dto);
  }

  @Post('scenario')
  @ApiOperation({ summary: 'Run a financial scenario simulation' })
  async scenario(
    @CurrentUser() user: { userId: string },
    @Body() dto: ScenarioDto,
  ) {
    return this.assistantService.scenario(user.userId, dto);
  }

  @Post('fx-simulation')
  @ApiOperation({ summary: 'Simulate a foreign exchange conversion' })
  async fxSimulation(
    @CurrentUser() user: { userId: string },
    @Body() dto: FxSimulationDto,
  ) {
    return this.assistantService.fxSimulation(user.userId, dto);
  }
}
