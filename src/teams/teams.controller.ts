import { Controller, Get, Post, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { TeamsService } from './teams.service.js';
import { CreateTeamDto } from './dto/create-team.dto.js';
import { AddMemberDto } from './dto/add-member.dto.js';
import { QueryTeamsDto } from './dto/query-teams.dto.js';
import { AuthGuard } from '@nestjs/passport';
import { RolesGuard } from '../auth/guards/roles.guard.js';
import { Roles } from '../auth/decorators/roles.decorator.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import { TeamRole } from '@prisma/client';

@UseGuards(AuthGuard('jwt'))
@Controller('teams')
export class TeamsController {
  constructor(private teamsService: TeamsService) {}

  @Post()
  create(@CurrentUser() user: any, @Body() dto: CreateTeamDto) {
    return this.teamsService.create(user.userId, dto);
  }

  @Get('mine')
  findMine(@CurrentUser() user: any, @Query() query: QueryTeamsDto) {
    return this.teamsService.findUserTeamsWithSearch(user.userId, query);
  }

  @Get(':teamId/members')
  getMembers(@Param('teamId') teamId: string) {
    return this.teamsService.getMembers(teamId);
  }

  @UseGuards(RolesGuard)
  @Roles(TeamRole.OWNER, TeamRole.ADMIN)
  @Post(':teamId/members')
  addMember(@Param('teamId') teamId: string, @Body() dto: AddMemberDto) {
    return this.teamsService.addMember(teamId, dto);
  }

  @UseGuards(RolesGuard)
  @Roles(TeamRole.OWNER, TeamRole.ADMIN)
  @Delete(':teamId/members/:memberUserId')
  removeMember(@Param('teamId') teamId: string, @Param('memberUserId') memberUserId: string) {
    return this.teamsService.removeMember(teamId, memberUserId);
  }
}
