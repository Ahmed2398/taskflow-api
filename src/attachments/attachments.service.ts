import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';

@Injectable()
export class AttachmentsService {
  constructor(private prisma: PrismaService) {}

  private async assertTaskAccess(taskId: string, userId: string) {
    const task = await this.prisma.task.findUnique({
      where: { id: taskId },
      select: { board: { select: { project: { select: { teamId: true } } } } },
    });
    if (!task) throw new NotFoundException('Task not found');

    const membership = await this.prisma.teamMember.findUnique({
      where: { userId_teamId: { userId, teamId: task.board.project.teamId } },
    });
    if (!membership) throw new ForbiddenException('Not a member of this task\'s team');
  }

  async create(taskId: string, userId: string, file: Express.Multer.File) {
    await this.assertTaskAccess(taskId, userId);
    return this.prisma.attachment.create({
      data: {
        taskId,
        fileName: file.originalname,
        fileUrl: `/uploads/${file.filename}`,
      },
    });
  }

  async findByTask(taskId: string, userId: string) {
    await this.assertTaskAccess(taskId, userId);
    return this.prisma.attachment.findMany({ where: { taskId } });
  }
}
