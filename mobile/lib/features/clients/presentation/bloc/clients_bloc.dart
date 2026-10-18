import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/usecases/get_clients_usecase.dart';
import '../../domain/usecases/save_measurements_usecase.dart';
import '../../domain/repositories/clients_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────
abstract class ClientsEvent extends Equatable {
  const ClientsEvent();
  @override
  List<Object?> get props => [];
}

class ClientsLoadRequested extends ClientsEvent {
  final String? search;
  const ClientsLoadRequested({this.search});
  @override
  List<Object?> get props => [search];
}

class ClientDetailRequested extends ClientsEvent {
  final String id;
  const ClientDetailRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class ClientCreateRequested extends ClientsEvent {
  final Map<String, dynamic> data;
  const ClientCreateRequested(this.data);
  @override
  List<Object?> get props => [data];
}

class ClientUpdateRequested extends ClientsEvent {
  final String id;
  final Map<String, dynamic> data;
  const ClientUpdateRequested(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class ClientDeleteRequested extends ClientsEvent {
  final String id;
  const ClientDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class MeasurementsSaveRequested extends ClientsEvent {
  final String clientId;
  final Map<String, dynamic> data;
  const MeasurementsSaveRequested(this.clientId, this.data);
  @override
  List<Object?> get props => [clientId, data];
}

// ── States ───────────────────────────────────────────────────────────────────
abstract class ClientsState extends Equatable {
  const ClientsState();
  @override
  List<Object?> get props => [];
}

class ClientsInitial extends ClientsState {}
class ClientsLoading extends ClientsState {}

class ClientsLoaded extends ClientsState {
  final List<ClientEntity> clients;
  const ClientsLoaded(this.clients);
  @override
  List<Object?> get props => [clients];
}

class ClientDetailLoaded extends ClientsState {
  final ClientEntity client;
  const ClientDetailLoaded(this.client);
  @override
  List<Object?> get props => [client];
}

class ClientsError extends ClientsState {
  final String message;
  const ClientsError(this.message);
  @override
  List<Object?> get props => [message];
}

class ClientActionSuccess extends ClientsState {
  final String message;
  const ClientActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────
class ClientsBloc extends Bloc<ClientsEvent, ClientsState> {
  final GetClientsUsecase _getClients;
  final SaveMeasurementsUsecase _saveMeasurements;
  final ClientsRepository _repository;

  ClientsBloc({
    required GetClientsUsecase getClients,
    required SaveMeasurementsUsecase saveMeasurements,
    required ClientsRepository repository,
  })  : _getClients = getClients,
        _saveMeasurements = saveMeasurements,
        _repository = repository,
        super(ClientsInitial()) {
    on<ClientsLoadRequested>(_onLoad);
    on<ClientDetailRequested>(_onDetail);
    on<ClientCreateRequested>(_onCreate);
    on<ClientUpdateRequested>(_onUpdate);
    on<ClientDeleteRequested>(_onDelete);
    on<MeasurementsSaveRequested>(_onSaveMeasurements);
  }

  Future<void> _onLoad(ClientsLoadRequested event, Emitter<ClientsState> emit) async {
    emit(ClientsLoading());
    final result = await _getClients(search: event.search);
    result.fold(
      (error) => emit(ClientsError(error)),
      (clients) => emit(ClientsLoaded(clients)),
    );
  }

  Future<void> _onDetail(ClientDetailRequested event, Emitter<ClientsState> emit) async {
    emit(ClientsLoading());
    final result = await _repository.getClientById(event.id);
    result.fold(
      (error) => emit(ClientsError(error)),
      (client) => emit(ClientDetailLoaded(client)),
    );
  }

  Future<void> _onCreate(ClientCreateRequested event, Emitter<ClientsState> emit) async {
    final result = await _repository.createClient(event.data);
    result.fold(
      (error) => emit(ClientsError(error)),
      (_) {
        emit(const ClientActionSuccess('Client ajouté'));
        add(const ClientsLoadRequested());
      },
    );
  }

  Future<void> _onUpdate(ClientUpdateRequested event, Emitter<ClientsState> emit) async {
    final result = await _repository.updateClient(event.id, event.data);
    result.fold(
      (error) => emit(ClientsError(error)),
      (_) => emit(const ClientActionSuccess('Client mis à jour')),
    );
  }

  Future<void> _onDelete(ClientDeleteRequested event, Emitter<ClientsState> emit) async {
    final result = await _repository.deleteClient(event.id);
    result.fold(
      (error) => emit(ClientsError(error)),
      (_) {
        emit(const ClientActionSuccess('Client supprimé'));
        add(const ClientsLoadRequested());
      },
    );
  }

  Future<void> _onSaveMeasurements(
      MeasurementsSaveRequested event, Emitter<ClientsState> emit) async {
    final result = await _saveMeasurements(event.clientId, event.data);
    result.fold(
      (error) => emit(ClientsError(error)),
      (_) => emit(const ClientActionSuccess('Mesures sauvegardées')),
    );
  }
}
