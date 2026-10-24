import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AiMeasurementsService } from './ai-measurements.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { IsString } from 'class-validator';

class ParseTranscriptDto {
  @IsString()
  transcript: string;
}

@ApiTags('ai-measurements')
@ApiBearerAuth('access-token')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ARTISAN')
@Controller('artisans/ai')
export class AiMeasurementsController {
  constructor(private aiService: AiMeasurementsService) {}

  @Post('parse-measurements')
  @ApiOperation({ summary: 'Extraire automatiquement les mesures d’un texte ou vocal via IA' })
  parseMeasurements(@Body() dto: ParseTranscriptDto) {
    return this.aiService.parseText(dto.transcript);
  }
}
