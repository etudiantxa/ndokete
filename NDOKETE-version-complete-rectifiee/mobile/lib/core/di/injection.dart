import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../storage/hive_service.dart';

// ── Auth ─────────────────────────────────────────────────────────────────────
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// ── Orders ───────────────────────────────────────────────────────────────────
import '../../features/orders/data/datasources/orders_remote_datasource.dart';
import '../../features/orders/data/repositories/orders_repository_impl.dart';
import '../../features/orders/domain/repositories/orders_repository.dart';
import '../../features/orders/domain/usecases/get_orders_usecase.dart';
import '../../features/orders/domain/usecases/create_order_usecase.dart';
import '../../features/orders/domain/usecases/update_order_status_usecase.dart';
import '../../features/orders/presentation/bloc/orders_bloc.dart';

// ── Clients ──────────────────────────────────────────────────────────────────
import '../../features/clients/data/datasources/clients_remote_datasource.dart';
import '../../features/clients/data/repositories/clients_repository_impl.dart';
import '../../features/clients/domain/repositories/clients_repository.dart';
import '../../features/clients/domain/usecases/get_clients_usecase.dart';
import '../../features/clients/domain/usecases/save_measurements_usecase.dart';
import '../../features/clients/presentation/bloc/clients_bloc.dart';

// ── Stock ────────────────────────────────────────────────────────────────────
import '../../features/stock/data/datasources/stock_remote_datasource.dart';
import '../../features/stock/data/repositories/stock_repository_impl.dart';
import '../../features/stock/domain/repositories/stock_repository.dart';
import '../../features/stock/domain/usecases/get_stock_usecase.dart';
import '../../features/stock/domain/usecases/adjust_stock_usecase.dart';
import '../../features/stock/presentation/bloc/stock_bloc.dart';

// ── Finance ──────────────────────────────────────────────────────────────────
import '../../features/finance/data/datasources/finance_remote_datasource.dart';
import '../../features/finance/data/repositories/finance_repository_impl.dart';
import '../../features/finance/domain/repositories/finance_repository.dart';
import '../../features/finance/domain/usecases/get_treasury_usecase.dart';
import '../../features/finance/domain/usecases/create_transaction_usecase.dart';
import '../../features/finance/presentation/bloc/finance_bloc.dart';

// ── Marketplace ──────────────────────────────────────────────────────────────
import '../../features/marketplace/data/datasources/marketplace_remote_datasource.dart';
import '../../features/marketplace/data/repositories/marketplace_repository_impl.dart';
import '../../features/marketplace/domain/repositories/marketplace_repository.dart';
import '../../features/marketplace/domain/usecases/get_products_usecase.dart';
import '../../features/marketplace/domain/usecases/place_order_usecase.dart';
import '../../features/marketplace/presentation/bloc/marketplace_bloc.dart';

// ── Notifications ────────────────────────────────────────────────────────────
import '../../features/notifications/data/datasources/notifications_remote_datasource.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/domain/usecases/get_notifications_usecase.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';

