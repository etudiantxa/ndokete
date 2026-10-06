import { PrismaService } from '../common/prisma/prisma.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
export declare class UsersService {
    private prisma;
    constructor(prisma: PrismaService);
    updateFcmToken(userId: string, fcmToken: string): Promise<{
        message: string;
    }>;
    getMe(userId: string): Promise<{
        id: string;
        email: string;
        phone: string;
        role: import(".prisma/client").$Enums.Role;
        isVerified: boolean;
        createdAt: Date;
        artisan: {
            id: string;
            businessName: string;
            specialty: string[];
            description: string | null;
            quarter: string;
            profilePhoto: string | null;
            subscription: {
                id: string;
                createdAt: Date;
                updatedAt: Date;
                plan: import(".prisma/client").$Enums.SubscriptionPlan;
                status: import(".prisma/client").$Enums.SubscriptionStatus;
                startDate: Date;
                endDate: Date | null;
                price: number;
                paymentRef: string | null;
                artisanId: string;
            } | null;
            _count: {
                customers: number;
                products: number;
            };
        } | null;
        client: {
            id: string;
            createdAt: Date;
        } | null;
    }>;
    updateMe(userId: string, dto: UpdateUserDto): Promise<{
        id: string;
        email: string;
        phone: string;
        role: import(".prisma/client").$Enums.Role;
        isVerified: boolean;
        createdAt: Date;
        artisan: {
            id: string;
            businessName: string;
            specialty: string[];
            description: string | null;
            quarter: string;
            profilePhoto: string | null;
            subscription: {
                id: string;
                createdAt: Date;
                updatedAt: Date;
                plan: import(".prisma/client").$Enums.SubscriptionPlan;
                status: import(".prisma/client").$Enums.SubscriptionStatus;
                startDate: Date;
                endDate: Date | null;
                price: number;
                paymentRef: string | null;
                artisanId: string;
            } | null;
            _count: {
                customers: number;
                products: number;
            };
        } | null;
        client: {
            id: string;
            createdAt: Date;
        } | null;
    }>;
    changePassword(userId: string, dto: ChangePasswordDto): Promise<{
        message: string;
    }>;
}
