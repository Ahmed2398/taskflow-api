import { IsString, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateBoardDto {
  @ApiProperty({ example: 'Sprint 1', minLength: 2 })
  @IsString()
  @MinLength(2)
  name: string;
}
