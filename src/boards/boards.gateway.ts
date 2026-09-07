import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { OnEvent } from '@nestjs/event-emitter';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service.js';
import { extractUserFromSocket } from '../auth/ws-jwt.util.js';

@WebSocketGateway({
  cors: { origin: '*' },
})
export class BoardsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  constructor(
    private jwtService: JwtService,
    private prisma: PrismaService,
  ) {}

  async handleConnection(socket: Socket) {
    try {
      const user = extractUserFromSocket(socket, this.jwtService);
      socket.data.user = user;
    } catch (err) {
      socket.emit('error', 'Unauthorized');
      socket.disconnect();
    }
  }

  handleDisconnect(socket: Socket) {
    // cleanup handled automatically by socket.io
  }

  @SubscribeMessage('board:join')
  async handleJoinBoard(
    @ConnectedSocket() socket: Socket,
    @MessageBody() data: { boardId: string },
  ) {
    const user = socket.data.user;
    if (!user) return socket.emit('error', 'Unauthorized');

    const board = await this.prisma.board.findUnique({
      where: { id: data.boardId },
      select: { project: { select: { teamId: true } } },
    });
    if (!board) return socket.emit('error', 'Board not found');

    const membership = await this.prisma.teamMember.findUnique({
      where: { userId_teamId: { userId: user.userId, teamId: board.project.teamId } },
    });
    if (!membership) return socket.emit('error', 'Not a member of this board\'s team');

    socket.join(`board:${data.boardId}`);
    socket.emit('board:joined', { boardId: data.boardId });
  }

  @SubscribeMessage('board:leave')
  handleLeaveBoard(
    @ConnectedSocket() socket: Socket,
    @MessageBody() data: { boardId: string },
  ) {
    socket.leave(`board:${data.boardId}`);
  }

  @OnEvent('task.created')
  handleTaskCreated({ boardId, task }: { boardId: string; task: any }) {
    this.server.to(`board:${boardId}`).emit('task:created', task);
  }

  @OnEvent('task.updated')
  handleTaskUpdated({ boardId, task }: { boardId: string; task: any }) {
    this.server.to(`board:${boardId}`).emit('task:updated', task);
  }

  @OnEvent('task.deleted')
  handleTaskDeleted({ boardId, taskId }: { boardId: string; taskId: string }) {
    this.server.to(`board:${boardId}`).emit('task:deleted', { taskId });
  }
}
