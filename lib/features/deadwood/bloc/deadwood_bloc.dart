import 'package:bloc/bloc.dart';
import 'package:taxation_card/features/deadwood/domain/deadwood_repository.dart';

sealed class DeadwoodEvent {
  const DeadwoodEvent();

  const factory DeadwoodEvent.volumeChanged(String value) =
      DeadwoodVolumeChanged;

  const factory DeadwoodEvent.loaded(int probaInfoId) = DeadwoodLoaded;

  const factory DeadwoodEvent.speciesChanged(String? value) =
      DeadwoodSpeciesChanged;

  const factory DeadwoodEvent.lengthChanged(String value) =
      DeadwoodLengthChanged;

  const factory DeadwoodEvent.diameterChanged({
    required int? diameter,
    required int? millimeter,
  }) = DeadwoodDiameterChanged;

  const factory DeadwoodEvent.rotSizeChanged(String value) =
      DeadwoodRotSizeChanged;

  const factory DeadwoodEvent.rotLengthChanged(String value) =
      DeadwoodRotLengthChanged;

  const factory DeadwoodEvent.decayClassChanged(String value) =
      DeadwoodDecayClassChanged;

  const factory DeadwoodEvent.saved(DeadwoodRecord record) = DeadwoodSaved;

  const factory DeadwoodEvent.deleted({
    required int id,
    required int probaInfoId,
  }) = DeadwoodDeleted;
}

final class DeadwoodVolumeChanged extends DeadwoodEvent {
  const DeadwoodVolumeChanged(this.value);

  final String value;
}

final class DeadwoodLoaded extends DeadwoodEvent {
  const DeadwoodLoaded(this.probaInfoId);

  final int probaInfoId;
}

final class DeadwoodSpeciesChanged extends DeadwoodEvent {
  const DeadwoodSpeciesChanged(this.value);

  final String? value;
}

final class DeadwoodLengthChanged extends DeadwoodEvent {
  const DeadwoodLengthChanged(this.value);

  final String value;
}

final class DeadwoodDiameterChanged extends DeadwoodEvent {
  const DeadwoodDiameterChanged({
    required this.diameter,
    required this.millimeter,
  });

  final int? diameter;
  final int? millimeter;
}

final class DeadwoodRotSizeChanged extends DeadwoodEvent {
  const DeadwoodRotSizeChanged(this.value);

  final String value;
}

final class DeadwoodRotLengthChanged extends DeadwoodEvent {
  const DeadwoodRotLengthChanged(this.value);

  final String value;
}

final class DeadwoodDecayClassChanged extends DeadwoodEvent {
  const DeadwoodDecayClassChanged(this.value);

  final String value;
}

final class DeadwoodSaved extends DeadwoodEvent {
  const DeadwoodSaved(this.record);

  final DeadwoodRecord record;
}

final class DeadwoodDeleted extends DeadwoodEvent {
  const DeadwoodDeleted({required this.id, required this.probaInfoId});

  final int id;
  final int probaInfoId;
}

enum DeadwoodStatus { idle, loading, success, failure }

final class DeadwoodState {
  const DeadwoodState({
    this.volume = 0,
    this.species,
    this.length = 0,
    this.diameter,
    this.millimeter,
    this.rotSize,
    this.rotLength,
    this.decayClass,
    this.records = const [],
    this.status = DeadwoodStatus.idle,
    this.message,
  });

  final double volume;
  final String? species;
  final double length;
  final int? diameter;
  final int? millimeter;
  final double? rotSize;
  final double? rotLength;
  final String? decayClass;
  final List<DeadwoodRecord> records;
  final DeadwoodStatus status;
  final String? message;

  bool get isLoading => status == DeadwoodStatus.loading;

