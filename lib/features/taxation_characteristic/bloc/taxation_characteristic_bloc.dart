import 'package:bloc/bloc.dart';

enum TaxationCharacteristicField {
  tier,
  dominantSpecies,
  compositionCoefficient,
  age,
  averageHeight,
  diameter,
  density,
  stock,
  forestType,
  siteClass,
  tlu,
  plantationsTotal,
  coniferousTotal,
  canopyClosure,
  sparseness,
  commercialWoodOutput,
  merchantabilityClass,
}

sealed class TaxationCharacteristicEvent {
  const TaxationCharacteristicEvent();

  const factory TaxationCharacteristicEvent.fieldChanged({
    required TaxationCharacteristicField field,
    required String value,
  }) = TaxationCharacteristicFieldChanged;

  const factory TaxationCharacteristicEvent.added() =
      TaxationCharacteristicAdded;

  const factory TaxationCharacteristicEvent.saved() =
      TaxationCharacteristicSaved;
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

final class TaxationCharacteristicSaved extends TaxationCharacteristicEvent {
  const TaxationCharacteristicSaved();
}

enum TaxationCharacteristicStatus { idle, loading, success, failure }

final class TaxationCharacteristicState {
  const TaxationCharacteristicState({
    this.tier,
    this.dominantSpecies = '',
    this.compositionCoefficient = '',
    this.age = '',
    this.averageHeight = '',
    this.diameter = '',
    this.density = '',
    this.stock = '',
    this.forestType,
    this.siteClass,
    this.tlu = '',
    this.plantationsTotal = '',
    this.coniferousTotal = '',
    this.canopyClosure = '',
    this.sparseness = '',
    this.commercialWoodOutput = '',
    this.merchantabilityClass,
    this.status = TaxationCharacteristicStatus.idle,
    this.message,
  });

  final String? tier;
  final String dominantSpecies;
  final String compositionCoefficient;
  final String age;
  final String averageHeight;
  final String diameter;
  final String density;
  final String stock;
  final String? forestType;
  final String? siteClass;
  final String tlu;
  final String plantationsTotal;
  final String coniferousTotal;
  final String canopyClosure;
  final String sparseness;
  final String commercialWoodOutput;
  final String? merchantabilityClass;
  final TaxationCharacteristicStatus status;
  final String? message;

  TaxationCharacteristicState copyWith({
    String? tier,
    String? dominantSpecies,
    String? compositionCoefficient,
    String? age,
    String? averageHeight,
    String? diameter,
    String? density,
    String? stock,
    String? forestType,
    String? siteClass,
    String? tlu,
    String? plantationsTotal,
    String? coniferousTotal,
    String? canopyClosure,
    String? sparseness,
    String? commercialWoodOutput,
    String? merchantabilityClass,
    TaxationCharacteristicStatus? status,
    String? message,
  }) {
    return TaxationCharacteristicState(
      tier: tier ?? this.tier,
      dominantSpecies: dominantSpecies ?? this.dominantSpecies,
      compositionCoefficient:
          compositionCoefficient ?? this.compositionCoefficient,
      age: age ?? this.age,
      averageHeight: averageHeight ?? this.averageHeight,
      diameter: diameter ?? this.diameter,
      density: density ?? this.density,
      stock: stock ?? this.stock,
      forestType: forestType ?? this.forestType,
      siteClass: siteClass ?? this.siteClass,
      tlu: tlu ?? this.tlu,
      plantationsTotal: plantationsTotal ?? this.plantationsTotal,
      coniferousTotal: coniferousTotal ?? this.coniferousTotal,
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
  TaxationCharacteristicBloc() : super(const TaxationCharacteristicState()) {
    on<TaxationCharacteristicFieldChanged>(_onFieldChanged);
    on<TaxationCharacteristicAdded>(_onAdded);
    on<TaxationCharacteristicSaved>(_onSaved);
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
      case TaxationCharacteristicField.stock:
        emit(
          state.copyWith(
            stock: value,
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
    await _completeSubmission(emit);
  }

  Future<void> _onSaved(
    TaxationCharacteristicSaved event,
    Emitter<TaxationCharacteristicState> emit,
  ) async {
    await _completeSubmission(emit);
  }

  Future<void> _completeSubmission(
    Emitter<TaxationCharacteristicState> emit,
  ) async {
    emit(state.copyWith(status: TaxationCharacteristicStatus.loading));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    emit(state.copyWith(status: TaxationCharacteristicStatus.success));
  }
}
