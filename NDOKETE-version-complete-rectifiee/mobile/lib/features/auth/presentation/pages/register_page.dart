import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _quarterCtrl = TextEditingController();
  String _role = 'ARTISAN';
  String? _selectedSpecialty;
  bool _obscurePassword = true;

  static const _specialties = [
    'Tailleur', 'Cordonnier', 'Bijoutier', 'Maroquinier',
    'Brodeur', 'Tisserand', 'Potier', 'Menuisier',
  ];

  static const _quarters = [
    'Médina', 'Plateau', 'HLM', 'Colobane', 'Sandaga',
    'Pikine', 'Guédiawaye', 'Thiès', 'Saint-Louis', 'Ziguinchor',
  ];

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthRegisterRequested(
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          password: _passwordCtrl.text,
          role: _role,
          businessName: _role == 'ARTISAN' ? _businessNameCtrl.text.trim() : null,
          specialty: _selectedSpecialty,
          quarter: _role == 'ARTISAN' ? _quarterCtrl.text.trim() : null,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Créer un compte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role selector
                const Text(
                  'Je suis un',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _RoleChip(
                      label: 'Artisan',
                      icon: Icons.handyman,
                      selected: _role == 'ARTISAN',
                      onTap: () => setState(() => _role = 'ARTISAN'),
                    ),
                    const SizedBox(width: 12),
                    _RoleChip(
                      label: 'Client',
                      icon: Icons.shopping_bag_outlined,
                      selected: _role == 'CLIENT',
                      onTap: () => setState(() => _role = 'CLIENT'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Champs communs
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
                  ),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Email invalide' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Téléphone (ex: +221771234567)',
                    prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 8) ? 'Numéro invalide' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 8) ? 'Minimum 8 caractères' : null,
                ),

                // Champs artisan uniquement
                if (_role == 'ARTISAN') ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Informations de votre atelier',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _businessNameCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Nom de votre atelier',
                      prefixIcon: Icon(Icons.store_outlined, color: AppColors.textSecondary),
                    ),
                    validator: (v) =>
                        (_role == 'ARTISAN' && (v == null || v.isEmpty))
                            ? 'Nom de l\'atelier requis'
                            : null,
                  ),
                  const SizedBox(height: 12),

                  // Spécialité dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedSpecialty,
                    dropdownColor: AppColors.cardDark,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Votre métier',
                      prefixIcon: Icon(Icons.work_outline, color: AppColors.textSecondary),
                    ),
                    items: _specialties.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, style: const TextStyle(color: AppColors.textPrimary)),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedSpecialty = v),
                  ),
                  const SizedBox(height: 12),

                  // Quartier dropdown
                  DropdownButtonFormField<String>(
                    dropdownColor: AppColors.cardDark,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Quartier / Ville',
                      prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
                    ),
                    items: _quarters.map((q) => DropdownMenuItem(
                      value: q,
                      child: Text(q, style: const TextStyle(color: AppColors.textPrimary)),
                    )).toList(),
                    onChanged: (v) {
                      if (v != null) _quarterCtrl.text = v;
                    },
                    validator: (v) => (_role == 'ARTISAN' && v == null)
                        ? 'Quartier requis'
                        : null,
                  ),
                ],

                const SizedBox(height: 32),

                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLoading ? AppColors.textSecondary : AppColors.primary,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Créer mon compte'),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.2) : AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.dividerDark,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
