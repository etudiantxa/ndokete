import { Controller, Get, Post, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { TeamService, CreateTeamMemberDto } from './team.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('artisans-team')
@ApiBearerAuth('access-token')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ARTISAN')
@Controller('artisans/team')
export class TeamController {
  constructor(private teamService: TeamService) {}

  @Get()
  @ApiOperation({ summary: 'Lister les membres de l’équipe de l’artisan' })
  getTeam(@CurrentUser('artisanId') artisanId: string) {
    return this.teamService.getTeam(artisanId);
  }

  @Post()
  @ApiOperation({ summary: 'Ajouter un apprenti ou employé à l’équipe' })
  addMember(@CurrentUser('artisanId') artisanId: string, @Body() dto: CreateTeamMemberDto) {
    return this.teamService.addMember(artisanId, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Supprimer un membre de l’équipe' })
  removeMember(@CurrentUser('artisanId') artisanId: string, @Param('id') memberId: string) {
    return this.teamService.removeMember(artisanId, memberId);
  }
}
