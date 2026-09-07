import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateBoardDto } from './dto/create-board.dto.js';

@Injectable()
export class BoardsService {
  constructor(private prisma: PrismaService) {}

  private async assertMembership(projectId: string, userId: string) {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { teamId: true },
    });
    if (!project) throw new NotFoundException('Project not found');

    const membership = await this.prisma.teamMember.findUnique({
      where: { userId_teamId: { userId, teamId: project.teamId } },
    });
    if (!membership) throw new ForbiddenException('Not a member of this project\'s team');

    return project;
  }

  async create(projectId: string, userId: string, dto: CreateBoardDto) {
    await this.assertMembership(projectId, userId);
    return this.prisma.board.create({
      data: { name: dto.name, projectId },
    });
  }

  async findByProject(projectId: string, userId: string) {
    await this.assertMembership(projectId, userId);
    return this.prisma.board.findMany({
      where: { projectId },
      include: { tasks: true },
    });
  }
}
