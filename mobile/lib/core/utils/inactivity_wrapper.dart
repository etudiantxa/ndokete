import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../theme/app_theme.dart';
import 'security_checker.dart';

class InactivityWrapper extends StatefulWidget {
  final Widget child;

  const InactivityWrapper({super.key, required this.child});

  @override
  State<InactivityWrapper> createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends State<InactivityWrapper> {
  Timer? _timer;
  static const timeout = Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    _handleUserActivity();
    _checkSecurity();
  }

  Future<void> _checkSecurity() async {
    final compromised = await SecurityChecker.isDeviceCompromised();
    if (compromised && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text('Alerte de Sécurité', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Cet appareil semble rooté ou jailbreaké. Pour la sécurité de votre trésorerie et des données de vos clients, veillez à utiliser un appareil non modifié.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('J’ai compris', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  void _handleUserActivity([_]) {
    _timer?.cancel();
    _timer = Timer(timeout, () {
      if (!mounted) return;
      context.read<AuthBloc>().add(const AuthLogoutRequested());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session verrouillée pour inactivité (Sécurité des données de l’atelier).'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handleUserActivity,
      onPointerMove: _handleUserActivity,
      child: widget.child,
    );
  }
}
