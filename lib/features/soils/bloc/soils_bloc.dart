import 'package:bloc/bloc.dart';

sealed class SoilsEvent {
  const SoilsEvent();

  const factory SoilsEvent.typeChanged(String value) = SoilsTypeChanged;

  const factory SoilsEvent.moistureChanged(String value) = SoilsMoistureChanged;

  const factory SoilsEvent.saved() = SoilsSaved;
}

final class SoilsTypeChanged extends SoilsEvent {
  const SoilsTypeChanged(this.value);

  final String value;
}

final class SoilsMoistureChanged extends SoilsEvent {
  const SoilsMoistureChanged(this.value);

  final String value;
}

final class SoilsSaved extends SoilsEvent {
  const SoilsSaved();
}

enum SoilsStatus { idle, loading, success, failure }

final class SoilsState {
  const SoilsState({
    this.type,
    this.moisture,
    this.status = SoilsStatus.idle,
    this.message,
  });

  final String? type;
  final String? moisture;
  final SoilsStatus status;
  final String? message;

  SoilsState copyWith({
    String? type,
    String? moisture,
    SoilsStatus? status,
    String? message,
  }) {
    return SoilsState(
      type: type ?? this.type,
      moisture: moisture ?? this.moisture,
      status: status ?? this.status,
      message: message,
    );
  }
}

final class SoilsBloc extends Bloc<SoilsEvent, SoilsState> {
  SoilsBloc() : super(const SoilsState()) {
    on<SoilsTypeChanged>(_onTypeChanged);
    on<SoilsMoistureChanged>(_onMoistureChanged);
    on<SoilsSaved>(_onSaved);
  }

  void _onTypeChanged(SoilsTypeChanged event, Emitter<SoilsState> emit) {
    emit(state.copyWith(type: event.value, status: SoilsStatus.idle));
  }

  void _onMoistureChanged(
    SoilsMoistureChanged event,
    Emitter<SoilsState> emit,
  ) {
    emit(state.copyWith(moisture: event.value, status: SoilsStatus.idle));
  }

  Future<void> _onSaved(SoilsSaved event, Emitter<SoilsState> emit) async {
    emit(state.copyWith(status: SoilsStatus.loading));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    emit(state.copyWith(status: SoilsStatus.success));
  }
}
