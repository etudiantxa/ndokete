import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/stock_entity.dart';
import '../../domain/usecases/get_stock_usecase.dart';
import '../../domain/usecases/adjust_stock_usecase.dart';
import '../../domain/repositories/stock_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────
abstract class StockEvent extends Equatable {
  const StockEvent();
  @override
  List<Object?> get props => [];
}

class StockLoadRequested extends StockEvent {
  final String? category;
  const StockLoadRequested({this.category});
  @override
  List<Object?> get props => [category];
}

class StockItemDetailRequested extends StockEvent {
  final String id;
  const StockItemDetailRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class StockItemCreateRequested extends StockEvent {
  final Map<String, dynamic> data;
  const StockItemCreateRequested(this.data);
  @override
  List<Object?> get props => [data];
}

class StockAdjustRequested extends StockEvent {
  final String id;
  final double quantity;
  final String type;
  final String? reason;
  const StockAdjustRequested(this.id, this.quantity, this.type, {this.reason});
  @override
  List<Object?> get props => [id, quantity, type];
}

class StockDeleteRequested extends StockEvent {
  final String id;
  const StockDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

// ── States ───────────────────────────────────────────────────────────────────
abstract class StockState extends Equatable {
  const StockState();
  @override
  List<Object?> get props => [];
}

class StockInitial extends StockState {}
class StockLoading extends StockState {}

class StockLoaded extends StockState {
  final List<StockItemEntity> items;
  final List<StockItemEntity> lowStockItems;
  const StockLoaded({required this.items, this.lowStockItems = const []});
  @override
  List<Object?> get props => [items, lowStockItems];
}

class StockItemDetailLoaded extends StockState {
  final StockItemEntity item;
  const StockItemDetailLoaded(this.item);
  @override
  List<Object?> get props => [item];
}

class StockError extends StockState {
  final String message;
  const StockError(this.message);
  @override
  List<Object?> get props => [message];
}

class StockActionSuccess extends StockState {
  final String message;
  const StockActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────
class StockBloc extends Bloc<StockEvent, StockState> {
  final GetStockUsecase _getStock;
  final AdjustStockUsecase _adjustStock;
  final StockRepository _repository;

  StockBloc({
    required GetStockUsecase getStock,
    required AdjustStockUsecase adjustStock,
    required StockRepository repository,
  })  : _getStock = getStock,
        _adjustStock = adjustStock,
        _repository = repository,
        super(StockInitial()) {
    on<StockLoadRequested>(_onLoad);
    on<StockItemDetailRequested>(_onDetail);
    on<StockItemCreateRequested>(_onCreate);
    on<StockAdjustRequested>(_onAdjust);
    on<StockDeleteRequested>(_onDelete);
  }

  Future<void> _onLoad(StockLoadRequested event, Emitter<StockState> emit) async {
    emit(StockLoading());
    final [itemsResult, lowResult] = await Future.wait([
      _getStock(category: event.category),
      _repository.getLowStockItems(),
    ]);
    itemsResult.fold(
      (error) => emit(StockError(error)),
      (items) => lowResult.fold(
        (_) => emit(StockLoaded(items: items)),
        (low) => emit(StockLoaded(items: items, lowStockItems: low)),
      ),
    );
  }

  Future<void> _onDetail(StockItemDetailRequested event, Emitter<StockState> emit) async {
    emit(StockLoading());
    final result = await _repository.getStockItemById(event.id);
    result.fold(
      (error) => emit(StockError(error)),
      (item) => emit(StockItemDetailLoaded(item)),
    );
  }

  Future<void> _onCreate(StockItemCreateRequested event, Emitter<StockState> emit) async {
    final result = await _repository.createStockItem(event.data);
    result.fold(
      (error) => emit(StockError(error)),
      (_) {
        emit(const StockActionSuccess('Article ajouté au stock'));
        add(const StockLoadRequested());
      },
    );
  }

  Future<void> _onAdjust(StockAdjustRequested event, Emitter<StockState> emit) async {
    final result =
        await _adjustStock(event.id, event.quantity, event.type, event.reason);
    result.fold(
      (error) => emit(StockError(error)),
      (_) {
        emit(const StockActionSuccess('Stock ajusté'));
        add(const StockLoadRequested());
      },
    );
  }

  Future<void> _onDelete(StockDeleteRequested event, Emitter<StockState> emit) async {
    final result = await _repository.deleteStockItem(event.id);
    result.fold(
      (error) => emit(StockError(error)),
      (_) {
        emit(const StockActionSuccess('Article supprimé'));
        add(const StockLoadRequested());
      },
    );
  }
}
