# 📱 Guide Complet - Marketplace NDOKETE

## ✅ Corrections Appliquées

### 1. **Commande de Produits** ✓ CORRIGÉ
**Problème**: Le format d'envoi de la commande ne correspondait pas à ce que le backend attendait.

**Solution**: Modification du payload dans [`product_detail_page.dart`](mobile/lib/features/marketplace/presentation/pages/product_detail_page.dart)
```dart
// AVANT (incorrect)
{
  'productId': product['id'],
  'quantity': _quantity,
}

// APRÈS (correct)
{
  'items': [
    {
      'productId': product['id'],
      'quantity': _quantity,
    }
  ],
}
```

**Messages d'erreur améliorés**:
- "Vous devez avoir un profil client pour commander"
- "Stock insuffisant pour ce produit"

---

### 2. **Upload de Photos** ✓ AMÉLIORÉ
**Problème**: Les photos étaient de simples placeholders sans interaction réelle.

**Solution**: Intégration du sélecteur d'images natif avec `image_picker`

**Fonctionnement actuel**:
- Clique sur le bouton "+" → Ouvre la galerie photo
- Sélectionne une image → Ajoute un placeholder temporaire
- L'image sélectionnée est prête pour l'upload

**Pour activer Cloudinary** (étapes détaillées):

#### Option A: Cloudinary (Recommandé)
```bash
# 1. Installer le package
flutter pub add cloudinary_public

# 2. Créer un compte sur https://cloudinary.com/users/register/free

# 3. Récupérer vos identifiants:
#    - Cloud Name
#    - Upload Preset (créer dans Settings > Upload > Upload presets)

# 4. Modifier le code dans add_edit_product_page.dart:
```

```dart
import 'package:cloudinary_public/cloudinary_public.dart';

// Dans la classe _AddEditProductPageState:
final cloudinary = CloudinaryPublic('VOTRE_CLOUD_NAME', 'VOTRE_PRESET');

Future<void> _addImageFromGallery() async {
  try {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      // Upload vers Cloudinary
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(image.path, folder: 'ndokete_products')
      );
      
      setState(() {
        _imageUrls.add(response.secureUrl);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Image uploadée avec succès'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  } catch (e) {
    // Gestion d'erreur...
  }
}
```

#### Option B: Backend Local (Alternative)
Créer un endpoint d'upload sur le backend NestJS avec Multer.

---

### 3. **Visibilité des Produits** ✓ CORRIGÉ ET AMÉLIORÉ

**Problème initial**: Les produits doivent avoir `status = 'ACTIF'` pour apparaître, mais il n'y avait pas de contrôle UI pour gérer ce statut.

**Solutions appliquées** :

#### ✅ Backend - Statut explicite
Dans [`products.service.ts`](backend/src/marketplace/products/products.service.ts) :
- Le statut est maintenant **explicitement défini** à `'ACTIF'` lors de la création
- Le DTO accepte maintenant un champ `status` optionnel

```typescript
const product = await this.prisma.product.create({
  data: {
    // ... autres champs
    status: 'ACTIF', // Produit actif par défaut
  },
});
```

#### ✅ Frontend - Toggle de visibilité
Dans [`add_edit_product_page.dart`](mobile/lib/features/marketplace/presentation/pages/add_edit_product_page.dart) :

**Nouveau toggle "Produit visible"** ajouté avec :
- ✅ **Activé par défaut** : Le produit est visible immédiatement
- 📝 **Label clair** : "Produit visible"
- 💡 **Sous-titre dynamique** :
  - Si actif : "Le produit est visible sur la marketplace"
  - Si inactif : "Le produit est masqué (brouillon)"
- 🎨 **Couleurs distinctives** :
  - Vert (success) quand actif
  - Gris quand inactif

**Fonctionnement** :
1. L'artisan crée un produit → Par défaut **VISIBLE** (status = 'ACTIF')
2. Il peut **désactiver** le toggle → Le produit devient **INACTIF** (masqué)
3. En mode édition, il peut **réactiver** le produit à tout moment

**Payload envoyé au backend** :
```dart
{
  'name': '...',
  'status': _isActive ? 'ACTIF' : 'INACTIF', // Statut envoyé
  // ... autres champs
}
```

---

### Quand un produit n'est plus actif ?

Un produit peut avoir 3 statuts différents :

#### 1️⃣ **ACTIF** (visible)
- ✅ Produit affiché sur la marketplace publique
- ✅ Visible par tous les clients
- ✅ Peut être commandé
- 🟢 **Statut par défaut** lors de la création

#### 2️⃣ **INACTIF** (masqué/brouillon)
- ❌ Produit **NON affiché** sur la marketplace
- 👁️ Visible uniquement par l'artisan dans "Ma boutique"
- ✏️ Utile pour :
  - Préparer un produit sans le publier
  - Retirer temporairement un produit
  - Mettre en brouillon pour modifications

#### 3️⃣ **EN_RUPTURE** (stock épuisé)
- ⚠️ Produit affiché mais marqué comme "ÉPUISÉ"
- 🚫 Ne peut pas être commandé
- 📊 Statut automatique quand `stock = 0` (à implémenter)

