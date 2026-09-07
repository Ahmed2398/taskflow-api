import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common';
import { BoardsService } from './boards.service.js';
import { CreateBoardDto } from './dto/create-board.dto.js';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';

@UseGuards(AuthGuard('jwt'))
@Controller('projects/:projectId/boards')
export class BoardsController {
  constructor(private boardsService: BoardsService) {}

  @Post()
  create(
    @Param('projectId') projectId: string,
    @CurrentUser() user: any,
    @Body() dto: CreateBoardDto,
  ) {
    return this.boardsService.create(projectId, user.userId, dto);
  }

  @Get()
  findAll(@Param('projectId') projectId: string, @CurrentUser() user: any) {
    return this.boardsService.findByProject(projectId, user.userId);
  }
}
