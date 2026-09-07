import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateProjectDto } from './dto/create-project.dto.js';
import { QueryProjectsDto } from './dto/query-projects.dto.js';
import { QueryBuilder } from '../common/utils/query-builder.util.js';
import { PaginatedResponse } from '../common/interfaces/paginated-response.interface.js';

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

  async findByTeamWithSearch(
    teamId: string,
    query: QueryProjectsDto,
  ): Promise<PaginatedResponse<any>> {
    const { search, page = 1, limit = 10, sortBy, sortOrder, name, createdAfter, createdBefore } = query;

    // Build where conditions
    const searchConditions = QueryBuilder.buildSearchConditions(search, ['name']);
    const filterConditions = QueryBuilder.buildFilterConditions({
      name,
      createdAfter,
      createdBefore,
    });

    const where = {
      teamId,
      ...searchConditions,
      ...filterConditions,
    };

    // Get total count
    const total = await this.prisma.project.count({ where });

    // Get paginated data
    const pagination = QueryBuilder.buildPaginationOptions(page, limit);
    const orderBy = QueryBuilder.buildSortOptions(sortBy, sortOrder);

    const projects = await this.prisma.project.findMany({
      where,
      ...pagination,
      orderBy,
      include: { 
        boards: true,
        _count: { select: { boards: true } },
      },
    });

    return QueryBuilder.buildPaginatedResponse(projects, total, page, limit);
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