  DeadwoodState copyWith({
    double? volume,
    Object? species = _sentinel,
    double? length,
    Object? diameter = _sentinel,
    Object? millimeter = _sentinel,
    Object? rotSize = _sentinel,
    Object? rotLength = _sentinel,
    String? decayClass,
    List<DeadwoodRecord>? records,
    DeadwoodStatus? status,
    String? message,
  }) {
    return DeadwoodState(
      volume: volume ?? this.volume,
      species: identical(species, _sentinel)
          ? this.species
          : species as String?,
      length: length ?? this.length,
      diameter: identical(diameter, _sentinel)
          ? this.diameter
          : diameter as int?,
      millimeter: identical(millimeter, _sentinel)
          ? this.millimeter
          : millimeter as int?,
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

final class DeadwoodBloc extends Bloc<DeadwoodEvent, DeadwoodState> {
  DeadwoodBloc({required DeadwoodRepository repository})
    : _repository = repository,
      super(const DeadwoodState()) {
    on<DeadwoodVolumeChanged>(_onVolumeChanged);
    on<DeadwoodLoaded>(_onLoaded);
    on<DeadwoodSpeciesChanged>(_onSpeciesChanged);
    on<DeadwoodLengthChanged>(_onLengthChanged);
    on<DeadwoodDiameterChanged>(_onDiameterChanged);
    on<DeadwoodRotSizeChanged>(_onRotSizeChanged);
    on<DeadwoodRotLengthChanged>(_onRotLengthChanged);
    on<DeadwoodDecayClassChanged>(_onDecayClassChanged);
    on<DeadwoodSaved>(_onSaved);
    on<DeadwoodDeleted>(_onDeleted);
  }

  final DeadwoodRepository _repository;

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

  Future<void> _onLoaded(
    DeadwoodLoaded event,
    Emitter<DeadwoodState> emit,
  ) async {
    emit(state.copyWith(status: DeadwoodStatus.loading));

    try {
      final records = await _repository.getLatestByProbaInfoId(
        event.probaInfoId,
      );
      emit(state.copyWith(records: records, status: DeadwoodStatus.idle));
    } on Object catch (_) {
      emit(
        state.copyWith(
          status: DeadwoodStatus.failure,
          message: 'Не удалось загрузить записи.',
        ),
      );
    }
  }

  void _onSpeciesChanged(
    DeadwoodSpeciesChanged event,
    Emitter<DeadwoodState> emit,
  ) {
    emit(state.copyWith(species: event.value, status: DeadwoodStatus.idle));
  }

  void _onLengthChanged(
    DeadwoodLengthChanged event,
    Emitter<DeadwoodState> emit,
  ) {
    emit(
      state.copyWith(
        length: _parseDecimal(event.value) ?? 0,
        status: DeadwoodStatus.idle,
      ),
    );
  }

  void _onDiameterChanged(
    DeadwoodDiameterChanged event,
    Emitter<DeadwoodState> emit,
  ) {
    emit(
      state.copyWith(
        diameter: event.diameter,
        millimeter: event.millimeter,
        status: DeadwoodStatus.idle,
      ),
    );
  }

  void _onRotSizeChanged(
    DeadwoodRotSizeChanged event,
    Emitter<DeadwoodState> emit,
  ) {
    emit(
      state.copyWith(
        rotSize: _parseDecimal(event.value),
        status: DeadwoodStatus.idle,
      ),
    );
  }

  void _onRotLengthChanged(
    DeadwoodRotLengthChanged event,
    Emitter<DeadwoodState> emit,
  ) {
    emit(
      state.copyWith(
        rotLength: _parseDecimal(event.value),
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

    try {
      await _repository.insert(event.record);
      final records = await _repository.getLatestByProbaInfoId(
        event.record.probaInfoId,
      );
      emit(
        state.copyWith(
          records: records,
          status: DeadwoodStatus.success,
          message: 'Данные по валёжнику сохранены.',
        ),
      );
    } on Object catch (_) {
      emit(
        state.copyWith(
          status: DeadwoodStatus.failure,
          message: 'Не удалось сохранить данные по валёжнику.',
        ),
      );
    }
  }

  Future<void> _onDeleted(
    DeadwoodDeleted event,
    Emitter<DeadwoodState> emit,
  ) async {
    emit(state.copyWith(status: DeadwoodStatus.loading));

    try {
      await _repository.deleteById(event.id);
      final records = await _repository.getLatestByProbaInfoId(
        event.probaInfoId,
      );
      emit(
        state.copyWith(
          records: records,
          status: DeadwoodStatus.success,
          message: 'Запись удалена.',
        ),
      );
    } on Object catch (_) {
      emit(
        state.copyWith(
          status: DeadwoodStatus.failure,
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
