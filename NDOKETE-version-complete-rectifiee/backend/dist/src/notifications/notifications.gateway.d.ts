import { OnGatewayConnection, OnGatewayDisconnect } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
export declare class NotificationsGateway implements OnGatewayConnection, OnGatewayDisconnect {
    private jwt;
    private config;
    server: Server;
    private readonly logger;
    constructor(jwt: JwtService, config: ConfigService);
    handleConnection(client: Socket): Promise<void>;
    handleDisconnect(client: Socket): void;
    joinRoom(client: Socket, artisanId: string): void;
    sendToUser(userId: string, event: string, data: any): void;
    broadcastToArtisans(event: string, data: any): void;
}
