import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common';
import { ProjectsService } from './projects.service.js';
import { CreateProjectDto } from './dto/create-project.dto.js';
import { AuthGuard } from '@nestjs/passport';
import { TeamMemberGuard } from '../auth/guards/team-member.guard.js';

@UseGuards(AuthGuard('jwt'), TeamMemberGuard)
@Controller('teams/:teamId/projects')
export class ProjectsController {
  constructor(private projectsService: ProjectsService) {}

  @Post()
  create(@Param('teamId') teamId: string, @Body() dto: CreateProjectDto) {
    return this.projectsService.create(teamId, dto);
  }

  @Get()
  findAll(@Param('teamId') teamId: string) {
    return this.projectsService.findByTeam(teamId);
  }
}
