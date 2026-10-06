import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';

// Map userId -> socketId pour les notifications ciblées
const userSocketMap = new Map<string, string>();

@WebSocketGateway({
  cors: { origin: '*' },
  namespace: 'notifications',
})
export class NotificationsGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer() server: Server;
  private readonly logger = new Logger(NotificationsGateway.name);

  constructor(
    private jwt: JwtService,
    private config: ConfigService,
  ) {}

  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth.token;
      const payload = this.jwt.verify(token, {
        secret: this.config.get('JWT_ACCESS_SECRET'),
      });
      client.data.userId = payload.sub;
      userSocketMap.set(payload.sub, client.id);
      this.logger.log(`Client connecté : ${payload.sub}`);
    } catch {
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    const userId = client.data.userId;
    if (userId) userSocketMap.delete(userId);
    this.logger.log(`Client déconnecté : ${userId}`);
  }

  @SubscribeMessage('join_room')
  joinRoom(@ConnectedSocket() client: Socket, @MessageBody() artisanId: string) {
    client.join(`artisan:${artisanId}`);
  }

  // Envoyer une notification à un utilisateur spécifique
  sendToUser(userId: string, event: string, data: any) {
    const socketId = userSocketMap.get(userId);
    if (socketId) {
      this.server.to(socketId).emit(event, data);
    }
  }

  // Envoyer à tous les artisans
  broadcastToArtisans(event: string, data: any) {
    this.server.to('artisans').emit(event, data);
  }
}
