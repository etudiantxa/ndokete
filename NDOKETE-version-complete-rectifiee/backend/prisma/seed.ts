import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Démarrage du seed NDOKETE...');

  // ── Artisan de démo ──────────────────────────────────────────────────────
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

  const artisan = artisanUser.artisan!;

  // ── Clients de l'artisan ─────────────────────────────────────────────────
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

  // ── Commandes ────────────────────────────────────────────────────────────
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

  // ── Stock ────────────────────────────────────────────────────────────────
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

  // ── Transactions ─────────────────────────────────────────────────────────
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

  // ── Client marketplace de démo ────────────────────────────────────────────
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

  // ── Produits Marketplace de démo ─────────────────────────────────────────
  await prisma.product.createMany({
    skipDuplicates: true,
    data: [
      {
        id: 'seed-product-1',
        artisanId: artisan.id,
        name: 'Boubou Traditionnel Bleu Royal',
        description: 'Magnifique boubou 3 pièces en tissu bazin riche avec broderie or faite main. Idéal pour les cérémonies et fêtes traditionnelles.',
        price: 45000,
        category: 'Vêtements',
        photos: [
          'https://images.unsplash.com/photo-1598532163257-ae3c6b2524b6?w=800',
          'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800',
        ],
        stock: 5,
        tags: ['boubou', 'traditionnel', 'broderie', 'bazin'],
        isVitrine: true,
        status: 'ACTIF',
        viewCount: 124,
      },
      {
        id: 'seed-product-2',
        artisanId: artisan.id,
        name: 'Caftan Homme Brodé Or',
        description: 'Caftan élégant avec broderies dorées artisanales. Tissu de qualité supérieure, parfait pour les occasions spéciales.',
        price: 78000,
        category: 'Vêtements',
        photos: [
          'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=800',
        ],
        stock: 3,
        tags: ['caftan', 'luxe', 'broderie', 'or'],
        isVitrine: true,
        status: 'ACTIF',
        viewCount: 89,
      },
      {
        id: 'seed-product-3',
        artisanId: artisan.id,
        name: 'Robe Wax Africaine Moderne',
        description: 'Robe moderne en tissu wax aux motifs colorés. Coupe ajustée et confortable pour un look africain contemporain.',
        price: 35000,
        category: 'Vêtements',
        photos: [
          'https://images.unsplash.com/photo-1583391733956-6c78276477e2?w=800',
          'https://images.unsplash.com/photo-1595777457583-95e059d58b8d?w=800',
        ],
        stock: 8,
        tags: ['robe', 'wax', 'moderne', 'femme'],
        isVitrine: false,
        status: 'ACTIF',
        viewCount: 67,
      },
      {
        id: 'seed-product-4',
        artisanId: artisan.id,
        name: 'Sac Artisanal en Cuir',
        description: 'Sac à main fait main en cuir véritable. Design unique inspiré des motifs traditionnels sénégalais.',
        price: 25000,
        category: 'Accessoires',
        photos: [
          'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=800',
        ],
        stock: 12,
        tags: ['sac', 'cuir', 'artisanal', 'accessoires'],
        isVitrine: true,
        status: 'ACTIF',
        viewCount: 156,
      },
      {
        id: 'seed-product-5',
        artisanId: artisan.id,
        name: 'Parure de Lit Bazin',
        description: 'Ensemble parure de lit en tissu bazin de qualité. Housse de couette + 2 taies d\'oreiller brodées main.',
        price: 55000,
        category: 'Maison',
        photos: [
          'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=800',
        ],
        stock: 4,
        tags: ['maison', 'bazin', 'broderie', 'literie'],
        isVitrine: false,
        status: 'ACTIF',
        viewCount: 43,
      },
      {
        id: 'seed-product-6',
        artisanId: artisan.id,
        name: 'Sandales Traditionnelles Cuir',
        description: 'Sandales artisanales en cuir tanné naturellement. Confortables et durables, fabriquées selon les techniques ancestrales.',
        price: 15000,
        category: 'Chaussures',
        photos: [
          'https://images.unsplash.com/photo-1603487742131-4160ec999306?w=800',
        ],
        stock: 20,
        tags: ['sandales', 'cuir', 'chaussures', 'traditionnel'],
        isVitrine: false,
        status: 'ACTIF',
        viewCount: 98,
      },
    ],
  });

  console.log('✅ Seed terminé !');
  console.log('📧 Artisan: moussa@ndokete.sn / Demo1234!');
  console.log('📧 Client: client@ndokete.sn / Demo1234!');
  console.log('🛍️  6 produits marketplace créés');
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
