import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateCommentDto } from './dto/create-comment.dto.js';

@Injectable()
export class CommentsService {
  constructor(private prisma: PrismaService) {}

  private async assertTaskAccess(taskId: string, userId: string) {
    const task = await this.prisma.task.findUnique({
      where: { id: taskId },
      select: { board: { select: { project: { select: { teamId: true } } } } },
    });
    if (!task) throw new NotFoundException('Task not found');

    const teamId = task.board.project.teamId;
    const membership = await this.prisma.teamMember.findUnique({
      where: { userId_teamId: { userId, teamId } },
    });
    if (!membership) throw new ForbiddenException('Not a member of this task\'s team');

    return teamId;
  }

  async create(taskId: string, authorId: string, dto: CreateCommentDto) {
    await this.assertTaskAccess(taskId, authorId);
    return this.prisma.comment.create({
      data: { content: dto.content, taskId, authorId },
      include: { author: { select: { id: true, name: true } } },
    });
  }

  async findByTask(taskId: string, userId: string) {
    await this.assertTaskAccess(taskId, userId);
    return this.prisma.comment.findMany({
      where: { taskId },
      include: { author: { select: { id: true, name: true } } },
      orderBy: { createdAt: 'asc' },
    });
  }

  async remove(commentId: string, userId: string) {
    const comment = await this.prisma.comment.findUnique({ where: { id: commentId } });
    if (!comment) throw new NotFoundException('Comment not found');
    if (comment.authorId !== userId) {
      throw new ForbiddenException('You can only delete your own comments');
    }
    return this.prisma.comment.delete({ where: { id: commentId } });
  }
}
