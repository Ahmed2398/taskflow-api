import {
  Controller, Get, Post, Param, UseGuards,
  UseInterceptors, UploadedFile, ParseFilePipe,
  MaxFileSizeValidator, BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { AttachmentsService } from './attachments.service.js';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';

const ALLOWED_EXTENSIONS = ['.png', '.jpeg', '.jpg', '.pdf', '.docx'];

@UseGuards(AuthGuard('jwt'))
@Controller('tasks/:taskId/attachments')
export class AttachmentsController {
  constructor(private attachmentsService: AttachmentsService) {}

  @Post()
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: './uploads',
        filename: (req, file, cb) => {
          const uniqueName = `${Date.now()}-${Math.round(Math.random() * 1e9)}${extname(file.originalname)}`;
          cb(null, uniqueName);
        },
      }),
      fileFilter: (req, file, cb) => {
        const ext = extname(file.originalname).toLowerCase();
        if (ALLOWED_EXTENSIONS.includes(ext)) {
          cb(null, true);
        } else {
          cb(new BadRequestException(`File type not allowed. Allowed: ${ALLOWED_EXTENSIONS.join(', ')}`), false);
        }
      },
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  create(
    @Param('taskId') taskId: string,
    @CurrentUser() user: any,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 5 * 1024 * 1024 }),
        ],
      }),
    )
    file: Express.Multer.File,
  ) {
    return this.attachmentsService.create(taskId, user.userId, file);
  }

  @Get()
  findByTask(@Param('taskId') taskId: string, @CurrentUser() user: any) {
    return this.attachmentsService.findByTask(taskId, user.userId);
  }
}
