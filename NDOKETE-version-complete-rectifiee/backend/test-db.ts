import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function testDatabase() {
  console.log('🔍 Test de la base de données NDOKETE...\n');

  try {
    // Vérifier les artisans
    const artisans = await prisma.artisan.findMany({
      include: {
        user: { select: { email: true, role: true } },
        _count: { select: { products: true } },
      },
    });
    console.log(`✅ Artisans trouvés: ${artisans.length}`);
    artisans.forEach((artisan) => {
      console.log(`   - ${artisan.businessName} (${artisan.user.email}) - ${artisan._count.products} produits`);
    });

    // Vérifier les produits
    const products = await prisma.product.findMany({
      include: {
        artisan: { select: { businessName: true } },
      },
    });
    console.log(`\n✅ Produits trouvés: ${products.length}`);
    products.forEach((product) => {
      console.log(`   - ${product.name} (${product.price} FCFA) par ${product.artisan.businessName}`);
    });

    // Vérifier les clients
    const clients = await prisma.user.findMany({
      where: { role: 'CLIENT' },
      include: { client: true },
    });
    console.log(`\n✅ Clients trouvés: ${clients.length}`);
    clients.forEach((client) => {
      console.log(`   - ${client.email}`);
    });

    // Tester la requête du marketplace
    console.log('\n🧪 Test de la requête marketplace...');
    const marketplaceProducts = await prisma.product.findMany({
      where: { status: 'ACTIF' },
      include: {
        artisan: {
          select: { id: true, businessName: true, quarter: true, rating: true, profilePhoto: true },
        },
      },
      orderBy: [{ isVitrine: 'desc' }, { viewCount: 'desc' }],
      take: 5,
    });
    console.log(`✅ Marketplace query successful: ${marketplaceProducts.length} produits retournés`);

    console.log('\n✅ Tous les tests sont passés !');
  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    await prisma.$disconnect();
  }
}

testDatabase();
