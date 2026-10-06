import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message,
                      style:
                          const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        ctx.read<ProfileBloc>().add(ProfileLoadRequested()),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context, ProfileEntity profile) {
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
            _Field(ctrl: shopCtrl, label: 'Nom de l\'atelier'),
            const SizedBox(height: 12),
            _Field(ctrl: locationCtrl, label: 'Localisation'),
            const SizedBox(height: 12),
            _Field(ctrl: bioCtrl, label: 'Bio', maxLines: 3),
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
                    'phone': phoneCtrl.text.trim(),
                     'businessName': shopCtrl.text.trim(),
                    'location': locationCtrl.text.trim(),
                    'bio': bioCtrl.text.trim(),
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
}

class _ProfileContent extends StatelessWidget {
  final ProfileEntity profile;
  const _ProfileContent({required this.profile});

  @override
  Widget build(BuildContext context) {
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
                  onTap: () async {
                    final picker = ImagePicker();
                    final img = await picker.pickImage(
                        source: ImageSource.gallery, imageQuality: 80);
                    if (img != null && context.mounted) {
                      context.read<ProfileBloc>().add(
                            ProfileAvatarUploadRequested(img.path),
                          );
                    }
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
              if (profile.shopName != null) ...[
                const SizedBox(height: 4),
                Text(profile.shopName!,
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 13)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Plan d'abonnement ──────────────────────────────────────────
        _PlanCard(profile: profile),
        const SizedBox(height: 20),

        // ── Statistiques d'utilisation ─────────────────────────────────
        _UsageCard(profile: profile),
        const SizedBox(height: 20),

        // ── Informations ────────────────────────────────────────────────
        _InfoSection(profile: profile),
        const SizedBox(height: 20),

        // ── Actions ─────────────────────────────────────────────────────
        _ActionSection(context: context),
        const SizedBox(height: 40),
      ],
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
              ? [AppColors.primary.withOpacity(0.3), AppColors.secondary.withOpacity(0.2)]
              : [AppColors.cardDark, AppColors.surfaceDark],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPremium
              ? AppColors.primary.withOpacity(0.5)
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
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Abonnement Premium'),
                        content: const Text(
                            'La souscription en ligne sera disponible après la configuration du paiement.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Fermer'),
                          ),
                        ],
                      ),
                    ),
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
    final isNearLimit = percent > 0.8;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            Text('$current / $max',
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
            value: percent,
            backgroundColor: AppColors.surfaceDark,
            color: isNearLimit
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
  const _ActionSection({required this.context});

  @override
  Widget build(BuildContext outerCtx) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        children: [
          _ActionItem(
            icon: Icons.lock_outline,
            label: 'Changer le mot de passe',
            onTap: () => _showChangePasswordSheet(outerCtx),
          ),
          const Divider(height: 1, color: AppColors.dividerDark),
          _ActionItem(
            icon: Icons.notifications_outlined,
            label: 'Rappels & Notifications',
            onTap: () => outerCtx.push('/notifications/config'),
          ),
          const Divider(height: 1, color: AppColors.dividerDark),
          _ActionItem(
            icon: Icons.language,
            label: 'Langue (Français)',
            onTap: () => _showLanguageDialog(outerCtx),
          ),
          const Divider(height: 1, color: AppColors.dividerDark),
          _ActionItem(
            icon: Icons.logout,
            label: 'Se déconnecter',
            color: AppColors.error,
            onTap: () {
              outerCtx.read<AuthBloc>().add(AuthLogoutRequested());
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
        title: const Text('Langue'),
        content: const Text('La langue active est le français. Le wolof sera ajouté prochainement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
        ],
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
