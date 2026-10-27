import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/wolof_dictionary.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../../domain/entities/profile_entity.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ProfileBloc>()..add(ProfileLoadRequested()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Mon Profil'),
        actions: [
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (ctx, state) {
              if (state is ProfileLoaded) {
                return IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showEditSheet(ctx, state.profile),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (ctx, state) {
          if (state is ProfileActionSuccess) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ));
          }
          if (state is ProfileError) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ));
          }
        },
        builder: (ctx, state) {
          if (state is ProfileLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state is ProfileLoaded) {
            return _ProfileContent(profile: state.profile);
          }
          if (state is ProfileError) {
            final isAuthError = state.message.toLowerCase().contains('unauthorized') ||
                state.message.toLowerCase().contains('expirée') ||
                state.message.toLowerCase().contains('session');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isAuthError ? Icons.lock_clock_outlined : Icons.error_outline,
                      size: 56,
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isAuthError
                          ? 'Votre session a expiré'
                          : state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAuthError
                          ? 'Veuillez vous reconnecter pour accéder à votre profil.'
                          : 'Impossible de charger le profil.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        if (isAuthError) {
                          ctx.read<AuthBloc>().add(const AuthLogoutRequested());
                          ctx.go('/login');
                        } else {
                          ctx.read<ProfileBloc>().add(ProfileLoadRequested());
                        }
                      },
                      child: Text(isAuthError ? 'Se reconnecter' : 'Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context, ProfileEntity profile) {
    final isArtisan = profile.isArtisan;
    final nameCtrl = TextEditingController(text: profile.name);
    final phoneCtrl = TextEditingController(text: profile.phone ?? '');
    final shopCtrl = TextEditingController(text: profile.shopName ?? '');
    final locationCtrl = TextEditingController(text: profile.location ?? '');
    final bioCtrl = TextEditingController(text: profile.bio ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Modifier le profil',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _Field(ctrl: nameCtrl, label: 'Nom complet'),
            const SizedBox(height: 12),
            _Field(ctrl: phoneCtrl, label: 'Téléphone', type: TextInputType.phone),
            const SizedBox(height: 12),
            if (isArtisan) ...[
              _Field(ctrl: shopCtrl, label: 'Nom de l\'atelier'),
              const SizedBox(height: 12),
              _Field(ctrl: locationCtrl, label: 'Localisation / Quartier'),
              const SizedBox(height: 12),
              _Field(ctrl: bioCtrl, label: 'Bio', maxLines: 3),
            ] else ...[
              _Field(ctrl: locationCtrl, label: 'Adresse de livraison'),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  context.read<ProfileBloc>().add(ProfileUpdateRequested({
                    'name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    if (isArtisan) 'businessName': shopCtrl.text.trim(),
                    'location': locationCtrl.text.trim(),
                    if (isArtisan) 'bio': bioCtrl.text.trim(),
                  }));
                  Navigator.pop(ctx);
                },
                child: const Text('Sauvegarder',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool?> _showPaymentSimulationDialog({
    required BuildContext context,
    required String planLabel,
    required int amount,
    required String method,
    required String phone,
  }) {
    final pinCtrl = TextEditingController();
    bool isProcessing = false;
    final isWave = method == 'WAVE';

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isWave ? Icons.waves : Icons.phone_android,
                color: isWave ? AppColors.secondary : Colors.orange,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isWave ? 'Paiement Wave' : 'Paiement Orange Money',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.dividerDark),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Services :',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        Text(planLabel,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Montant :',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        Text('$amount FCFA',
                            style: TextStyle(
                                color:
                                    isWave ? AppColors.secondary : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Téléphone :',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        Text(phone,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Entrez votre code secret à 4 chiffres pour autoriser le prélèvement :',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    letterSpacing: 8),
                decoration: const InputDecoration(
                  hintText: '••••',
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  isProcessing ? null : () => Navigator.pop(dialogCtx, false),
              child: const Text('Annuler',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isWave ? AppColors.secondary : Colors.orange,
                foregroundColor: Colors.black,
              ),
              onPressed: isProcessing
                  ? null
                  : () async {
                      if (pinCtrl.text.length < 4) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Veuillez entrer un code PIN à 4 chiffres.')),
                        );
                        return;
                      }
                      setDialogState(() => isProcessing = true);
                      await Future<void>.delayed(
                          const Duration(milliseconds: 1200));
                      if (ctx.mounted) Navigator.pop(dialogCtx, true);
                    },
              child: isProcessing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Text('Valider le Paiement',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  static void showUpgradeSheet(BuildContext context, ProfileEntity profile) {
    String selectedPlan = 'PREMIUM';
    String selectedMethod = 'WAVE';
    final phoneCtrl = TextEditingController(text: profile.phone ?? '');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium,
                      color: AppColors.primary, size: 28),
                  const SizedBox(width: 10),
                  const Text(
                    'Abonnement Premium NDOKETE',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Choisissez votre formule d\'abonnement :',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setSheetState(() => selectedPlan = 'PREMIUM'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selectedPlan == 'PREMIUM'
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedPlan == 'PREMIUM'
                                ? AppColors.primary
                                : AppColors.dividerDark,
                            width: selectedPlan == 'PREMIUM' ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Premium',
                              style: TextStyle(
                                color: selectedPlan == 'PREMIUM'
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '5 000 FCFA/mois',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Clients & Produits illimités',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.textPrimary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setSheetState(() => selectedPlan = 'PREMIUM_PLUS'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selectedPlan == 'PREMIUM_PLUS'
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedPlan == 'PREMIUM_PLUS'
                                ? AppColors.primary
                                : AppColors.dividerDark,
                            width: selectedPlan == 'PREMIUM_PLUS' ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Premium+',
                              style: TextStyle(
                                color: selectedPlan == 'PREMIUM_PLUS'
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '10 000 FCFA/mois',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Priorité Marketplace & Support',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.textPrimary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text(
                'Moyen de paiement :',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setSheetState(() => selectedMethod = 'WAVE'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selectedMethod == 'WAVE'
                              ? AppColors.secondary.withValues(alpha: 0.2)
                              : AppColors.cardDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedMethod == 'WAVE'
                                ? AppColors.secondary
                                : AppColors.dividerDark,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.waves,
                                color: AppColors.secondary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Wave',
                              style: TextStyle(
                                color: selectedMethod == 'WAVE'
                                    ? AppColors.secondary
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setSheetState(() => selectedMethod = 'ORANGE_MONEY'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selectedMethod == 'ORANGE_MONEY'
                              ? Colors.orange.withValues(alpha: 0.2)
                              : AppColors.cardDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedMethod == 'ORANGE_MONEY'
                                ? Colors.orange
                                : AppColors.dividerDark,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.phone_android,
                                color: Colors.orange, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Orange Money',
                              style: TextStyle(
                                color: selectedMethod == 'ORANGE_MONEY'
                                    ? Colors.orange
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone de paiement',
                  prefixIcon: Icon(Icons.phone, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final amount = selectedPlan == 'PREMIUM' ? 5000 : 10000;
                          final confirmed = await _showPaymentSimulationDialog(
                            context: context,
                            planLabel: selectedPlan == 'PREMIUM' ? 'Premium (5 000 FCFA)' : 'Premium+ (10 000 FCFA)',
                            amount: amount,
                            method: selectedMethod,
                            phone: phoneCtrl.text.trim(),
                          );

                          if (confirmed != true) return;

                          setSheetState(() => isSubmitting = true);
                          try {
                            final client = getIt<ApiClient>();
                            final response = await client.post(
                              '/subscriptions/upgrade',
                              data: {
                                'plan': selectedPlan,
                                'method': selectedMethod,
                                'phone': phoneCtrl.text.trim(),
                              },
                            );
                            if (ctx.mounted) {
                              Navigator.pop(sheetCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    (response.data as Map)['message']
                                            ?.toString() ??
                                        'Abonnement activé avec succès !',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              context
                                  .read<ProfileBloc>()
                                  .add(ProfileLoadRequested());
                            }
                          } catch (e) {
                            setSheetState(() => isSubmitting = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Échec du paiement : $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          'Payer ${selectedPlan == 'PREMIUM' ? '5 000' : '10 000'} FCFA via $selectedMethod',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final ProfileEntity profile;
  const _ProfileContent({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isArtisan = profile.isArtisan;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Avatar + Infos ─────────────────────────────────────────────
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: AppColors.cardDark,
                backgroundImage: profile.avatarUrl != null
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
                child: profile.avatarUrl == null
                    ? Text(
                        profile.name.isNotEmpty
                            ? profile.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 36,
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppColors.surfaceDark,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (bottomCtx) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.camera_alt,
                                  color: AppColors.primary),
                              title: const Text('Prendre une photo',
                                  style:
                                      TextStyle(color: AppColors.textPrimary)),
                              onTap: () async {
                                Navigator.pop(bottomCtx);
                                final picker = ImagePicker();
                                final img = await picker.pickImage(
                                    source: ImageSource.camera, imageQuality: 80);
                                if (img != null && context.mounted) {
                                  context.read<ProfileBloc>().add(
                                        ProfileAvatarUploadRequested(img.path),
                                      );
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library,
                                  color: AppColors.secondary),
                              title: const Text('Choisir dans la galerie',
                                  style:
                                      TextStyle(color: AppColors.textPrimary)),
                              onTap: () async {
                                Navigator.pop(bottomCtx);
                                final picker = ImagePicker();
                                final img = await picker.pickImage(
                                    source: ImageSource.gallery, imageQuality: 80);
                                if (img != null && context.mounted) {
                                  context.read<ProfileBloc>().add(
                                        ProfileAvatarUploadRequested(img.path),
                                      );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.backgroundDark, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.black, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              Text(profile.name,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(profile.email,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isArtisan
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isArtisan ? (profile.shopName ?? 'Atelier Artisan') : 'Compte Client',
                  style: TextStyle(
                    color: isArtisan ? AppColors.primary : AppColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (isArtisan) ...[
          // ── Plan d'abonnement ──────────────────────────────────────────
          _PlanCard(profile: profile),
          const SizedBox(height: 20),

          // ── Statistiques d'utilisation ─────────────────────────────────
          _UsageCard(profile: profile),
          const SizedBox(height: 20),
        ] else ...[
          // ── Espace Client Spécifique ────────────────────────────────────
          _ClientCard(profile: profile),
          const SizedBox(height: 20),
        ],

        // ── Informations ────────────────────────────────────────────────
        _InfoSection(profile: profile),
        const SizedBox(height: 20),

        // ── Actions ─────────────────────────────────────────────────────
        _ActionSection(context: context, profile: profile),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _ClientCard extends StatelessWidget {
  final ProfileEntity profile;
  const _ClientCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag_outlined,
                  color: AppColors.primary, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Espace Acheteur NDOKETE',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Actif',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Explorez les créations d’artisans sénégalais, passez vos commandes en ligne et suivez vos livraisons en toute simplicité.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/marketplace?tab=0'),
                  icon: const Icon(Icons.storefront, size: 18),
                  label: const Text('Voir la Boutique'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final ProfileEntity profile;
  const _PlanCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isPremium = profile.isPremium;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium
              ? [AppColors.primary.withValues(alpha: 0.3), AppColors.secondary.withValues(alpha: 0.2)]
              : [AppColors.cardDark, AppColors.surfaceDark],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPremium
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.dividerDark,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPremium ? Icons.workspace_premium : Icons.person_outline,
            color: isPremium ? AppColors.primary : AppColors.textSecondary,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.planLabel,
                  style: TextStyle(
                    color: isPremium ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (!isPremium)
                  const Text(
                    'Passez Premium pour des fonctionnalités illimitées',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                if (profile.planExpiresAt != null)
                  Text(
                    'Expire le ${profile.planExpiresAt!.day}/${profile.planExpiresAt!.month}/${profile.planExpiresAt!.year}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (!isPremium)
            ElevatedButton(
              onPressed: () => _ProfileView.showUpgradeSheet(context, profile),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Upgrader',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  final ProfileEntity profile;
  const _UsageCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Utilisation du plan',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          const SizedBox(height: 16),
          _UsageBar(
            label: 'Clients',
            current: profile.clientsCount,
            max: profile.clientsLimit,
            percent: profile.clientsUsagePercent,
          ),
          const SizedBox(height: 12),
          _UsageBar(
            label: 'Produits marketplace',
            current: profile.productsCount,
            max: profile.productsLimit,
            percent: profile.productsUsagePercent,
          ),
        ],
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  final String label;
  final int current;
  final int max;
  final double percent;
  const _UsageBar(
      {required this.label,
      required this.current,
      required this.max,
      required this.percent});

  @override
  Widget build(BuildContext context) {
    final isUnlimited = max >= 99999;
    final isNearLimit = !isUnlimited && percent > 0.8;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            Text(isUnlimited ? '$current / Illimité' : '$current / $max',
                style: TextStyle(
                    color: isNearLimit ? AppColors.warning : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: isUnlimited ? 0.1 : percent,
            backgroundColor: AppColors.surfaceDark,
            color: isUnlimited
                ? AppColors.primary
                : isNearLimit
                    ? AppColors.warning
                    : percent >= 1
                        ? AppColors.error
                        : AppColors.primary,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final ProfileEntity profile;
  const _InfoSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        children: [
          if (profile.phone != null)
            _InfoRow(icon: Icons.phone_outlined, label: profile.phone!),
          if (profile.location != null)
            _InfoRow(icon: Icons.location_on_outlined, label: profile.location!),
          if (profile.artisanType != null)
            _InfoRow(
                icon: Icons.work_outline,
                label: profile.artisanType!.name.toUpperCase()),
          if (profile.bio != null)
            _InfoRow(icon: Icons.info_outline, label: profile.bio!),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  final BuildContext context;
  final ProfileEntity profile;
  const _ActionSection({required this.context, required this.profile});

  @override
  Widget build(BuildContext outerCtx) {
    final isArtisan = profile.isArtisan;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        children: [
          if (profile.role == 'ADMIN' || profile.email.contains('admin')) ...[
            _ActionItem(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Administration NDOKETE (Super-Admin)',
              color: AppColors.primary,
              onTap: () => outerCtx.push('/admin'),
            ),
            const Divider(height: 1, color: AppColors.dividerDark),
          ],
          _ActionItem(
            icon: Icons.lock_outline,
            label: 'Changer le mot de passe',
            onTap: () => _showChangePasswordSheet(outerCtx),
          ),
          const Divider(height: 1, color: AppColors.dividerDark),
          if (isArtisan)
            _ActionItem(
              icon: Icons.notifications_outlined,
              label: 'Rappels & Notifications Automatiques',
              onTap: () => outerCtx.push('/notifications/config'),
            )
          else
            _ActionItem(
              icon: Icons.notifications_none,
              label: 'Mes Notifications',
              onTap: () => outerCtx.push('/notifications'),
            ),
          const Divider(height: 1, color: AppColors.dividerDark),
          _ActionItem(
            icon: Icons.cloud_sync_outlined,
            label: 'Synchronisation & Mode Hors-Ligne',
            onTap: () => outerCtx.push('/sync'),
          ),
          const Divider(height: 1, color: AppColors.dividerDark),
          if (isArtisan) ...[
            _ActionItem(
              icon: Icons.group_outlined,
              label: 'Gestion d’Équipe & Apprentis',
              onTap: () => outerCtx.push('/team'),
            ),
            const Divider(height: 1, color: AppColors.dividerDark),
            _ActionItem(
              icon: Icons.workspace_premium_outlined,
              label: 'Mon Abonnement & Facturation Pro',
              onTap: () => outerCtx.push('/subscription'),
            ),
            const Divider(height: 1, color: AppColors.dividerDark),
          ],
          _ActionItem(
            icon: Icons.language,
            label: 'Langue / Tànn Lakk',
            onTap: () => _showLanguageDialog(outerCtx),
          ),
          const Divider(height: 1, color: AppColors.dividerDark),
          _ActionItem(
            icon: AppTheme.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            label: AppTheme.isDark ? 'Mode Thème Clair' : 'Mode Thème Sombre',
            onTap: () {
              AppTheme.toggleTheme();
              ScaffoldMessenger.of(outerCtx).showSnackBar(
                SnackBar(
                  content: Text(AppTheme.isDark ? '✓ Thème Sombre activé' : '✓ Thème Clair activé'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppColors.dividerDark),
          _ActionItem(
            icon: Icons.logout,
            label: 'Se déconnecter',
            color: AppColors.error,
            onTap: () {
              outerCtx.read<AuthBloc>().add(const AuthLogoutRequested());
            },
          ),
        ],
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext ctx) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Changer le mot de passe',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _Field(
                ctrl: currentCtrl,
                label: 'Mot de passe actuel',
                obscure: true),
            const SizedBox(height: 12),
            _Field(
                ctrl: newCtrl,
                label: 'Nouveau mot de passe',
                obscure: true),
            const SizedBox(height: 12),
            _Field(
                ctrl: confirmCtrl,
                label: 'Confirmer le nouveau',
                obscure: true),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () {
                   if (currentCtrl.text.isEmpty || newCtrl.text.length < 8) {
                     ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                       content: Text('Le nouveau mot de passe doit contenir au moins 8 caractères.'),
                       backgroundColor: AppColors.error,
                     ));
                   } else if (newCtrl.text == confirmCtrl.text) {
                    ctx.read<ProfileBloc>().add(ProfilePasswordChangeRequested(
                          currentCtrl.text.trim(),
                          newCtrl.text.trim(),
                        ));
                    Navigator.pop(sheetCtx);
                   } else {
                     ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                       content: Text('Les mots de passe ne correspondent pas.'),
                       backgroundColor: AppColors.error,
                     ));
                  }
                },
                child: const Text('Confirmer',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext ctx) {
    showDialog<void>(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.language, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Langue / Tànn Lakk', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇫🇷', style: TextStyle(fontSize: 24)),
              title: const Text('Français', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              subtitle: const Text('Langue officielle', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              onTap: () {
                WolofDictionary.setLanguage('fr');
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('✓ Langue active : Français'), backgroundColor: AppColors.success),
                );
              },
            ),
            const Divider(color: AppColors.dividerDark),
            ListTile(
              leading: const Text('🇸🇳', style: TextStyle(fontSize: 24)),
              title: const Text('Wolof (Sénégal)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              subtitle: const Text('Dictionnaire & Lexique wolof artisanal', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              onTap: () {
                WolofDictionary.setLanguage('wo');
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('✓ Lakk bi tànn na : Wolof (Dalal ak jamm)'), backgroundColor: AppColors.success),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 14))),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool obscure;
  final TextInputType type;
  final int maxLines;
  const _Field({
    required this.ctrl,
    required this.label,
    this.obscure = false,
    this.type = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: type,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
