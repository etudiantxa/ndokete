import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/usecases/get_treasury_usecase.dart';
import '../../domain/usecases/create_transaction_usecase.dart';
import '../../domain/repositories/finance_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────
abstract class FinanceEvent extends Equatable {
  const FinanceEvent();
  @override
  List<Object?> get props => [];
}

class FinanceLoadRequested extends FinanceEvent {
  final String? period;
  const FinanceLoadRequested({this.period});
  @override
  List<Object?> get props => [period];
}

class TransactionCreateRequested extends FinanceEvent {
  final Map<String, dynamic> data;
  const TransactionCreateRequested(this.data);
  @override
  List<Object?> get props => [data];
}

class TransactionDeleteRequested extends FinanceEvent {
  final String id;
  const TransactionDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class ReportGenerateRequested extends FinanceEvent {
  final String startDate;
  final String endDate;
  const ReportGenerateRequested(this.startDate, this.endDate);
  @override
  List<Object?> get props => [startDate, endDate];
}

// ── States ───────────────────────────────────────────────────────────────────
abstract class FinanceState extends Equatable {
  const FinanceState();
  @override
  List<Object?> get props => [];
}

class FinanceInitial extends FinanceState {}
class FinanceLoading extends FinanceState {}

class FinanceLoaded extends FinanceState {
  final TreasurySummaryEntity summary;
  final List<TransactionEntity> transactions;
  const FinanceLoaded({required this.summary, required this.transactions});
  @override
  List<Object?> get props => [summary, transactions];
}

class FinanceReportLoaded extends FinanceState {
  final Map<String, dynamic> report;
  const FinanceReportLoaded(this.report);
  @override
  List<Object?> get props => [report];
}

class FinanceError extends FinanceState {
  final String message;
  const FinanceError(this.message);
  @override
  List<Object?> get props => [message];
}

class FinanceActionSuccess extends FinanceState {
  final String message;
  const FinanceActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────
class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final GetTreasuryUsecase _getTreasury;
  final CreateTransactionUsecase _createTransaction;
  final FinanceRepository _repository;

  FinanceBloc({
    required GetTreasuryUsecase getTreasury,
    required CreateTransactionUsecase createTransaction,
    required FinanceRepository repository,
  })  : _getTreasury = getTreasury,
        _createTransaction = createTransaction,
        _repository = repository,
        super(FinanceInitial()) {
    on<FinanceLoadRequested>(_onLoad);
    on<TransactionCreateRequested>(_onCreate);
    on<TransactionDeleteRequested>(_onDelete);
    on<ReportGenerateRequested>(_onReport);
  }

  Future<void> _onLoad(FinanceLoadRequested event, Emitter<FinanceState> emit) async {
    emit(FinanceLoading());
    final summaryResult = await _getTreasury(period: event.period);
    final txResult = await _repository.getTransactions(period: event.period);
    summaryResult.fold(
      (error) => emit(FinanceError(error)),
      (summary) => txResult.fold(
        (_) => emit(FinanceLoaded(summary: summary, transactions: const [])),
        (txs) => emit(FinanceLoaded(summary: summary, transactions: txs)),
      ),
    );
  }

  Future<void> _onCreate(
      TransactionCreateRequested event, Emitter<FinanceState> emit) async {
    final result = await _createTransaction(event.data);
    result.fold(
      (error) => emit(FinanceError(error)),
      (_) {
        emit(const FinanceActionSuccess('Transaction enregistrée'));
        add(const FinanceLoadRequested());
      },
    );
  }

  Future<void> _onDelete(
      TransactionDeleteRequested event, Emitter<FinanceState> emit) async {
    final result = await _repository.deleteTransaction(event.id);
    result.fold(
      (error) => emit(FinanceError(error)),
      (_) {
        emit(const FinanceActionSuccess('Transaction supprimée'));
        add(const FinanceLoadRequested());
      },
    );
  }

  Future<void> _onReport(
      ReportGenerateRequested event, Emitter<FinanceState> emit) async {
    emit(FinanceLoading());
    final result =
        await _repository.generateReport(event.startDate, event.endDate);
    result.fold(
      (error) => emit(FinanceError(error)),
      (report) => emit(FinanceReportLoaded(report)),
    );
  }
}
