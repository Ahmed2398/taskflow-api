import { IsEmail, IsEnum, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { TeamRole } from '@prisma/client';

export class AddMemberDto {
  @ApiProperty({ example: 'member@example.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'MEMBER', enum: TeamRole, required: false })
  @IsOptional()
  @IsEnum(TeamRole)
  role?: TeamRole;
}
