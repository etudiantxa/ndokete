import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/storage/hive_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// Gestionnaire Firebase background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (!kIsWeb) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    // Firebase
    await Firebase.initializeApp();
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  } catch (error) {
    // L’application reste utilisable sans notifications tant que Firebase
    // n’est pas configuré pour la plateforme ciblée.
    debugPrint('Firebase non configuré : $error');
  }

  try {
    // Dates françaises
    await initializeDateFormatting('fr_FR', null);
    debugPrint('NDOKETE: dates initialisées');

    // Injection de dépendances (get_it) - inclut HiveService
    await setupDependencies();
    debugPrint('NDOKETE: dépendances initialisées');

    // Initialisation Hive pour stockage offline
    final hiveService = getIt<HiveService>();
    await hiveService.init();
    debugPrint('NDOKETE: Hive initialisé');

    final authBloc = getIt<AuthBloc>();
    debugPrint('NDOKETE: AuthBloc créé');
    runApp(NdoketeApp(authBloc: authBloc));
    debugPrint('NDOKETE: runApp appelé');
  } catch (error, stackTrace) {
    debugPrint('Erreur au démarrage de NDOKETE : $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(_StartupErrorApp(error: error.toString()));
  }
}

class _StartupErrorApp extends StatelessWidget {
  final String error;

  const _StartupErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F1117),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: SelectableText(
              'NDOKETE ne peut pas démarrer sur cet aperçu.\n\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class NdoketeApp extends StatefulWidget {
  final AuthBloc authBloc;

  const NdoketeApp({super.key, required this.authBloc});

  @override
  State<NdoketeApp> createState() => _NdoketeAppState();
}

class _NdoketeAppState extends State<NdoketeApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.create(widget.authBloc);
    widget.authBloc.add(const AuthCheckRequested());
  }

  @override
  void dispose() {
    _router.dispose();
    widget.authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const diagnosticPreview = bool.fromEnvironment(
      'NDOKETE_PREVIEW_DIAGNOSTIC',
      defaultValue: false,
    );
    if (diagnosticPreview) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0F1117),
          body: const Center(
            child: Text(
              'NDOKETE Flutter Web est démarré',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
        ),
      );
    }

    return BlocProvider.value(
      value: widget.authBloc,
      child: MaterialApp.router(
        title: 'NDOKETE',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
         routerConfig: _router,
        locale: const Locale('fr', 'FR'),
        supportedLocales: const [
          Locale('fr', 'FR'),
          Locale('wo'), // Wolof
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
