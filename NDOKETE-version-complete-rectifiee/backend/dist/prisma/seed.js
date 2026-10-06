"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const bcrypt = require("bcryptjs");
const prisma = new client_1.PrismaClient();
async function main() {
    console.log('🌱 Démarrage du seed NDOKETE...');
    const passwordHash = await bcrypt.hash('Demo1234!', 12);
    const artisanUser = await prisma.user.upsert({
        where: { email: 'moussa@ndokete.sn' },
        update: {},
        create: {
            email: 'moussa@ndokete.sn',
            phone: '+221771234567',
            passwordHash,
            role: 'ARTISAN',
            isVerified: true,
            artisan: {
                create: {
                    businessName: 'Atelier Moussa Couture',
                    specialty: ['Tailleur', 'Broderie'],
                    quarter: 'Médina',
                    city: 'Dakar',
                    waveNumber: '+221771234567',
                    isVerified: true,
                    rating: 4.8,
                    reviewCount: 24,
                    subscription: { create: { plan: 'PREMIUM', price: 5000 } },
                    analytics: { create: {} },
                    autoReminders: { create: { whatsappEnabled: true } },
                },
            },
        },
        include: { artisan: true },
    });
    const artisan = artisanUser.artisan;
    const customers = await Promise.all([
        prisma.customer.upsert({
            where: { id: 'seed-customer-1' },
            update: {},
            create: {
                id: 'seed-customer-1',
                artisanId: artisan.id,
                name: 'Fatou Diome',
                phone: '+221779876543',
                isVip: false,
                totalOrders: 3,
                measurements: {
                    cou: 36, epaule: 44, poitrine: 96, longueurBras: 60,
                    taille: 88, bassin: 102, longPantalon: 100,
                },
            },
        }),
        prisma.customer.upsert({
            where: { id: 'seed-customer-2' },
            update: {},
            create: {
                id: 'seed-customer-2',
                artisanId: artisan.id,
                name: 'Amadou Ba',
                phone: '+221776543210',
                isVip: true,
                totalOrders: 8,
                totalSpent: 156000,
                measurements: {
                    cou: 42, epaule: 48, poitrine: 102, longueurBras: 64,
                    taille: 92, bassin: 108, longPantalon: 105,
                },
            },
        }),
    ]);
    await prisma.order.createMany({
        skipDuplicates: true,
        data: [
            {
                id: 'seed-order-1',
                orderNumber: 'CMD-001',
                artisanId: artisan.id,
                customerId: customers[0].id,
                title: 'Boubou 3 pièces en soie',
                amount: 45000,
                deposit: 20000,
                status: 'EN_COURS',
                progressPct: 60,
                dueDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
                isUrgent: true,
            },
            {
                id: 'seed-order-2',
                orderNumber: 'CMD-002',
                artisanId: artisan.id,
                customerId: customers[1].id,
                title: 'Caftan Homme - Broderie Or',
                amount: 78000,
                deposit: 30000,
                status: 'PRET',
                progressPct: 100,
                dueDate: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000),
            },
        ],
    });
    await prisma.stockItem.createMany({
        skipDuplicates: true,
        data: [
            {
                id: 'seed-stock-1',
                artisanId: artisan.id,
                name: 'Tissu Bazin Riche',
                category: 'Tissus',
                unit: 'm',
                quantity: 12.5,
                alertThreshold: 5,
                costPerUnit: 3500,
                supplier: 'Sandaga Market',
            },
            {
                id: 'seed-stock-2',
                artisanId: artisan.id,
                name: 'Fil de Soie d\'Or',
                category: 'Fils',
                unit: 'u',
                quantity: 2,
                alertThreshold: 3,
                costPerUnit: 8000,
            },
            {
                id: 'seed-stock-3',
                artisanId: artisan.id,
                name: 'Tissu Wax Fleur',
                category: 'Tissus',
                unit: 'm',
                quantity: 45,
                alertThreshold: 5,
                costPerUnit: 2500,
            },
        ],
    });
    await prisma.transaction.createMany({
        skipDuplicates: true,
        data: [
            {
                artisanId: artisan.id,
                type: 'ENTREE',
                amount: 230000,
                category: 'Vente',
                description: 'Acompte Salon Royal',
                paymentMethod: 'WAVE',
                date: new Date(),
            },
            {
                artisanId: artisan.id,
                type: 'DEPENSE',
                amount: 85000,
                category: 'Tissu',
                description: 'Achat Bois (Ébène)',
                paymentMethod: 'ESPECES',
                date: new Date(),
            },
            {
                artisanId: artisan.id,
                type: 'ENTREE',
                amount: 120000,
                category: 'Vente',
                description: 'Solde Client Diop',
                paymentMethod: 'ORANGE_MONEY',
                date: new Date(),
            },
        ],
    });
    await prisma.user.upsert({
        where: { email: 'client@ndokete.sn' },
        update: {},
        create: {
            email: 'client@ndokete.sn',
            phone: '+221770000001',
            passwordHash,
            role: 'CLIENT',
            isVerified: true,
            client: { create: {} },
        },
    });
    console.log('✅ Seed terminé !');
    console.log('📧 Artisan: moussa@ndokete.sn / Demo1234!');
    console.log('📧 Client: client@ndokete.sn / Demo1234!');
}
main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
//# sourceMappingURL=seed.js.map