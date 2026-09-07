import { Controller, Get, Post, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { CommentsService } from './comments.service.js';
import { CreateCommentDto } from './dto/create-comment.dto.js';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';

@UseGuards(AuthGuard('jwt'))
@Controller()
export class CommentsController {
  constructor(private commentsService: CommentsService) {}

  @Post('tasks/:taskId/comments')
  create(
    @Param('taskId') taskId: string,
    @CurrentUser() user: any,
    @Body() dto: CreateCommentDto,
  ) {
    return this.commentsService.create(taskId, user.userId, dto);
  }

  @Get('tasks/:taskId/comments')
  findByTask(@Param('taskId') taskId: string, @CurrentUser() user: any) {
    return this.commentsService.findByTask(taskId, user.userId);
  }

  @Delete('comments/:commentId')
  remove(@Param('commentId') commentId: string, @CurrentUser() user: any) {
    return this.commentsService.remove(commentId, user.userId);
  }
}
