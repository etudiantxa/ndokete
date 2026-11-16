import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../theme/app_theme.dart';

class NdoketeLogoutDialog extends StatelessWidget {
  const NdoketeLogoutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.logout, color: AppColors.error, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Déconnexion',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: const SizedBox(
        width: 320,
        child: Text(
          'Voulez-vous vraiment vous déconnecter de votre session NDOKETE ?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            Navigator.pop(context);
            context.read<AuthBloc>().add(const AuthLogoutRequested());
            context.go('/login');
          },
          child: const Text('Se déconnecter', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
