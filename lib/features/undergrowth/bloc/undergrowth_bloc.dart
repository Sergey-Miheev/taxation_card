import 'package:bloc/bloc.dart';

sealed class UndergrowthEvent {
  const UndergrowthEvent();

  const factory UndergrowthEvent.speciesChanged(String value) =
      UndergrowthSpeciesChanged;

  const factory UndergrowthEvent.quantityChanged(String value) =
      UndergrowthQuantityChanged;

  const factory UndergrowthEvent.heightChanged(String value) =
      UndergrowthHeightChanged;

  const factory UndergrowthEvent.saved() = UndergrowthSaved;
}

final class UndergrowthSpeciesChanged extends UndergrowthEvent {
  const UndergrowthSpeciesChanged(this.value);

  final String value;
}

final class UndergrowthQuantityChanged extends UndergrowthEvent {
  const UndergrowthQuantityChanged(this.value);

  final String value;
}

final class UndergrowthHeightChanged extends UndergrowthEvent {
  const UndergrowthHeightChanged(this.value);

  final String value;
}

final class UndergrowthSaved extends UndergrowthEvent {
  const UndergrowthSaved();
}

enum UndergrowthStatus { idle, loading, success, failure }

final class UndergrowthState {
  const UndergrowthState({
    this.species = '',
    this.quantity = 0,
    this.height = 0,
    this.status = UndergrowthStatus.idle,
    this.message,
  });

  final String species;
  final int quantity;
  final double height;
  final UndergrowthStatus status;
  final String? message;

  UndergrowthState copyWith({
    String? species,
    int? quantity,
    double? height,
    UndergrowthStatus? status,
    String? message,
  }) {
    return UndergrowthState(
      species: species ?? this.species,
      quantity: quantity ?? this.quantity,
      height: height ?? this.height,
      status: status ?? this.status,
      message: message,
    );
  }
}

final class UndergrowthBloc extends Bloc<UndergrowthEvent, UndergrowthState> {
  UndergrowthBloc() : super(const UndergrowthState()) {
    on<UndergrowthSpeciesChanged>(_onSpeciesChanged);
    on<UndergrowthQuantityChanged>(_onQuantityChanged);
    on<UndergrowthHeightChanged>(_onHeightChanged);
    on<UndergrowthSaved>(_onSaved);
  }

  void _onSpeciesChanged(
    UndergrowthSpeciesChanged event,
    Emitter<UndergrowthState> emit,
  ) {
    emit(state.copyWith(species: event.value, status: UndergrowthStatus.idle));
  }

  void _onQuantityChanged(
    UndergrowthQuantityChanged event,
    Emitter<UndergrowthState> emit,
  ) {
    emit(
      state.copyWith(
        quantity: int.tryParse(event.value) ?? 0,
        status: UndergrowthStatus.idle,
      ),
    );
  }

  void _onHeightChanged(
    UndergrowthHeightChanged event,
    Emitter<UndergrowthState> emit,
  ) {
    emit(
      state.copyWith(
        height: double.tryParse(event.value.replaceAll(',', '.')) ?? 0,
        status: UndergrowthStatus.idle,
      ),
    );
  }

  Future<void> _onSaved(
    UndergrowthSaved event,
    Emitter<UndergrowthState> emit,
  ) async {
    emit(state.copyWith(status: UndergrowthStatus.loading));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    emit(state.copyWith(status: UndergrowthStatus.success));
  }
}
