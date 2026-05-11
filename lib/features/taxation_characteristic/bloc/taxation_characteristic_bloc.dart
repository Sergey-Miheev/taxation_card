import 'package:bloc/bloc.dart';
import 'package:taxation_card/features/taxation_characteristic/domain/taxation_characteristic_repository.dart';

enum TaxationCharacteristicField {
  tier,
  dominantSpecies,
  compositionCoefficient,
  age,
  averageHeight,
  diameter,
  density,
  forestType,
  siteClass,
  tlu,
  plantationsTotal,
  coniferousTotal,
  dryStanding,
  nonLiquidWood,
  canopyClosure,
  sparseness,
  commercialWoodOutput,
  merchantabilityClass,
}

sealed class TaxationCharacteristicEvent {
  const TaxationCharacteristicEvent();

  const factory TaxationCharacteristicEvent.loaded(int probaInfoId) =
      TaxationCharacteristicLoaded;

  const factory TaxationCharacteristicEvent.recordSelected(
    TaxationCharacteristicRecord record,
  ) = TaxationCharacteristicRecordSelected;

  const factory TaxationCharacteristicEvent.fieldChanged({
    required TaxationCharacteristicField field,
    required String value,
  }) = TaxationCharacteristicFieldChanged;

  const factory TaxationCharacteristicEvent.added() =
      TaxationCharacteristicAdded;

  const factory TaxationCharacteristicEvent.updated(int id) =
      TaxationCharacteristicUpdated;

  const factory TaxationCharacteristicEvent.saved() =
      TaxationCharacteristicSaved;
}

final class TaxationCharacteristicLoaded extends TaxationCharacteristicEvent {
  const TaxationCharacteristicLoaded(this.probaInfoId);

  final int probaInfoId;
}

final class TaxationCharacteristicRecordSelected
    extends TaxationCharacteristicEvent {
  const TaxationCharacteristicRecordSelected(this.record);

  final TaxationCharacteristicRecord record;
}

final class TaxationCharacteristicFieldChanged
    extends TaxationCharacteristicEvent {
  const TaxationCharacteristicFieldChanged({
    required this.field,
    required this.value,
  });

  final TaxationCharacteristicField field;
  final String value;
}

final class TaxationCharacteristicAdded extends TaxationCharacteristicEvent {
  const TaxationCharacteristicAdded();
}

final class TaxationCharacteristicUpdated extends TaxationCharacteristicEvent {
  const TaxationCharacteristicUpdated(this.id);

  final int id;
}

final class TaxationCharacteristicSaved extends TaxationCharacteristicEvent {
  const TaxationCharacteristicSaved();
}

enum TaxationCharacteristicStatus { idle, loading, success, failure }

final class TaxationCharacteristicRecord {
  const TaxationCharacteristicRecord({
    required this.tier,
    required this.dominantSpecies,
    required this.compositionCoefficient,
    required this.age,
    required this.averageHeight,
    required this.diameter,
    required this.density,
    required this.forestType,
    required this.siteClass,
    required this.tlu,
    required this.plantationsTotal,
    required this.coniferousTotal,
    required this.dryStanding,
    required this.nonLiquidWood,
    required this.canopyClosure,
    required this.sparseness,
    required this.commercialWoodOutput,
    required this.merchantabilityClass,
    required this.probaInfoId,
    this.id,
  });

  final int? id;
  final int probaInfoId;
  final String? tier;
  final String dominantSpecies;
  final String compositionCoefficient;
  final String age;
  final String averageHeight;
  final String diameter;
  final String density;
  final String? forestType;
  final String? siteClass;
  final String? tlu;
  final String plantationsTotal;
  final String coniferousTotal;
  final String dryStanding;
  final String nonLiquidWood;
  final String canopyClosure;
  final String sparseness;
  final String commercialWoodOutput;
  final String? merchantabilityClass;
}

