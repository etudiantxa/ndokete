import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {}

class ProfileUpdateRequested extends ProfileEvent {
  final Map<String, dynamic> data;
  const ProfileUpdateRequested(this.data);
  @override
  List<Object?> get props => [data];
}

class ProfileAvatarUploadRequested extends ProfileEvent {
  final String filePath;
  const ProfileAvatarUploadRequested(this.filePath);
  @override
  List<Object?> get props => [filePath];
}

class ProfilePasswordChangeRequested extends ProfileEvent {
  final String current;
  final String newPassword;
  const ProfilePasswordChangeRequested(this.current, this.newPassword);
  @override
  List<Object?> get props => [current, newPassword];
}

// ── States ───────────────────────────────────────────────────────────────────
abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final ProfileEntity profile;
  const ProfileLoaded(this.profile);
  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
  @override
  List<Object?> get props => [message];
}

class ProfileActionSuccess extends ProfileState {
  final String message;
  const ProfileActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _repository;

  ProfileBloc({required ProfileRepository repository})
      : _repository = repository,
        super(ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoad);
    on<ProfileUpdateRequested>(_onUpdate);
    on<ProfileAvatarUploadRequested>(_onAvatarUpload);
    on<ProfilePasswordChangeRequested>(_onPasswordChange);
  }

  Future<void> _onLoad(
      ProfileLoadRequested event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    final result = await _repository.getProfile();
    result.fold(
      (error) => emit(ProfileError(error)),
      (profile) => emit(ProfileLoaded(profile)),
    );
  }

  Future<void> _onUpdate(
      ProfileUpdateRequested event, Emitter<ProfileState> emit) async {
    final result = await _repository.updateProfile(event.data);
    result.fold(
      (error) => emit(ProfileError(error)),
      (profile) {
        emit(const ProfileActionSuccess('Profil mis à jour'));
        emit(ProfileLoaded(profile));
      },
    );
  }

  Future<void> _onAvatarUpload(
      ProfileAvatarUploadRequested event, Emitter<ProfileState> emit) async {
    final result = await _repository.uploadAvatar(event.filePath);
    result.fold(
      (error) => emit(ProfileError(error)),
      (_) {
        emit(const ProfileActionSuccess('Photo de profil mise à jour'));
        add(ProfileLoadRequested());
      },
    );
  }

  Future<void> _onPasswordChange(
      ProfilePasswordChangeRequested event, Emitter<ProfileState> emit) async {
    final loadedProfile =
        state is ProfileLoaded ? (state as ProfileLoaded).profile : null;
    final result =
        await _repository.changePassword(event.current, event.newPassword);
    result.fold(
      (error) => emit(ProfileError(error)),
      (_) {
        emit(const ProfileActionSuccess('Mot de passe modifié'));
        if (loadedProfile != null) emit(ProfileLoaded(loadedProfile));
      },
    );
  }
}
