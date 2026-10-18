import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/repositories/notifications_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────
abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override
  List<Object?> get props => [];
}

class NotificationsLoadRequested extends NotificationsEvent {}

class NotificationMarkReadRequested extends NotificationsEvent {
  final String id;
  const NotificationMarkReadRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class NotificationsMarkAllReadRequested extends NotificationsEvent {}

class NotificationDeleteRequested extends NotificationsEvent {
  final String id;
  const NotificationDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class ReminderConfigLoadRequested extends NotificationsEvent {}

class ReminderConfigUpdateRequested extends NotificationsEvent {
  final Map<String, dynamic> data;
  const ReminderConfigUpdateRequested(this.data);
  @override
  List<Object?> get props => [data];
}

// ── States ───────────────────────────────────────────────────────────────────
abstract class NotificationsState extends Equatable {
  const NotificationsState();
  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}
class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationEntity> notifications;
  int get unreadCount => notifications.where((n) => !n.isRead).length;
  const NotificationsLoaded(this.notifications);
  @override
  List<Object?> get props => [notifications];
}

class ReminderConfigLoaded extends NotificationsState {
  final ReminderConfigEntity config;
  const ReminderConfigLoaded(this.config);
  @override
  List<Object?> get props => [config];
}

class NotificationsError extends NotificationsState {
  final String message;
  const NotificationsError(this.message);
  @override
  List<Object?> get props => [message];
}

class NotificationsActionSuccess extends NotificationsState {
  final String message;
  const NotificationsActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final GetNotificationsUsecase _getNotifications;
  final NotificationsRepository _repository;

  NotificationsBloc({
    required GetNotificationsUsecase getNotifications,
    required NotificationsRepository repository,
  })  : _getNotifications = getNotifications,
        _repository = repository,
        super(NotificationsInitial()) {
    on<NotificationsLoadRequested>(_onLoad);
    on<NotificationMarkReadRequested>(_onMarkRead);
    on<NotificationsMarkAllReadRequested>(_onMarkAllRead);
    on<NotificationDeleteRequested>(_onDelete);
    on<ReminderConfigLoadRequested>(_onLoadConfig);
    on<ReminderConfigUpdateRequested>(_onUpdateConfig);
  }

  Future<void> _onLoad(
      NotificationsLoadRequested event, Emitter<NotificationsState> emit) async {
    emit(NotificationsLoading());
    final result = await _getNotifications();
    result.fold(
      (error) => emit(NotificationsError(error)),
      (notifs) => emit(NotificationsLoaded(notifs)),
    );
  }

  Future<void> _onMarkRead(NotificationMarkReadRequested event,
      Emitter<NotificationsState> emit) async {
    await _repository.markAsRead(event.id);
    add(NotificationsLoadRequested());
  }

  Future<void> _onMarkAllRead(NotificationsMarkAllReadRequested event,
      Emitter<NotificationsState> emit) async {
    await _repository.markAllAsRead();
    add(NotificationsLoadRequested());
  }

  Future<void> _onDelete(NotificationDeleteRequested event,
      Emitter<NotificationsState> emit) async {
    await _repository.deleteNotification(event.id);
    add(NotificationsLoadRequested());
  }

  Future<void> _onLoadConfig(
      ReminderConfigLoadRequested event, Emitter<NotificationsState> emit) async {
    emit(NotificationsLoading());
    final result = await _repository.getReminderConfig();
    result.fold(
      (error) => emit(NotificationsError(error)),
      (config) => emit(ReminderConfigLoaded(config)),
    );
  }

  Future<void> _onUpdateConfig(ReminderConfigUpdateRequested event,
      Emitter<NotificationsState> emit) async {
    final result = await _repository.updateReminderConfig(event.data);
    result.fold(
      (error) => emit(NotificationsError(error)),
      (config) {
        emit(const NotificationsActionSuccess('Configuration sauvegardée'));
        emit(ReminderConfigLoaded(config));
      },
    );
  }
}
