import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

class RemindersConfigPage extends StatefulWidget {
  const RemindersConfigPage({super.key});

  @override
  State<RemindersConfigPage> createState() => _RemindersConfigPageState();
}

class _RemindersConfigPageState extends State<RemindersConfigPage> {
  bool _whatsappEnabled = true;
  bool _smsEnabled = false;
  int _hoursBeforeDelivery = 24;
  final _templateCtrl = TextEditingController(
    text: 'Bonjour [Nom Client], votre commande de [Article] chez Ndokete est presque prête ! Livraison prévue le [Date].',
  );
  bool _loading = false;

  static const _defaultTemplate =
      'Bonjour [Nom Client], votre commande de [Article] chez Ndokete est presque prête ! Livraison prévue le [Date].';

  int get _characterCount => _templateCtrl.text.length;

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final client = getIt<ApiClient>();
      await client.patch('/artisans/profile', data: {
        'autoReminders': {
          'whatsappEnabled': _whatsappEnabled,
          'smsEnabled': _smsEnabled,
          'hoursBeforeDelivery': _hoursBeforeDelivery,
          'messageTemplate': _templateCtrl.text,
        },
      });
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration enregistrée'), backgroundColor: AppColors.success),
        );
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Configuration'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: const Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rappels Automatiques',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Gérez comment vos clients reçoivent leurs notifications de commande.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 28),

            // Canaux de communication
            const Text(
              'CANAUX DE COMMUNICATION',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1),
            ),
            const SizedBox(height: 12),

            // WhatsApp
            _ChannelToggle(
              icon: Icons.message_outlined,
              iconColor: const Color(0xFF25D366),
              label: 'WhatsApp',
              subtitle: '24h avant la livraison',
              value: _whatsappEnabled,
              onChanged: (v) => setState(() => _whatsappEnabled = v),
            ),
            const SizedBox(height: 12),

            // SMS
            _ChannelToggle(
              icon: Icons.sms_outlined,
              iconColor: AppColors.info,
              label: 'SMS Classique',
              subtitle: 'Indisponible',
              value: _smsEnabled,
              available: false,
              onChanged: (v) => setState(() => _smsEnabled = v),
            ),
            const SizedBox(height: 28),

            // Modèle de message
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MODÈLE DE MESSAGE',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1),
                ),
                GestureDetector(
                  onTap: () => setState(() => _templateCtrl.text = _defaultTemplate),
                  child: const Text(
                    'RESTAURER PAR DÉFAUT',
                    style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Variables disponibles
            Wrap(
              spacing: 8,
              children: ['[NOM CLIENT]', '[ARTICLE]', '[DATE]'].map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Text(tag, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500)),
              )).toList(),
            ),
            const SizedBox(height: 12),

            // Éditeur de message
            Stack(
              children: [
                TextFormField(
                  controller: _templateCtrl,
                  maxLines: 5,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.5),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: AppColors.cardDark,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                Positioned(
                  bottom: 8,
                  right: 12,
                  child: Text(
                    '$_characterCount/150',
                    style: TextStyle(
                      color: _characterCount > 150 ? AppColors.error : AppColors.textDisabled,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Les balises entre crochets seront remplacées automatiquement par les informations de la commande.',
              style: TextStyle(color: AppColors.textDisabled, fontSize: 11, height: 1.5),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Enregistrer les modifications'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ChannelToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool value;
  final bool available;
  final ValueChanged<bool> onChanged;

  const _ChannelToggle({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
    this.available = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value && available,
            activeColor: AppColors.primary,
            onChanged: available ? onChanged : null,
          ),
        ],
      ),
    );
  }
}
