import { IsString, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateProjectDto {
  @ApiProperty({ example: 'Website Redesign', minLength: 2 })
  @IsString()
  @MinLength(2)
  name: string;
}
