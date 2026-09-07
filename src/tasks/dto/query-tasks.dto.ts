import { IsOptional, IsEnum, IsString, IsDateString } from 'class-validator';
import { TaskStatus } from '@prisma/client';
import { SearchQueryDto } from '../../common/dto/search-query.dto.js';

export class QueryTasksDto extends SearchQueryDto {
  @IsOptional()
  @IsEnum(TaskStatus)
  status?: TaskStatus;

  @IsOptional()
  @IsString()
  assigneeId?: string;

  @IsOptional()
  @IsDateString()
  dueBefore?: string;

  @IsOptional()
  @IsDateString()
  dueAfter?: string;
}
