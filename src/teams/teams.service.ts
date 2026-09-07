import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateTeamDto } from './dto/create-team.dto.js';
import { AddMemberDto } from './dto/add-member.dto.js';
import { TeamRole } from '@prisma/client';

@Injectable()
export class TeamsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, dto: CreateTeamDto) {
    return this.prisma.team.create({
      data: {
        name: dto.name,
        members: {
          create: { userId, role: TeamRole.OWNER },
        },
      },
      include: { members: true },
    });
  }

  async findUserTeams(userId: string) {
    return this.prisma.team.findMany({
      where: { members: { some: { userId } } },
      include: { members: true },
    });
  }

  async getMembers(teamId: string) {
    const team = await this.prisma.team.findUnique({
      where: { id: teamId },
      include: { members: { include: { user: { select: { id: true, name: true, email: true } } } } },
    });
    if (!team) throw new NotFoundException('Team not found');
    return team.members;
  }

  async addMember(teamId: string, dto: AddMemberDto) {
    const user = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (!user) throw new NotFoundException('User with that email not found');

    const existing = await this.prisma.teamMember.findUnique({
      where: { userId_teamId: { userId: user.id, teamId } },
    });
    if (existing) throw new ConflictException('User already in team');

    return this.prisma.teamMember.create({
      data: { userId: user.id, teamId, role: dto.role ?? TeamRole.MEMBER },
    });
  }

  async removeMember(teamId: string, memberUserId: string) {
    return this.prisma.teamMember.delete({
      where: { userId_teamId: { userId: memberUserId, teamId } },
    });
  }
}
