import { IsOptional, IsString, IsDateString } from 'class-validator';
import { SearchQueryDto } from '../../common/dto/search-query.dto.js';

export class QueryTeamsDto extends SearchQueryDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsDateString()
  createdAfter?: string;

  @IsOptional()
  @IsDateString()
  createdBefore?: string;
}
