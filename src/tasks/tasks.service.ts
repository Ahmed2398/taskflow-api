import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateTaskDto } from './dto/create-task.dto.js';
import { UpdateTaskDto } from './dto/update-task.dto.js';
import { QueryTasksDto } from './dto/query-tasks.dto.js';
import { QueryBuilder } from '../common/utils/query-builder.util.js';
import { PaginatedResponse } from '../common/interfaces/paginated-response.interface.js';

@Injectable()
export class TasksService {
  constructor(
    private prisma: PrismaService,
    private eventEmitter: EventEmitter2,
  ) {}

  // Reused across create/find/update/delete to enforce team access via board -> project -> team
  private async getTeamIdForBoard(boardId: string) {
    const board = await this.prisma.board.findUnique({
      where: { id: boardId },
      select: { project: { select: { teamId: true } } },
    });
    if (!board) throw new NotFoundException('Board not found');
    return board.project.teamId;
  }

  private async assertMembership(teamId: string, userId: string) {
    const membership = await this.prisma.teamMember.findUnique({
      where: { userId_teamId: { userId, teamId } },
    });
    if (!membership) throw new ForbiddenException('Not a member of this board\'s team');
  }

  private async assertAssigneeValid(teamId: string, assigneeId?: string) {
    if (!assigneeId) return;
    const membership = await this.prisma.teamMember.findUnique({
      where: { userId_teamId: { userId: assigneeId, teamId } },
    });
    if (!membership) throw new BadRequestException('Assignee must be a member of this team');
  }

  async create(boardId: string, userId: string, dto: CreateTaskDto) {
    const teamId = await this.getTeamIdForBoard(boardId);
    await this.assertMembership(teamId, userId);
    await this.assertAssigneeValid(teamId, dto.assigneeId);

    const task = await this.prisma.task.create({
      data: {
        title: dto.title,
        description: dto.description,
        status: dto.status,
        dueDate: dto.dueDate ? new Date(dto.dueDate) : undefined,
        boardId,
        assigneeId: dto.assigneeId,
      },
    });

    this.eventEmitter.emit('task.created', { boardId, task });
    return task;
  }

  async findByBoard(boardId: string, userId: string, query: QueryTasksDto): Promise<PaginatedResponse<any>> {
    const teamId = await this.getTeamIdForBoard(boardId);
    await this.assertMembership(teamId, userId);

    const { search, page = 1, limit = 10, sortBy, sortOrder, status, assigneeId, dueBefore, dueAfter } = query;

    // Build where conditions
    const searchConditions = QueryBuilder.buildSearchConditions(search, ['title', 'description']);
    const filterConditions = QueryBuilder.buildFilterConditions({
      status,
      assigneeId,
      dueBefore,
      dueAfter,
    });

    const where = {
      boardId,
      ...searchConditions,
      ...filterConditions,
    };

    // Get total count
    const total = await this.prisma.task.count({ where });

    // Get paginated data
    const pagination = QueryBuilder.buildPaginationOptions(page, limit);
    const orderBy = QueryBuilder.buildSortOptions(sortBy, sortOrder);

    const tasks = await this.prisma.task.findMany({
      where,
      ...pagination,
      orderBy,
      include: { 
        assignee: { select: { id: true, name: true, email: true } },
        _count: { select: { comments: true } },
      },
    });

    return QueryBuilder.buildPaginatedResponse(tasks, total, page, limit);
  }

  async findOne(taskId: string, userId: string) {
    const task = await this.prisma.task.findUnique({
      where: { id: taskId },
      include: { 
        board: { include: { project: true } }, 
        assignee: { select: { id: true, name: true, email: true } },
        comments: { include: { author: { select: { id: true, name: true, email: true } } } },
      },
    });
    if (!task) throw new NotFoundException('Task not found');
    await this.assertMembership(task.board.project.teamId, userId);
    return task;
  }

  async update(taskId: string, userId: string, dto: UpdateTaskDto) {
    const task = await this.findOne(taskId, userId); // reuses membership check
    const teamId = task.board.project.teamId;

    if (dto.assigneeId !== undefined) {
      await this.assertAssigneeValid(teamId, dto.assigneeId);
    }

    const updated = await this.prisma.task.update({
      where: { id: taskId },
      data: {
        title: dto.title,
        description: dto.description,
        status: dto.status,
        dueDate: dto.dueDate ? new Date(dto.dueDate) : undefined,
        assigneeId: dto.assigneeId,
      },
    });

    this.eventEmitter.emit('task.updated', { boardId: task.boardId, task: updated });
    return updated;
  }

  async remove(taskId: string, userId: string) {
    const task = await this.findOne(taskId, userId); // membership check
    await this.prisma.task.delete({ where: { id: taskId } });

    this.eventEmitter.emit('task.deleted', { boardId: task.boardId, taskId });
    return { success: true };
  }
}
