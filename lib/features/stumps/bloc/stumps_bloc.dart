import 'package:bloc/bloc.dart';
import 'package:taxation_card/features/stumps/domain/stumps_repository.dart';

sealed class StumpsEvent {
  const StumpsEvent();

  const factory StumpsEvent.loaded(int probaInfoId) = StumpsLoaded;

  const factory StumpsEvent.speciesChanged(String? value) =
      StumpsSpeciesChanged;

  const factory StumpsEvent.stumpHeightChanged(String value) =
      StumpsStumpHeightChanged;

  const factory StumpsEvent.stumpHeightDiameterChanged({
    required int? diameter,
    required int? millimeter,
  }) = StumpsStumpHeightDiameterChanged;

  const factory StumpsEvent.rootCollarDiameterChanged({
    required int? diameter,
    required int? millimeter,
  }) = StumpsRootCollarDiameterChanged;

  const factory StumpsEvent.rotSizeChanged(String value) = StumpsRotSizeChanged;

  const factory StumpsEvent.rotLengthChanged(String value) =
      StumpsRotLengthChanged;

  const factory StumpsEvent.decayClassChanged(String value) =
      StumpsDecayClassChanged;

  const factory StumpsEvent.saved(StumpRecord record) = StumpsSaved;

  const factory StumpsEvent.deleted({
    required int id,
    required int probaInfoId,
  }) = StumpsDeleted;
}

final class StumpsLoaded extends StumpsEvent {
  const StumpsLoaded(this.probaInfoId);

  final int probaInfoId;
}

final class StumpsSpeciesChanged extends StumpsEvent {
  const StumpsSpeciesChanged(this.value);

  final String? value;
}

final class StumpsStumpHeightChanged extends StumpsEvent {
  const StumpsStumpHeightChanged(this.value);

  final String value;
}

final class StumpsStumpHeightDiameterChanged extends StumpsEvent {
  const StumpsStumpHeightDiameterChanged({
    required this.diameter,
    required this.millimeter,
  });

  final int? diameter;
  final int? millimeter;
}

final class StumpsRootCollarDiameterChanged extends StumpsEvent {
  const StumpsRootCollarDiameterChanged({
    required this.diameter,
    required this.millimeter,
  });

  final int? diameter;
  final int? millimeter;
}

final class StumpsRotSizeChanged extends StumpsEvent {
  const StumpsRotSizeChanged(this.value);

  final String value;
}

final class StumpsRotLengthChanged extends StumpsEvent {
  const StumpsRotLengthChanged(this.value);

  final String value;
}

final class StumpsDecayClassChanged extends StumpsEvent {
  const StumpsDecayClassChanged(this.value);

  final String value;
}

final class StumpsSaved extends StumpsEvent {
  const StumpsSaved(this.record);

  final StumpRecord record;
}

final class StumpsDeleted extends StumpsEvent {
  const StumpsDeleted({required this.id, required this.probaInfoId});

  final int id;
  final int probaInfoId;
}

enum StumpsStatus { idle, loading, success, failure }

final class StumpsState {
  const StumpsState({
    this.species,
    this.stumpHeight = 0,
    this.stumpHeightDiameter,
    this.stumpHeightMillimeter,
    this.rootCollarDiameter,
    this.rootCollarMillimeter,
    this.rotSize,
    this.rotLength,
    this.decayClass,
    this.records = const [],
    this.status = StumpsStatus.idle,
    this.message,
  });

  final String? species;
  final double stumpHeight;
  final int? stumpHeightDiameter;
  final int? stumpHeightMillimeter;
  final int? rootCollarDiameter;
  final int? rootCollarMillimeter;
  final double? rotSize;
  final double? rotLength;
  final String? decayClass;
  final List<StumpRecord> records;
  final StumpsStatus status;
  final String? message;

  StumpsState copyWith({
    Object? species = _sentinel,
    double? stumpHeight,
    Object? stumpHeightDiameter = _sentinel,
    Object? stumpHeightMillimeter = _sentinel,
    Object? rootCollarDiameter = _sentinel,
    Object? rootCollarMillimeter = _sentinel,
    Object? rotSize = _sentinel,
    Object? rotLength = _sentinel,
    String? decayClass,
    List<StumpRecord>? records,
    StumpsStatus? status,
    String? message,
  }) {
    return StumpsState(
      species: identical(species, _sentinel)
          ? this.species
          : species as String?,
      stumpHeight: stumpHeight ?? this.stumpHeight,
      stumpHeightDiameter: identical(stumpHeightDiameter, _sentinel)
          ? this.stumpHeightDiameter
          : stumpHeightDiameter as int?,
      stumpHeightMillimeter: identical(stumpHeightMillimeter, _sentinel)
          ? this.stumpHeightMillimeter
          : stumpHeightMillimeter as int?,
      rootCollarDiameter: identical(rootCollarDiameter, _sentinel)
          ? this.rootCollarDiameter
          : rootCollarDiameter as int?,
      rootCollarMillimeter: identical(rootCollarMillimeter, _sentinel)
          ? this.rootCollarMillimeter
          : rootCollarMillimeter as int?,
      rotSize: identical(rotSize, _sentinel)
          ? this.rotSize
          : rotSize as double?,
      rotLength: identical(rotLength, _sentinel)
          ? this.rotLength
          : rotLength as double?,
      decayClass: decayClass ?? this.decayClass,
      records: records ?? this.records,
      status: status ?? this.status,
      message: message,
    );
  }
}

