import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/orders/presentation/pages/order_detail_page.dart';
import '../../features/orders/presentation/pages/create_order_page.dart';
import '../../features/clients/presentation/pages/clients_page.dart';
import '../../features/clients/presentation/pages/client_detail_page.dart';
import '../../features/clients/presentation/pages/measurements_page.dart';
import '../../features/stock/presentation/pages/stock_page.dart';
import '../../features/stock/presentation/pages/stock_detail_page.dart';
import '../../features/finance/presentation/pages/treasury_page.dart';
import '../../features/finance/presentation/pages/new_transaction_page.dart';
import '../../features/finance/presentation/pages/financial_report_page.dart';
import '../../features/marketplace/presentation/pages/marketplace_page.dart';
import '../../features/marketplace/presentation/pages/product_detail_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/notifications/presentation/pages/reminders_config_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter create(AuthBloc authBloc) => GoRouter(
        navigatorKey: _rootNavigatorKey,
        initialLocation: '/onboarding',
        refreshListenable: _GoRouterRefreshStream(authBloc.stream),
        redirect: (_, state) {
          final authState = authBloc.state;
          final isOnboarding = state.matchedLocation.startsWith('/onboarding');
          final isAuth = state.matchedLocation.startsWith('/login') ||
              state.matchedLocation.startsWith('/register');
          final user = authState is AuthAuthenticated ? authState.user : null;

          if (user != null) {
            final home = user.isArtisan ? '/dashboard' : '/marketplace';
            if (isOnboarding || isAuth) return home;
            if (!user.isArtisan &&
                _artisanOnlyRoutes
                    .any((route) => state.matchedLocation.startsWith(route))) {
              return home;
            }
            return null;
          }
          if (authState is AuthUnauthenticated || authState is AuthError) {
            if (isOnboarding) return null;
            if (!isAuth) return '/login';
          }
          return null;
        },
        routes: [
          GoRoute(path: '/', redirect: (_, __) => '/onboarding'),
          // ── Auth ────────────────────────────────────────────────────────────
          GoRoute(
              path: '/onboarding', builder: (_, __) => const OnboardingPage()),
          GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
          GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),

          // ── Dashboard ────────────────────────────────────────────────────────
          GoRoute(
              path: '/dashboard', builder: (_, __) => const DashboardPage()),

          // ── Commandes ───────────────────────────────────────────────────────
          GoRoute(
            path: '/orders',
            builder: (_, __) => const OrdersPage(),
            routes: [
              GoRoute(path: 'new', builder: (_, __) => const CreateOrderPage()),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    OrderDetailPage(orderId: state.pathParameters['id']!),
              ),
            ],
          ),

          // ── Clients ─────────────────────────────────────────────────────────
          GoRoute(
            path: '/clients',
            builder: (_, __) => const ClientsPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    ClientDetailPage(clientId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'measurements',
                    builder: (_, state) =>
                        MeasurementsPage(clientId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),

          // ── Stock ────────────────────────────────────────────────────────────
          GoRoute(
            path: '/stock',
            builder: (_, __) => const StockPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    StockDetailPage(itemId: state.pathParameters['id']!),
              ),
            ],
          ),

          // ── Finance ──────────────────────────────────────────────────────────
          GoRoute(
            path: '/finance',
            builder: (_, __) => const TreasuryPage(),
            routes: [
              GoRoute(
                  path: 'new', builder: (_, __) => const NewTransactionPage()),
              GoRoute(
                  path: 'report',
                  builder: (_, __) => const FinancialReportPage()),
            ],
          ),

          // ── Marketplace ──────────────────────────────────────────────────────
          GoRoute(
            path: '/marketplace',
            builder: (_, __) => const MarketplacePage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    ProductDetailPage(productId: state.pathParameters['id']!),
              ),
            ],
          ),

          // ── Notifications ────────────────────────────────────────────────────
          GoRoute(
            path: '/notifications',
            builder: (_, __) => const NotificationsPage(),
            routes: [
              GoRoute(
                  path: 'config',
                  builder: (_, __) => const RemindersConfigPage()),
            ],
          ),

          // ── Profil ───────────────────────────────────────────────────────────
          GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
        ],
        errorBuilder: (context, state) => Scaffold(
          backgroundColor: const Color(0xFF0F1117),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: Color(0xFFF5A623), size: 56),
                const SizedBox(height: 16),
                const Text(
                  'Page introuvable',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('Retour au tableau de bord',
                      style: TextStyle(color: Color(0xFFF5A623))),
                ),
              ],
            ),
          ),
        ),
      );

  static const _artisanOnlyRoutes = [
    '/dashboard',
    '/orders',
    '/clients',
    '/stock',
    '/finance',
    '/notifications/config',
  ];
}

class _GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;

  _GoRouterRefreshStream(Stream<AuthState> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
