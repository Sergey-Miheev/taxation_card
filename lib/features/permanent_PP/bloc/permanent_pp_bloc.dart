import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'permanent_pp_bloc.freezed.dart';

@freezed
sealed class PermanentPpEvent with _$PermanentPpEvent {
  const factory PermanentPpEvent.sentInfo() = _SentInfo;
}

@freezed
sealed class PermanentPpState with _$PermanentPpState {
  const factory PermanentPpState.idle() = _Idle;
  const factory PermanentPpState.loading() = _Loading;
  const factory PermanentPpState.success() = _Success;
  const factory PermanentPpState.failure([String? message]) = _Failure;
}

final class PermanentPpBloc extends Bloc<PermanentPpEvent, PermanentPpState> {
  PermanentPpBloc() : super(const PermanentPpState.idle()) {
    on<_SentInfo>(_onSentInfo);
  }

  Future<void> _onSentInfo(
    _SentInfo event,
    Emitter<PermanentPpState> emit,
  ) async {
    emit(const PermanentPpState.loading());

    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      emit(const PermanentPpState.success());
    } on Object catch (_) {
      emit(const PermanentPpState.failure('Не удалось отправить данные.'));
    }
  }
}