final class TaxationCharacteristicState {
  const TaxationCharacteristicState({
    this.records = const [],
    this.selectedProbaInfoId,
    this.tier,
    this.dominantSpecies = '',
    this.compositionCoefficient = '',
    this.age = '',
    this.averageHeight = '',
    this.diameter = '',
    this.density = '',
    this.forestType,
    this.siteClass,
    this.tlu,
    this.plantationsTotal = '',
    this.coniferousTotal = '',
    this.dryStanding = '',
    this.nonLiquidWood = '',
    this.canopyClosure = '',
    this.sparseness = '',
    this.commercialWoodOutput = '',
    this.merchantabilityClass,
    this.status = TaxationCharacteristicStatus.idle,
    this.message,
  });

  final List<TaxationCharacteristicRecord> records;
  final int? selectedProbaInfoId;
  final String? tier;
  final String dominantSpecies;
  final String compositionCoefficient;
  final String age;
  final String averageHeight;
  final String diameter;
  final String density;
  final String? forestType;
  final String? siteClass;
  final String? tlu;
  final String plantationsTotal;
  final String coniferousTotal;
  final String dryStanding;
  final String nonLiquidWood;
  final String canopyClosure;
  final String sparseness;
  final String commercialWoodOutput;
  final String? merchantabilityClass;
  final TaxationCharacteristicStatus status;
  final String? message;

  TaxationCharacteristicState copyWith({
    List<TaxationCharacteristicRecord>? records,
    int? selectedProbaInfoId,
    String? tier,
    String? dominantSpecies,
    String? compositionCoefficient,
    String? age,
    String? averageHeight,
    String? diameter,
    String? density,
    String? forestType,
    String? siteClass,
    String? tlu,
    String? plantationsTotal,
    String? coniferousTotal,
    String? dryStanding,
    String? nonLiquidWood,
    String? canopyClosure,
    String? sparseness,
    String? commercialWoodOutput,
    String? merchantabilityClass,
    TaxationCharacteristicStatus? status,
    String? message,
  }) {
    return TaxationCharacteristicState(
      records: records ?? this.records,
      selectedProbaInfoId: selectedProbaInfoId ?? this.selectedProbaInfoId,
      tier: tier ?? this.tier,
      dominantSpecies: dominantSpecies ?? this.dominantSpecies,
      compositionCoefficient:
          compositionCoefficient ?? this.compositionCoefficient,
      age: age ?? this.age,
      averageHeight: averageHeight ?? this.averageHeight,
      diameter: diameter ?? this.diameter,
      density: density ?? this.density,
      forestType: forestType ?? this.forestType,
      siteClass: siteClass ?? this.siteClass,
      tlu: tlu ?? this.tlu,
      plantationsTotal: plantationsTotal ?? this.plantationsTotal,
      coniferousTotal: coniferousTotal ?? this.coniferousTotal,
      dryStanding: dryStanding ?? this.dryStanding,
      nonLiquidWood: nonLiquidWood ?? this.nonLiquidWood,
      canopyClosure: canopyClosure ?? this.canopyClosure,
      sparseness: sparseness ?? this.sparseness,
      commercialWoodOutput: commercialWoodOutput ?? this.commercialWoodOutput,
      merchantabilityClass: merchantabilityClass ?? this.merchantabilityClass,
      status: status ?? this.status,
      message: message,
    );
  }
}

