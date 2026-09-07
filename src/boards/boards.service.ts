import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateBoardDto } from './dto/create-board.dto.js';
import { QueryBoardsDto } from './dto/query-boards.dto.js';
import { QueryBuilder } from '../common/utils/query-builder.util.js';
import { PaginatedResponse } from '../common/interfaces/paginated-response.interface.js';

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

  async findByProjectWithSearch(
    projectId: string,
    userId: string,
    query: QueryBoardsDto,
  ): Promise<PaginatedResponse<any>> {
    await this.assertMembership(projectId, userId);

    const { search, page = 1, limit = 10, sortBy, sortOrder, name, createdAfter, createdBefore } = query;

    // Build where conditions
    const searchConditions = QueryBuilder.buildSearchConditions(search, ['name']);
    const filterConditions = QueryBuilder.buildFilterConditions({
      name,
      createdAfter,
      createdBefore,
    });

    const where = {
      projectId,
      ...searchConditions,
      ...filterConditions,
    };

    // Get total count
    const total = await this.prisma.board.count({ where });

    // Get paginated data
    const pagination = QueryBuilder.buildPaginationOptions(page, limit);
    const orderBy = QueryBuilder.buildSortOptions(sortBy, sortOrder);

    const boards = await this.prisma.board.findMany({
      where,
      ...pagination,
      orderBy,
      include: { 
        tasks: true,
        _count: { select: { tasks: true } },
      },
    });

    return QueryBuilder.buildPaginatedResponse(boards, total, page, limit);
  }
}