// ── Profile ──────────────────────────────────────────────────────────────────
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // ── Core ───────────────────────────────────────────────────────────────────
  getIt.registerSingleton<HiveService>(HiveService());
  // Hive Web peut rester bloqué sur une base IndexedDB déjà ouverte dans
  // l’aperçu Replit. Le stockage offline reste actif sur Android/iOS ; le Web
  // peut démarrer sans lui et utilisera l’API distante pour les écrans métier.
  if (!kIsWeb) {
    await getIt<HiveService>().init();
  }

  getIt.registerSingleton<ApiClient>(ApiClient());

  // ── Auth ───────────────────────────────────────────────────────────────────
  getIt.registerFactory<AuthRemoteDatasource>(
      () => AuthRemoteDatasource(getIt<ApiClient>()));
  getIt.registerFactory<AuthRepository>(
      () => AuthRepositoryImpl(getIt<AuthRemoteDatasource>()));
  getIt.registerFactory<LoginUsecase>(
      () => LoginUsecase(getIt<AuthRepository>()));
  getIt.registerFactory<RegisterUsecase>(
      () => RegisterUsecase(getIt<AuthRepository>()));
  getIt.registerFactory<AuthBloc>(() => AuthBloc(
        loginUseCase: getIt<LoginUsecase>(),
        registerUseCase: getIt<RegisterUsecase>(),
        authRepository: getIt<AuthRepository>(),
      ));

  // ── Orders ─────────────────────────────────────────────────────────────────
  getIt.registerFactory<OrdersRemoteDatasource>(
      () => OrdersRemoteDatasource(getIt<ApiClient>()));
  getIt.registerFactory<OrdersRepository>(
      () => OrdersRepositoryImpl(getIt<OrdersRemoteDatasource>()));
  getIt.registerFactory<GetOrdersUsecase>(
      () => GetOrdersUsecase(getIt<OrdersRepository>()));
  getIt.registerFactory<CreateOrderUsecase>(
      () => CreateOrderUsecase(getIt<OrdersRepository>()));
  getIt.registerFactory<UpdateOrderStatusUsecase>(
      () => UpdateOrderStatusUsecase(getIt<OrdersRepository>()));
  getIt.registerFactory<OrdersBloc>(() => OrdersBloc(
        getOrders: getIt<GetOrdersUsecase>(),
        createOrder: getIt<CreateOrderUsecase>(),
        updateStatus: getIt<UpdateOrderStatusUsecase>(),
        repository: getIt<OrdersRepository>(),
      ));

  // ── Clients ────────────────────────────────────────────────────────────────
  getIt.registerFactory<ClientsRemoteDatasource>(
      () => ClientsRemoteDatasource(getIt<ApiClient>()));
  getIt.registerFactory<ClientsRepository>(
      () => ClientsRepositoryImpl(getIt<ClientsRemoteDatasource>()));
  getIt.registerFactory<GetClientsUsecase>(
      () => GetClientsUsecase(getIt<ClientsRepository>()));
  getIt.registerFactory<SaveMeasurementsUsecase>(
      () => SaveMeasurementsUsecase(getIt<ClientsRepository>()));
  getIt.registerFactory<ClientsBloc>(() => ClientsBloc(
        getClients: getIt<GetClientsUsecase>(),
        saveMeasurements: getIt<SaveMeasurementsUsecase>(),
        repository: getIt<ClientsRepository>(),
      ));

  // ── Stock ──────────────────────────────────────────────────────────────────
  getIt.registerFactory<StockRemoteDatasource>(
      () => StockRemoteDatasource(getIt<ApiClient>()));
  getIt.registerFactory<StockRepository>(
      () => StockRepositoryImpl(getIt<StockRemoteDatasource>()));
  getIt.registerFactory<GetStockUsecase>(
      () => GetStockUsecase(getIt<StockRepository>()));
  getIt.registerFactory<AdjustStockUsecase>(
      () => AdjustStockUsecase(getIt<StockRepository>()));
  getIt.registerFactory<StockBloc>(() => StockBloc(
        getStock: getIt<GetStockUsecase>(),
        adjustStock: getIt<AdjustStockUsecase>(),
        repository: getIt<StockRepository>(),
      ));

  // ── Finance ────────────────────────────────────────────────────────────────
  getIt.registerFactory<FinanceRemoteDatasource>(
      () => FinanceRemoteDatasource(getIt<ApiClient>()));
  getIt.registerFactory<FinanceRepository>(
      () => FinanceRepositoryImpl(getIt<FinanceRemoteDatasource>()));
  getIt.registerFactory<GetTreasuryUsecase>(
      () => GetTreasuryUsecase(getIt<FinanceRepository>()));
  getIt.registerFactory<CreateTransactionUsecase>(
      () => CreateTransactionUsecase(getIt<FinanceRepository>()));
  getIt.registerFactory<FinanceBloc>(() => FinanceBloc(
        getTreasury: getIt<GetTreasuryUsecase>(),
        createTransaction: getIt<CreateTransactionUsecase>(),
        repository: getIt<FinanceRepository>(),
      ));

  // ── Marketplace ────────────────────────────────────────────────────────────
  getIt.registerFactory<MarketplaceRemoteDatasource>(
      () => MarketplaceRemoteDatasource(getIt<ApiClient>()));
  getIt.registerFactory<MarketplaceRepository>(
      () => MarketplaceRepositoryImpl(getIt<MarketplaceRemoteDatasource>()));
  getIt.registerFactory<GetProductsUsecase>(
      () => GetProductsUsecase(getIt<MarketplaceRepository>()));
  getIt.registerFactory<PlaceOrderUsecase>(
      () => PlaceOrderUsecase(getIt<MarketplaceRepository>()));
  getIt.registerFactory<MarketplaceBloc>(() => MarketplaceBloc(
        getProducts: getIt<GetProductsUsecase>(),
        placeOrder: getIt<PlaceOrderUsecase>(),
        repository: getIt<MarketplaceRepository>(),
      ));

  // ── Notifications ──────────────────────────────────────────────────────────
  getIt.registerFactory<NotificationsRemoteDatasource>(
      () => NotificationsRemoteDatasource(getIt<ApiClient>()));
  getIt.registerFactory<NotificationsRepository>(
      () => NotificationsRepositoryImpl(getIt<NotificationsRemoteDatasource>()));
  getIt.registerFactory<GetNotificationsUsecase>(
      () => GetNotificationsUsecase(getIt<NotificationsRepository>()));
  getIt.registerFactory<NotificationsBloc>(() => NotificationsBloc(
        getNotifications: getIt<GetNotificationsUsecase>(),
        repository: getIt<NotificationsRepository>(),
      ));

  // ── Profile ────────────────────────────────────────────────────────────────
  getIt.registerFactory<ProfileRemoteDatasource>(
      () => ProfileRemoteDatasource(getIt<ApiClient>()));
  getIt.registerFactory<ProfileRepository>(
      () => ProfileRepositoryImpl(getIt<ProfileRemoteDatasource>()));
  getIt.registerFactory<ProfileBloc>(
      () => ProfileBloc(repository: getIt<ProfileRepository>()));
}
