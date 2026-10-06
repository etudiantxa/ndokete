import { OrderStatus } from '@prisma/client';
export declare class CreateOrderDto {
    customerId: string;
    title: string;
    description?: string;
    amount: number;
    deposit?: number;
    dueDate?: string;
    isUrgent?: boolean;
    notes?: string;
    localId?: string;
}
export declare class UpdateOrderDto {
    title?: string;
    status?: OrderStatus;
    progressPct?: number;
    dueDate?: string;
    notes?: string;
    isUrgent?: boolean;
}
