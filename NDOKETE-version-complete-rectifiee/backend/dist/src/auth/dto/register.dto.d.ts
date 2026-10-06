import { Role } from '@prisma/client';
export declare class RegisterDto {
    email: string;
    phone: string;
    password: string;
    role: Role;
    businessName?: string;
    specialty?: string;
    quarter?: string;
}