final class TaxationCharacteristicBloc
    extends Bloc<TaxationCharacteristicEvent, TaxationCharacteristicState> {
  TaxationCharacteristicBloc({
    required TaxationCharacteristicRepository repository,
  }) : _repository = repository,
       super(const TaxationCharacteristicState()) {
    on<TaxationCharacteristicLoaded>(_onLoaded);
    on<TaxationCharacteristicRecordSelected>(_onRecordSelected);
    on<TaxationCharacteristicFieldChanged>(_onFieldChanged);
    on<TaxationCharacteristicAdded>(_onAdded);
    on<TaxationCharacteristicUpdated>(_onUpdated);
    on<TaxationCharacteristicSaved>(_onSaved);
  }

  final TaxationCharacteristicRepository _repository;

  Future<void> _onLoaded(
    TaxationCharacteristicLoaded event,
    Emitter<TaxationCharacteristicState> emit,
  ) async {
    emit(state.copyWith(status: TaxationCharacteristicStatus.loading));

    try {
      final records = await _repository.getByProbaInfoId(event.probaInfoId);
      emit(
        state.copyWith(
          records: records,
          selectedProbaInfoId: event.probaInfoId,
          status: TaxationCharacteristicStatus.idle,
        ),
      );
    } on Object catch (_) {
      emit(
        state.copyWith(
          status: TaxationCharacteristicStatus.failure,
          message: 'Не удалось загрузить таксационные записи',
        ),
      );
    }
  }

  void _onRecordSelected(
    TaxationCharacteristicRecordSelected event,
    Emitter<TaxationCharacteristicState> emit,
  ) {
    final record = event.record;

    emit(
      state.copyWith(
        selectedProbaInfoId: record.probaInfoId,
        tier: record.tier,
        dominantSpecies: record.dominantSpecies,
        compositionCoefficient: record.compositionCoefficient,
        age: record.age,
        averageHeight: record.averageHeight,
        diameter: record.diameter,
        density: record.density,
        forestType: record.forestType,
        siteClass: record.siteClass,
        tlu: record.tlu,
        plantationsTotal: record.plantationsTotal,
        coniferousTotal: record.coniferousTotal,
        dryStanding: record.dryStanding,
        nonLiquidWood: record.nonLiquidWood,
        canopyClosure: record.canopyClosure,
        sparseness: record.sparseness,
        commercialWoodOutput: record.commercialWoodOutput,
        merchantabilityClass: record.merchantabilityClass,
        status: TaxationCharacteristicStatus.idle,
      ),
    );
  }

  void _onFieldChanged(
    TaxationCharacteristicFieldChanged event,
    Emitter<TaxationCharacteristicState> emit,
  ) {
    final value = event.value;

    switch (event.field) {
      case TaxationCharacteristicField.tier:
        emit(
          state.copyWith(
            tier: value,
            status: TaxationCharacteristicStatus.idle,
          ),
        );
      case TaxationCharacteristicField.dominantSpecies:
        emit(
          state.copyWith(
            dominantSpecies: value,
            status: TaxationCharacteristicStatus.idle,
          ),
        );
      case TaxationCharacteristicField.compositionCoefficient:
        emit(
          state.copyWith(
            compositionCoefficient: value,
            status: TaxationCharacteristicStatus.idle,
          ),
        );
      case TaxationCharacteristicField.age:
        emit(
          state.copyWith(age: value, status: TaxationCharacteristicStatus.idle),
        );
      case TaxationCharacteristicField.averageHeight:
        emit(
          state.copyWith(
            averageHeight: value,
            status: TaxationCharacteristicStatus.idle,
          ),
        );
      case TaxationCharacteristicField.diameter:
        emit(
          state.copyWith(
            diameter: value,
            status: TaxationCharacteristicStatus.idle,
          ),
        );
      case TaxationCharacteristicField.density:
        emit(
          state.copyWith(
            density: value,
            status: TaxationCharacteristicStatus.idle,
          ),
        );
      case TaxationCharacteristicField.forestType:
        emit(
          state.copyWith(
            forestType: value,
            status: TaxationCharacteristicStatus.idle,
          ),
        );
      case TaxationCharacteristicField.siteClass:
        emit(
          state.copyWith(
            siteClass: value,
            status: TaxationCharacteristicStatus.idle,
          ),
        );
      case TaxationCharacteristicField.tlu:
        emit(
          state.copyWith(tlu: value, status: TaxationCharacteristicStatus.idle),
        );
      case TaxationCharacteristicField.plantationsTotal:
        emit(
          state.copyWith(
            plantationsTotal: value,
            status: TaxationCharacteristicStatus.idle,
          ),
        );
      case TaxationCharacteristicField.coniferousTotal:
        emit(
          state.copyWith(
            coniferousTotal: value,
            status: TaxationCharacteristicStatus.idle,
          ),
        );
      case TaxationCharacteristicField.dryStanding:
        emit(
          state.copyWith(
            dryStanding: value,
            status: TaxationCharacteristicStatus.idle,
          ),
        );
      case TaxationCharacteristicField.nonLiquidWood:
        emit(
          state.copyWith(
            nonLiquidWood: value,
            status: TaxationCharacteristicStatus.idle,
          ),
        );
      case TaxationCharacteristicField.canopyClosure:
        emit(
          state.copyWith(
            canopyClosure: value,
            status: TaxationCharacteristicStatus.idle,
          ),
        );
      case TaxationCharacteristicField.sparseness:
        emit(
          state.copyWith(
            sparseness: value,
            status: TaxationCharacteristicStatus.idle,
          ),
        );
      case TaxationCharacteristicField.commercialWoodOutput:
        emit(
          state.copyWith(
            commercialWoodOutput: value,
            status: TaxationCharacteristicStatus.idle,
          ),
        );
      case TaxationCharacteristicField.merchantabilityClass:
        emit(
          state.copyWith(
            merchantabilityClass: value,
            status: TaxationCharacteristicStatus.idle,
          ),
        );
    }
  }

  Future<void> _onAdded(
    TaxationCharacteristicAdded event,
    Emitter<TaxationCharacteristicState> emit,
  ) async {
    final probaInfoId = state.selectedProbaInfoId;
    if (probaInfoId == null) {
      emit(
        state.copyWith(
          status: TaxationCharacteristicStatus.failure,
          message: 'Сначала выберите пробную площадь',
        ),
      );
      return;
    }

    final record = _createRecord(probaInfoId: probaInfoId);

    emit(state.copyWith(status: TaxationCharacteristicStatus.loading));

    try {
      final id = await _repository.insert(record);
      final savedRecord = _createRecord(id: id, probaInfoId: probaInfoId);
      emit(
        state.copyWith(
          records: [...state.records, savedRecord],
          status: TaxationCharacteristicStatus.success,
        ),
      );
    } on Object catch (_) {
      emit(
        state.copyWith(
          status: TaxationCharacteristicStatus.failure,
          message: 'Не удалось добавить запись в базу данных',
        ),
      );
    }
  }

  Future<void> _onUpdated(
    TaxationCharacteristicUpdated event,
    Emitter<TaxationCharacteristicState> emit,
  ) async {
    final probaInfoId = state.selectedProbaInfoId;
    if (probaInfoId == null) {
      emit(
        state.copyWith(
          status: TaxationCharacteristicStatus.failure,
          message: 'Сначала выберите пробную площадь',
        ),
      );
      return;
    }

    final record = _createRecord(id: event.id, probaInfoId: probaInfoId);

    emit(state.copyWith(status: TaxationCharacteristicStatus.loading));

    try {
      await _repository.update(record);
      emit(
        state.copyWith(
          records: [
            for (final item in state.records)
              if (item.id == event.id) record else item,
          ],
          status: TaxationCharacteristicStatus.success,
        ),
      );
    } on Object catch (_) {
      emit(
        state.copyWith(
          status: TaxationCharacteristicStatus.failure,
          message: 'Не удалось изменить запись в базе данных',
        ),
      );
    }
  }

  Future<void> _onSaved(
    TaxationCharacteristicSaved event,
    Emitter<TaxationCharacteristicState> emit,
  ) async {
    emit(state.copyWith(status: TaxationCharacteristicStatus.loading));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    emit(state.copyWith(status: TaxationCharacteristicStatus.success));
  }

  TaxationCharacteristicRecord _createRecord({
    required int probaInfoId,
    int? id,
  }) {
    return TaxationCharacteristicRecord(
      id: id,
      probaInfoId: probaInfoId,
      tier: state.tier,
      dominantSpecies: state.dominantSpecies,
      compositionCoefficient: state.compositionCoefficient,
      age: state.age,
      averageHeight: state.averageHeight,
      diameter: state.diameter,
      density: state.density,
      forestType: state.forestType,
      siteClass: state.siteClass,
      tlu: state.tlu,
      plantationsTotal: state.plantationsTotal,
      coniferousTotal: state.coniferousTotal,
      dryStanding: state.dryStanding,
      nonLiquidWood: state.nonLiquidWood,
      canopyClosure: state.canopyClosure,
      sparseness: state.sparseness,
      commercialWoodOutput: state.commercialWoodOutput,
      merchantabilityClass: state.merchantabilityClass,
    );
  }
}
