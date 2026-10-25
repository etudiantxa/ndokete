import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

class AddEditProductPage extends StatefulWidget {
  final String? productId; // ID du produit en mode édition
  const AddEditProductPage({super.key, this.productId});

  @override
  State<AddEditProductPage> createState() => _AddEditProductPageState();
}

class _AddEditProductPageState extends State<AddEditProductPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Champs du formulaire
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _tagsController;
  
  String? _selectedCategory;
  List<String> _imageUrls = [];
  bool _isVitrine = false;
  bool _isActive = true; // Produit actif par défaut
  bool _isLoading = false;
  bool _loadingProduct = false;
  Map<String, dynamic>? _existingProduct;

  final List<String> _categories = [
    'Vêtements',
    'Accessoires',
    'Maison',
    'Chaussures',
    'Tissage',
    'Bijouterie',
    'Maroquin',
    'Couture',
    'Poterie',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  Future<void> _initializeForm() async {
    // Si mode édition, charger le produit
    if (widget.productId != null) {
      setState(() => _loadingProduct = true);
      
      try {
        final client = getIt<ApiClient>();
        final response = await client.get('/marketplace/${widget.productId}');
        final product = (response.data as Map)['data'] as Map<String, dynamic>;
        
        if (mounted) {
          setState(() {
            _existingProduct = product;
            _nameController = TextEditingController(text: product['name']);
            _descriptionController = TextEditingController(text: product['description'] ?? '');
            _priceController = TextEditingController(
              text: (product['price'] ~/ 1).toString(),
            );
            _stockController = TextEditingController(
              text: product['stock']?.toString() ?? '0',
            );
            final tags = product['tags'] as List<dynamic>?;
            _tagsController = TextEditingController(
              text: tags?.map((e) => e.toString()).join(', ') ?? '',
            );
            _selectedCategory = product['category'] as String?;
            if (_selectedCategory != null &&
                _selectedCategory!.isNotEmpty &&
                !_categories.contains(_selectedCategory)) {
              _categories.add(_selectedCategory!);
            }
            final photos = product['photos'] as List<dynamic>?;
            _imageUrls = photos?.map((e) => e.toString()).toList() ?? [];
            _isVitrine = product['isVitrine'] ?? false;
            _isActive = product['status'] == 'ACTIF'; // Charger le statut du produit
            _loadingProduct = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _loadingProduct = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
          context.pop();
        }
      }
    } else {
      // Mode création - initialisation vide
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _priceController = TextEditingController();
      _stockController = TextEditingController(text: '0');
      _tagsController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final client = getIt<ApiClient>();
      final data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        'price': int.parse(_priceController.text.trim()),
        'category': _selectedCategory!,
        'photos': _imageUrls,
        'stock': int.parse(_stockController.text.trim()),
        'tags': _tagsController.text.trim().isEmpty
            ? []
            : _tagsController.text.split(',').map((e) => e.trim()).toList(),
        'isVitrine': _isVitrine,
        'status': _isActive ? 'ACTIF' : 'INACTIF', // Envoyer le statut au backend
      };

      if (_existingProduct == null) {
        // Mode création
        await client.post('/marketplace/products', data: data);
      } else {
        // Mode édition
        await client.patch('/marketplace/products/${_existingProduct!['id']}', data: data);
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _existingProduct == null 
                  ? 'Produit créé avec succès' 
                  : 'Produit mis à jour avec succès',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Une erreur est survenue';
        if (e.toString().contains('Limite de 5 produits')) {
          errorMessage = 'Limite de 5 produits atteinte sur le plan gratuit. Passez au Premium !';
        } else {
          errorMessage = 'Erreur: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() => _isLoading = true);

        final client = getIt<ApiClient>();
        late final MultipartFile multipartFile;
        final filename = image.name.isNotEmpty
            ? image.name
            : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';

        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          multipartFile = MultipartFile.fromBytes(
            bytes,
            filename: filename,
          );
        } else {
          multipartFile = await MultipartFile.fromFile(
            image.path,
            filename: filename,
          );
        }

        final formData = FormData.fromMap({
          'file': multipartFile,
        });

        final response = await client.post('/uploads/image', data: formData);
        final imageUrl = (response.data as Map)['url'] as String;

        setState(() {
          _imageUrls.add(imageUrl);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Photo ajoutée avec succès !'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'envoi d\'image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Prendre une photo avec l\'appareil', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.secondary),
              title: const Text('Choisir depuis la galerie', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _existingProduct != null;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardDark.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
        ),
        title: Text(
          isEditing ? 'Modifier le produit' : 'Ajouter un produit',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          if (_isLoading || _loadingProduct)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _submitForm,
              child: Text(
                isEditing ? 'Enregistrer' : 'Créer',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _loadingProduct
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section: Images
                    const Text(
                      'Photos du produit',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Grille d'images
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._imageUrls.asMap().entries.map((entry) {
                          final index = entry.key;
                          final url = entry.value;
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.dividerDark),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: AppColors.cardDark,
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                        
                        // Bouton ajouter image
                        GestureDetector(
                          onTap: _showImageSourcePicker,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.cardDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section: Nom du produit
                    const Text(
                      'Nom du produit *',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Ex: Sac en cuir artisanal',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.cardDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Section: Catégorie
                    const Text(
                      'Catégorie *',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: (_selectedCategory != null &&
                              _categories.contains(_selectedCategory))
                          ? _selectedCategory
                          : null,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Sélectionner une catégorie',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.cardDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategory = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La catégorie est requise';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Section: Prix
                    const Text(
                      'Prix (FCFA) *',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _priceController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Ex: 15000',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        suffixText: 'FCFA',
                        suffixStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.cardDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le prix est requis';
                        }
                        final price = int.tryParse(value.trim());
                        if (price == null || price <= 0) {
                          return 'Prix invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Section: Stock
                    const Text(
                      'Stock disponible',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _stockController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Ex: 10',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.cardDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le stock est requis';
                        }
                        final stock = int.tryParse(value.trim());
                        if (stock == null || stock < 0) {
                          return 'Stock invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Section: Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Décrivez votre produit...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.cardDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section: Tags
                    const Text(
                      'Tags (séparés par des virgules)',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _tagsController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Ex: cuir, fait main, Dakar',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.cardDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section: Vitrine
                    SwitchListTile(
                      title: const Text(
                        'Produit vitrine',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Afficher en priorité sur la marketplace',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      value: _isVitrine,
                      activeThumbColor: AppColors.primary,
                      onChanged: (value) {
                        setState(() => _isVitrine = value);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Section: Statut du produit (Actif/Inactif)
                    SwitchListTile(
                      title: const Text(
                        'Produit visible',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _isActive 
                            ? 'Le produit est visible sur la marketplace'
                            : 'Le produit est masqué (brouillon)',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      value: _isActive,
                      activeThumbColor: AppColors.success,
                      inactiveThumbColor: AppColors.textSecondary,
                      inactiveTrackColor: AppColors.cardDark,
                      onChanged: (value) {
                        setState(() => _isActive = value);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Note informative
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Plan FREE: Maximum 5 produits. Passez au Premium pour plus!',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
