import { JwtService } from '@nestjs/jwt';
import { Socket } from 'socket.io';

export function extractUserFromSocket(socket: Socket, jwtService: JwtService) {
  const token = socket.handshake.auth?.token || socket.handshake.headers?.authorization?.split(' ')[1];
  if (!token) throw new Error('No token provided');

  const payload = jwtService.verify(token, { secret: process.env.JWT_SECRET });
  return { userId: payload.sub, email: payload.email };
}
