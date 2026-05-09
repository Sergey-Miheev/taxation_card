import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'eyes_taxation_bloc.freezed.dart';

enum EyesTaxationSubmissionStatus { idle, loading, success, failure }

@freezed
abstract class EyesTaxationFormData with _$EyesTaxationFormData {
  const factory EyesTaxationFormData({
    String? region,
    String? district,
    String? forestry,
    String? subForestry,
    @Default(0) int quarter,
    @Default(0) int allotment,
    @Default(0) int samplePlotNumber,
    @Default(0) double samplePlotArea,
  }) = _EyesTaxationFormData;
}

@freezed
sealed class EyesTaxationEvent with _$EyesTaxationEvent {
  const factory EyesTaxationEvent.regionChanged(String? region) =
      _RegionChanged;

  const factory EyesTaxationEvent.districtChanged(String? district) =
      _DistrictChanged;

  const factory EyesTaxationEvent.forestryChanged(String? forestry) =
      _ForestryChanged;

  const factory EyesTaxationEvent.subForestryChanged(String? subForestry) =
      _SubForestryChanged;

  const factory EyesTaxationEvent.quarterChanged(String quarter) =
      _QuarterChanged;

  const factory EyesTaxationEvent.allotmentChanged(String allotment) =
      _AllotmentChanged;

  const factory EyesTaxationEvent.samplePlotNumberChanged(
    String samplePlotNumber,
  ) = _SamplePlotNumberChanged;

  const factory EyesTaxationEvent.samplePlotAreaChanged(String samplePlotArea) =
      _SamplePlotAreaChanged;

  const factory EyesTaxationEvent.sentInfo() = _SentInfo;
}

@freezed
abstract class EyesTaxationState with _$EyesTaxationState {
  const factory EyesTaxationState({
    @Default(EyesTaxationFormData()) EyesTaxationFormData data,
    @Default(EyesTaxationSubmissionStatus.idle)
    EyesTaxationSubmissionStatus status,
    String? message,
  }) = _EyesTaxationState;
}

final class EyesTaxationBloc
    extends Bloc<EyesTaxationEvent, EyesTaxationState> {
  EyesTaxationBloc() : super(const EyesTaxationState()) {
    on<_RegionChanged>(_onRegionChanged);
    on<_DistrictChanged>(_onDistrictChanged);
    on<_ForestryChanged>(_onForestryChanged);
    on<_SubForestryChanged>(_onSubForestryChanged);
    on<_QuarterChanged>(_onQuarterChanged);
    on<_AllotmentChanged>(_onAllotmentChanged);
    on<_SamplePlotNumberChanged>(_onSamplePlotNumberChanged);
    on<_SamplePlotAreaChanged>(_onSamplePlotAreaChanged);
    on<_SentInfo>(_onSentInfo);
  }

  void _onRegionChanged(_RegionChanged event, Emitter<EyesTaxationState> emit) {
    emit(
      state.copyWith(
        data: state.data.copyWith(region: event.region, district: null),
        status: EyesTaxationSubmissionStatus.idle,
        message: null,
      ),
    );
  }

  void _onDistrictChanged(
    _DistrictChanged event,
    Emitter<EyesTaxationState> emit,
  ) {
    emit(
      state.copyWith(
        data: state.data.copyWith(district: event.district),
        status: EyesTaxationSubmissionStatus.idle,
        message: null,
      ),
    );
  }

  void _onForestryChanged(
    _ForestryChanged event,
    Emitter<EyesTaxationState> emit,
  ) {
    emit(
      state.copyWith(
        data: state.data.copyWith(forestry: event.forestry),
        status: EyesTaxationSubmissionStatus.idle,
        message: null,
      ),
    );
  }

  void _onSubForestryChanged(
    _SubForestryChanged event,
    Emitter<EyesTaxationState> emit,
  ) {
    emit(
      state.copyWith(
        data: state.data.copyWith(subForestry: event.subForestry),
        status: EyesTaxationSubmissionStatus.idle,
        message: null,
      ),
    );
  }

  void _onQuarterChanged(
    _QuarterChanged event,
    Emitter<EyesTaxationState> emit,
  ) {
    emit(
      state.copyWith(
        data: state.data.copyWith(quarter: int.tryParse(event.quarter) ?? 0),
        status: EyesTaxationSubmissionStatus.idle,
        message: null,
      ),
    );
  }

  void _onAllotmentChanged(
    _AllotmentChanged event,
    Emitter<EyesTaxationState> emit,
  ) {
    emit(
      state.copyWith(
        data: state.data.copyWith(
          allotment: int.tryParse(event.allotment) ?? 0,
        ),
        status: EyesTaxationSubmissionStatus.idle,
        message: null,
      ),
    );
  }

  void _onSamplePlotNumberChanged(
    _SamplePlotNumberChanged event,
    Emitter<EyesTaxationState> emit,
  ) {
    emit(
      state.copyWith(
        data: state.data.copyWith(
          samplePlotNumber: int.tryParse(event.samplePlotNumber) ?? 0,
        ),
        status: EyesTaxationSubmissionStatus.idle,
        message: null,
      ),
    );
  }

  void _onSamplePlotAreaChanged(
    _SamplePlotAreaChanged event,
    Emitter<EyesTaxationState> emit,
  ) {
    emit(
      state.copyWith(
        data: state.data.copyWith(
          samplePlotArea: double.tryParse(event.samplePlotArea) ?? 0,
        ),
        status: EyesTaxationSubmissionStatus.idle,
        message: null,
      ),
    );
  }

  Future<void> _onSentInfo(
    _SentInfo event,
    Emitter<EyesTaxationState> emit,
  ) async {
    emit(
      state.copyWith(
        status: EyesTaxationSubmissionStatus.loading,
        message: null,
      ),
    );

    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      emit(state.copyWith(status: EyesTaxationSubmissionStatus.success));
    } on Object catch (_) {
      emit(
        state.copyWith(
          status: EyesTaxationSubmissionStatus.failure,
          message: 'Не удалось отправить данные.',
        ),
      );
    }
  }
}
