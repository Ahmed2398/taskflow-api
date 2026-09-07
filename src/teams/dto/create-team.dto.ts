import { IsString, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateTeamDto {
  @ApiProperty({ example: 'Engineering Team', minLength: 2 })
  @IsString()
  @MinLength(2)
  name: string;
}
