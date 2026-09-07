import { IsString, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateCommentDto {
  @ApiProperty({ example: 'Looks good, ship it' })
  @IsString()
  @MinLength(1)
  content: string;
}
