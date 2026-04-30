import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'main_info_bloc.freezed.dart';

enum MainInfoSubmissionStatus { idle, loading, success, failure }

@freezed
abstract class MainInfoFormData with _$MainInfoFormData {
  const factory MainInfoFormData({
    String? region,
    String? district,
    String? forestry,
    String? subForestry,
    @Default(0) int quarter,
    @Default(0) int allotment,
    @Default(0) int samplePlotNumber,
    @Default(0) double samplePlotArea,
  }) = _MainInfoFormData;
}

@freezed
sealed class MainInfoEvent with _$MainInfoEvent {
  const factory MainInfoEvent.regionChanged(String? region) = _RegionChanged;

  const factory MainInfoEvent.districtChanged(String? district) =
      _DistrictChanged;

  const factory MainInfoEvent.forestryChanged(String? forestry) =
      _ForestryChanged;

  const factory MainInfoEvent.subForestryChanged(String? subForestry) =
      _SubForestryChanged;

  const factory MainInfoEvent.quarterChanged(String quarter) = _QuarterChanged;

  const factory MainInfoEvent.allotmentChanged(String allotment) =
      _AllotmentChanged;

  const factory MainInfoEvent.samplePlotNumberChanged(String samplePlotNumber) =
      _SamplePlotNumberChanged;

  const factory MainInfoEvent.samplePlotAreaChanged(String samplePlotArea) =
      _SamplePlotAreaChanged;

  const factory MainInfoEvent.sentInfo() = _SentInfo;
}

@freezed
abstract class MainInfoState with _$MainInfoState {
  const factory MainInfoState({
    @Default(MainInfoFormData()) MainInfoFormData data,
    @Default(MainInfoSubmissionStatus.idle) MainInfoSubmissionStatus status,
    String? message,
  }) = _MainInfoState;
}

final class MainInfoBloc extends Bloc<MainInfoEvent, MainInfoState> {
  MainInfoBloc() : super(const MainInfoState()) {
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

  void _onRegionChanged(_RegionChanged event, Emitter<MainInfoState> emit) {
    emit(
      state.copyWith(
        data: state.data.copyWith(region: event.region, district: null),
        status: MainInfoSubmissionStatus.idle,
        message: null,
      ),
    );
  }

  void _onDistrictChanged(_DistrictChanged event, Emitter<MainInfoState> emit) {
    emit(
      state.copyWith(
        data: state.data.copyWith(district: event.district),
        status: MainInfoSubmissionStatus.idle,
        message: null,
      ),
    );
  }

  void _onForestryChanged(_ForestryChanged event, Emitter<MainInfoState> emit) {
    emit(
      state.copyWith(
        data: state.data.copyWith(forestry: event.forestry),
        status: MainInfoSubmissionStatus.idle,
        message: null,
      ),
    );
  }

  void _onSubForestryChanged(
    _SubForestryChanged event,
    Emitter<MainInfoState> emit,
  ) {
    emit(
      state.copyWith(
        data: state.data.copyWith(subForestry: event.subForestry),
        status: MainInfoSubmissionStatus.idle,
        message: null,
      ),
    );
  }

  void _onQuarterChanged(_QuarterChanged event, Emitter<MainInfoState> emit) {
    emit(
      state.copyWith(
        data: state.data.copyWith(quarter: int.tryParse(event.quarter) ?? 0),
        status: MainInfoSubmissionStatus.idle,
        message: null,
      ),
    );
  }

  void _onAllotmentChanged(
    _AllotmentChanged event,
    Emitter<MainInfoState> emit,
  ) {
    emit(
      state.copyWith(
        data: state.data.copyWith(
          allotment: int.tryParse(event.allotment) ?? 0,
        ),
        status: MainInfoSubmissionStatus.idle,
        message: null,
      ),
    );
  }

  void _onSamplePlotNumberChanged(
    _SamplePlotNumberChanged event,
    Emitter<MainInfoState> emit,
  ) {
    emit(
      state.copyWith(
        data: state.data.copyWith(
          samplePlotNumber: int.tryParse(event.samplePlotNumber) ?? 0,
        ),
        status: MainInfoSubmissionStatus.idle,
        message: null,
      ),
    );
  }

  void _onSamplePlotAreaChanged(
    _SamplePlotAreaChanged event,
    Emitter<MainInfoState> emit,
  ) {
    emit(
      state.copyWith(
        data: state.data.copyWith(
          samplePlotArea: double.tryParse(event.samplePlotArea) ?? 0,
        ),
        status: MainInfoSubmissionStatus.idle,
        message: null,
      ),
    );
  }

  Future<void> _onSentInfo(_SentInfo event, Emitter<MainInfoState> emit) async {
    emit(
      state.copyWith(status: MainInfoSubmissionStatus.loading, message: null),
    );

    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      emit(state.copyWith(status: MainInfoSubmissionStatus.success));
    } on Object catch (_) {
      emit(
        state.copyWith(
          status: MainInfoSubmissionStatus.failure,
          message: 'Не удалось отправить данные.',
        ),
      );
    }
  }
}