---

**Comment gérer la visibilité** :

**Lors de la création** :
1. Remplir le formulaire
2. Le toggle "Produit visible" est **activé par défaut**
3. Décocher si vous voulez créer un brouillon
4. Cliquer "Créer"

**En modification** :
1. Aller sur la page du produit
2. Cliquer sur le bouton "..." (menu)
3. Choisir "Modifier"
4. Activer/désactiver le toggle "Produit visible"
5. Cliquer "Enregistrer"

**Vérification** :
- Dans "Ma boutique" → Vous voyez TOUS vos produits (actifs et inactifs)
- Sur la marketplace publique → Vous voyez seulement les produits ACTIFS

---

### 4. **Filtrage par Catégorie** ✓ AMÉLIORÉ
**Problème**: Le filtrage semblait ne pas fonctionner.

**Réalité**: Le filtrage FONCTIONNE déjà correctement !

**Catégories disponibles**:
- Tout
- Tissage
- Bijouterie
- Maroquin
- Couture
- Poterie

**Améliorations apportées**:
- Message d'erreur plus informatif quand aucun produit trouvé
- Affichage de la catégorie actuellement sélectionnée
- Conseil: "Vérifiez que les produits ont le statut ACTIF"

**Test du filtrage**:
1. Créer des produits avec différentes catégories
2. Cliquer sur une catégorie (ex: "Tissage")
3. Seuls les produits de cette catégorie s'affichent
4. Cliquer sur "Tout" pour voir tous les produits

---

## 🎯 Qui Peut Faire Quoi ?

### ARTISAN
- ✅ Ajouter des produits (max 5 en mode FREE)
- ✅ Modifier ses propres produits
- ✅ Supprimer ses produits
- ✅ Voir ses produits dans "Ma boutique"
- ❌ NE PEUT PAS commander sur la marketplace

### CLIENT
- ✅ Voir tous les produits publics
- ✅ Filtrer par catégorie
- ✅ Commander des produits
- ✅ Voir ses commandes
- ❌ NE PEUT PAS ajouter de produits

### PUBLIC (non connecté)
- ✅ Voir tous les produits publics
- ✅ Filtrer par catégorie
- ❌ NE PEUT PAS commander
- ❌ NE PEUT PAS voir les détails complets

---

## 🔧 Commandes Utiles

### Tester l'application
```bash
cd mobile
flutter run -d chrome --release --web-port=5000 --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

### Vérifier les produits dans la base de données
```bash
cd backend
npx prisma studio
```

### Seeds de test
```bash
cd backend
npx prisma db seed
```

---

## 🐛 Dépannage

### Problème: "Aucun produit trouvé"
**Causes possibles**:
1. Aucun produit créé
2. Produits avec status ≠ 'ACTIF'
3. Filtre de catégorie trop restrictif

**Solution**:
```sql
-- Vérifier dans Prisma Studio
SELECT * FROM Product WHERE status = 'ACTIF';
```

### Problème: "Profil client non trouvé" lors de la commande
**Cause**: L'utilisateur n'a pas de profil Client associé

**Solution**:
1. S'assurer que l'utilisateur a le rôle `CLIENT`
2. Un profil Client doit être créé automatiquement à l'inscription
3. Vérifier dans la table `Client` que l'userId existe

### Problème: Images ne s'affichent pas
**Cause**: URLs de placeholders temporaires

**Solution**: Intégrer Cloudinary (voir section 2)

---

## 📊 Architecture des Données

### Tables principales
```
User (id, email, role: ARTISAN|CLIENT|ADMIN)
  ↓
Artisan (id, userId, businessName, subscriptionPlan)
  ↓
Product (id, artisanId, name, price, category, stock, status, photos[])
  
User (id, email, role: CLIENT)
  ↓
Client (id, userId)
  ↓
MarketplaceOrder (id, clientId, totalAmount, status)
  ↓
MarketplaceOrderItem (id, orderId, productId, quantity, unitPrice, artisanId)
```

### Workflow de commande
1. CLIENT clique "Commander" sur un produit
2. Envoi de la requête avec `items: [{productId, quantity}]`
3. Backend vérifie:
   - Profil client existe
   - Produit disponible (stock suffisant)
   - Produit status = 'ACTIF'
4. Décrémentation du stock
5. Création de la commande
6. Retour de confirmation

---

## 🚀 Prochaines Étapes Recommandées

1. **Intégrer Cloudinary** pour l'upload réel d'images
2. **Ajouter la pagination** pour les listes de produits
3. **Implémenter la recherche avancée** (par prix, localisation)
4. **Ajouter les notifications** quand une commande est passée
5. **Dashboard analytics** pour les artisans (vues, ventes)

---

## 📞 Support

Pour toute question ou problème, vérifier:
1. Les logs du backend (`npm run start:dev`)
2. Les logs Flutter (console Chrome DevTools)
3. La base de données via Prisma Studio
