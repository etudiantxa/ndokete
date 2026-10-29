import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

class InactivityWrapper extends StatefulWidget {
  final Widget child;

  const InactivityWrapper({super.key, required this.child});

  @override
  State<InactivityWrapper> createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends State<InactivityWrapper> {
  Timer? _timer;
  static const timeout = Duration(minutes: 15);

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
  void initState() {
    super.initState();
    _handleUserActivity();
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
