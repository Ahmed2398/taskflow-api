import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateProjectDto } from './dto/create-project.dto.js';

@Injectable()
export class ProjectsService {
  constructor(private prisma: PrismaService) {}

  create(teamId: string, dto: CreateProjectDto) {
    return this.prisma.project.create({
      data: { name: dto.name, teamId },
    });
  }

  findByTeam(teamId: string) {
    return this.prisma.project.findMany({
      where: { teamId },
      include: { boards: true },
    });
  }

  async findOne(projectId: string) {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      include: { boards: true, team: true },
    });
    if (!project) throw new NotFoundException('Project not found');
    return project;
  }
}
