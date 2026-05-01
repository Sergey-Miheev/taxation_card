import 'package:bloc/bloc.dart';

sealed class DeadwoodEvent {
  const DeadwoodEvent();

  const factory DeadwoodEvent.volumeChanged(String value) =
      DeadwoodVolumeChanged;

  const factory DeadwoodEvent.decayClassChanged(String value) =
      DeadwoodDecayClassChanged;

  const factory DeadwoodEvent.saved() = DeadwoodSaved;
}

final class DeadwoodVolumeChanged extends DeadwoodEvent {
  const DeadwoodVolumeChanged(this.value);

  final String value;
}

final class DeadwoodDecayClassChanged extends DeadwoodEvent {
  const DeadwoodDecayClassChanged(this.value);

  final String value;
}

final class DeadwoodSaved extends DeadwoodEvent {
  const DeadwoodSaved();
}

enum DeadwoodStatus { idle, loading, success, failure }

final class DeadwoodState {
  const DeadwoodState({
    this.volume = 0,
    this.decayClass,
    this.status = DeadwoodStatus.idle,
    this.message,
  });

  final double volume;
  final String? decayClass;
  final DeadwoodStatus status;
  final String? message;

  DeadwoodState copyWith({
    double? volume,
    String? decayClass,
    DeadwoodStatus? status,
    String? message,
  }) {
    return DeadwoodState(
      volume: volume ?? this.volume,
      decayClass: decayClass ?? this.decayClass,
      status: status ?? this.status,
      message: message,
    );
  }
}

final class DeadwoodBloc extends Bloc<DeadwoodEvent, DeadwoodState> {
  DeadwoodBloc() : super(const DeadwoodState()) {
    on<DeadwoodVolumeChanged>(_onVolumeChanged);
    on<DeadwoodDecayClassChanged>(_onDecayClassChanged);
    on<DeadwoodSaved>(_onSaved);
  }

  void _onVolumeChanged(
    DeadwoodVolumeChanged event,
    Emitter<DeadwoodState> emit,
  ) {
    emit(
      state.copyWith(
        volume: double.tryParse(event.value.replaceAll(',', '.')) ?? 0,
        status: DeadwoodStatus.idle,
      ),
    );
  }

  void _onDecayClassChanged(
    DeadwoodDecayClassChanged event,
    Emitter<DeadwoodState> emit,
  ) {
    emit(state.copyWith(decayClass: event.value, status: DeadwoodStatus.idle));
  }

  Future<void> _onSaved(
    DeadwoodSaved event,
    Emitter<DeadwoodState> emit,
  ) async {
    emit(state.copyWith(status: DeadwoodStatus.loading));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    emit(state.copyWith(status: DeadwoodStatus.success));
  }
}
