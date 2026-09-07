import { Controller, Get, Post, Patch, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { TasksService } from './tasks.service.js';
import { CreateTaskDto } from './dto/create-task.dto.js';
import { UpdateTaskDto } from './dto/update-task.dto.js';
import { QueryTasksDto } from './dto/query-tasks.dto.js';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';

@ApiTags('tasks')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller()
export class TasksController {
  constructor(private tasksService: TasksService) {}

  @Post('boards/:boardId/tasks')
  create(
    @Param('boardId') boardId: string,
    @CurrentUser() user: any,
    @Body() dto: CreateTaskDto,
  ) {
    return this.tasksService.create(boardId, user.userId, dto);
  }

  @Get('boards/:boardId/tasks')
  findByBoard(
    @Param('boardId') boardId: string,
    @CurrentUser() user: any,
    @Query() query: QueryTasksDto,
  ) {
    return this.tasksService.findByBoard(boardId, user.userId, query);
  }

  @Get('tasks/:taskId')
  findOne(@Param('taskId') taskId: string, @CurrentUser() user: any) {
    return this.tasksService.findOne(taskId, user.userId);
  }

  @Patch('tasks/:taskId')
  update(
    @Param('taskId') taskId: string,
    @CurrentUser() user: any,
    @Body() dto: UpdateTaskDto,
  ) {
    return this.tasksService.update(taskId, user.userId, dto);
  }

  @Delete('tasks/:taskId')
  remove(@Param('taskId') taskId: string, @CurrentUser() user: any) {
    return this.tasksService.remove(taskId, user.userId);
  }
}
