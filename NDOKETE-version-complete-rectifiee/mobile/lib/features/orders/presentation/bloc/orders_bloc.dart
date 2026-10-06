import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/usecases/get_orders_usecase.dart';
import '../../domain/usecases/create_order_usecase.dart';
import '../../domain/usecases/update_order_status_usecase.dart';
import '../../domain/repositories/orders_repository.dart';

// ── Events ──────────────────────────────────────────────────────────────────
abstract class OrdersEvent extends Equatable {
  const OrdersEvent();
  @override
  List<Object?> get props => [];
}

class OrdersLoadRequested extends OrdersEvent {
  final String? status;
  const OrdersLoadRequested({this.status});
  @override
  List<Object?> get props => [status];
}

class OrderCreateRequested extends OrdersEvent {
  final Map<String, dynamic> data;
  const OrderCreateRequested(this.data);
  @override
  List<Object?> get props => [data];
}

class OrderStatusUpdateRequested extends OrdersEvent {
  final String id;
  final OrderStatus status;
  const OrderStatusUpdateRequested(this.id, this.status);
  @override
  List<Object?> get props => [id, status];
}

class OrderDeleteRequested extends OrdersEvent {
  final String id;
  const OrderDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class OrderReminderSentAll extends OrdersEvent {
  const OrderReminderSentAll();
}

// ── States ───────────────────────────────────────────────────────────────────
abstract class OrdersState extends Equatable {
  const OrdersState();
  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}
class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<OrderEntity> orders;
  final List<OrderEntity> urgentOrders;
  const OrdersLoaded({required this.orders, this.urgentOrders = const []});
  @override
  List<Object?> get props => [orders, urgentOrders];
}

class OrdersError extends OrdersState {
  final String message;
  const OrdersError(this.message);
  @override
  List<Object?> get props => [message];
}

class OrderActionSuccess extends OrdersState {
  final String message;
  const OrderActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final GetOrdersUsecase _getOrders;
  final CreateOrderUsecase _createOrder;
  final UpdateOrderStatusUsecase _updateStatus;
  final OrdersRepository _repository;

  OrdersBloc({
    required GetOrdersUsecase getOrders,
    required CreateOrderUsecase createOrder,
    required UpdateOrderStatusUsecase updateStatus,
    required OrdersRepository repository,
  })  : _getOrders = getOrders,
        _createOrder = createOrder,
        _updateStatus = updateStatus,
        _repository = repository,
        super(OrdersInitial()) {
    on<OrdersLoadRequested>(_onLoad);
    on<OrderCreateRequested>(_onCreate);
    on<OrderStatusUpdateRequested>(_onStatusUpdate);
    on<OrderDeleteRequested>(_onDelete);
    on<OrderReminderSentAll>(_onBulkReminder);
  }

  Future<void> _onLoad(OrdersLoadRequested event, Emitter<OrdersState> emit) async {
    emit(OrdersLoading());
    final result = await _getOrders(status: event.status);
    final urgentResult = await _repository.getUrgentOrders();
    result.fold(
      (error) => emit(OrdersError(error)),
      (orders) => urgentResult.fold(
        (_) => emit(OrdersLoaded(orders: orders)),
        (urgent) => emit(OrdersLoaded(orders: orders, urgentOrders: urgent)),
      ),
    );
  }

  Future<void> _onCreate(OrderCreateRequested event, Emitter<OrdersState> emit) async {
    final result = await _createOrder(event.data);
    result.fold(
      (error) => emit(OrdersError(error)),
      (_) => emit(const OrderActionSuccess('Commande créée avec succès')),
    );
  }

  Future<void> _onStatusUpdate(
      OrderStatusUpdateRequested event, Emitter<OrdersState> emit) async {
    final result = await _updateStatus(event.id, event.status);
    result.fold(
      (error) => emit(OrdersError(error)),
      (_) {
        emit(const OrderActionSuccess('Statut mis à jour'));
        add(const OrdersLoadRequested());
      },
    );
  }

  Future<void> _onDelete(OrderDeleteRequested event, Emitter<OrdersState> emit) async {
    final result = await _repository.deleteOrder(event.id);
    result.fold(
      (error) => emit(OrdersError(error)),
      (_) {
        emit(const OrderActionSuccess('Commande supprimée'));
        add(const OrdersLoadRequested());
      },
    );
  }

  Future<void> _onBulkReminder(
      OrderReminderSentAll event, Emitter<OrdersState> emit) async {
    final result = await _repository.sendBulkReminders();
    result.fold(
      (error) => emit(OrdersError(error)),
      (_) => emit(const OrderActionSuccess('Rappels envoyés')),
    );
  }
}
