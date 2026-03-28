import { PartialType } from '@nestjs/swagger';
import { CreateGoalDto } from './create-goal.dto.js';

export class UpdateGoalDto extends PartialType(CreateGoalDto) {}
