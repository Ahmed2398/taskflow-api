import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { BoardsController } from './boards.controller.js';
import { BoardsService } from './boards.service.js';
import { BoardsGateway } from './boards.gateway.js';

@Module({
  imports: [JwtModule.register({ secret: process.env.JWT_SECRET })],
  controllers: [BoardsController],
  providers: [BoardsService, BoardsGateway],
})
export class BoardsModule {}
