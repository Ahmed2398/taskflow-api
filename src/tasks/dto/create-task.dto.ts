import { IsString, IsOptional, IsEnum, IsDateString, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { TaskStatus } from '@prisma/client';

export class CreateTaskDto {
  @ApiProperty({ example: 'Design homepage', minLength: 2 })
  @IsString()
  @MinLength(2)
  title: string;

  @ApiProperty({ example: 'Create mockups for the homepage', required: false })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ example: 'TODO', enum: TaskStatus, required: false })
  @IsOptional()
  @IsEnum(TaskStatus)
  status?: TaskStatus;

  @ApiProperty({ example: '2025-12-31T00:00:00.000Z', required: false })
  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @ApiProperty({ example: 'uuid-of-assignee', required: false })
  @IsOptional()
  @IsString()
  assigneeId?: string;
}