const _sentinel = Object();

final class StumpsBloc extends Bloc<StumpsEvent, StumpsState> {
  StumpsBloc({required StumpsRepository repository})
    : _repository = repository,
      super(const StumpsState()) {
    on<StumpsLoaded>(_onLoaded);
    on<StumpsSpeciesChanged>(_onSpeciesChanged);
    on<StumpsStumpHeightChanged>(_onStumpHeightChanged);
    on<StumpsStumpHeightDiameterChanged>(_onStumpHeightDiameterChanged);
    on<StumpsRootCollarDiameterChanged>(_onRootCollarDiameterChanged);
    on<StumpsRotSizeChanged>(_onRotSizeChanged);
    on<StumpsRotLengthChanged>(_onRotLengthChanged);
    on<StumpsDecayClassChanged>(_onDecayClassChanged);
    on<StumpsSaved>(_onSaved);
    on<StumpsDeleted>(_onDeleted);
  }

  final StumpsRepository _repository;

  Future<void> _onLoaded(StumpsLoaded event, Emitter<StumpsState> emit) async {
    emit(state.copyWith(status: StumpsStatus.loading));

    try {
      final records = await _repository.getLatestByProbaInfoId(
        event.probaInfoId,
      );
      emit(state.copyWith(records: records, status: StumpsStatus.idle));
    } on Object catch (_) {
      emit(
        state.copyWith(
          status: StumpsStatus.failure,
          message: 'Не удалось загрузить последние записи.',
        ),
      );
    }
  }

  void _onSpeciesChanged(
    StumpsSpeciesChanged event,
    Emitter<StumpsState> emit,
  ) {
    emit(state.copyWith(species: event.value, status: StumpsStatus.idle));
  }

  void _onStumpHeightChanged(
    StumpsStumpHeightChanged event,
    Emitter<StumpsState> emit,
  ) {
    emit(
      state.copyWith(
        stumpHeight: _parseDecimal(event.value) ?? 0,
        status: StumpsStatus.idle,
      ),
    );
  }

  void _onStumpHeightDiameterChanged(
    StumpsStumpHeightDiameterChanged event,
    Emitter<StumpsState> emit,
  ) {
    emit(
      state.copyWith(
        stumpHeightDiameter: event.diameter,
        stumpHeightMillimeter: event.millimeter,
        status: StumpsStatus.idle,
      ),
    );
  }

  void _onRootCollarDiameterChanged(
    StumpsRootCollarDiameterChanged event,
    Emitter<StumpsState> emit,
  ) {
    emit(
      state.copyWith(
        rootCollarDiameter: event.diameter,
        rootCollarMillimeter: event.millimeter,
        status: StumpsStatus.idle,
      ),
    );
  }

  void _onRotSizeChanged(
    StumpsRotSizeChanged event,
    Emitter<StumpsState> emit,
  ) {
    emit(
      state.copyWith(
        rotSize: _parseDecimal(event.value),
        status: StumpsStatus.idle,
      ),
    );
  }

  void _onRotLengthChanged(
    StumpsRotLengthChanged event,
    Emitter<StumpsState> emit,
  ) {
    emit(
      state.copyWith(
        rotLength: _parseDecimal(event.value),
        status: StumpsStatus.idle,
      ),
    );
  }

  void _onDecayClassChanged(
    StumpsDecayClassChanged event,
    Emitter<StumpsState> emit,
  ) {
    emit(state.copyWith(decayClass: event.value, status: StumpsStatus.idle));
  }

  Future<void> _onSaved(StumpsSaved event, Emitter<StumpsState> emit) async {
    emit(state.copyWith(status: StumpsStatus.loading));

    try {
      await _repository.insert(event.record);
      final records = await _repository.getLatestByProbaInfoId(
        event.record.probaInfoId,
      );
      emit(
        state.copyWith(
          records: records,
          status: StumpsStatus.success,
          message: 'Данные по пням сохранены.',
        ),
      );
    } on Object catch (_) {
      emit(
        state.copyWith(
          status: StumpsStatus.failure,
          message: 'Не удалось сохранить данные по пням.',
        ),
      );
    }
  }

  Future<void> _onDeleted(
    StumpsDeleted event,
    Emitter<StumpsState> emit,
  ) async {
    emit(state.copyWith(status: StumpsStatus.loading));

    try {
      await _repository.deleteById(event.id);
      final records = await _repository.getLatestByProbaInfoId(
        event.probaInfoId,
      );
      emit(
        state.copyWith(
          records: records,
          status: StumpsStatus.success,
          message: 'Запись удалена.',
        ),
      );
    } on Object catch (_) {
      emit(
        state.copyWith(
          status: StumpsStatus.failure,
          message: 'Не удалось удалить запись.',
        ),
      );
    }
  }

  double? _parseDecimal(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return double.tryParse(trimmed.replaceAll(',', '.'));
  }
}
