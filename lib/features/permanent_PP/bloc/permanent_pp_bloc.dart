import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:taxation_card/features/permanent_PP/domain/tree_information_repository.dart';

sealed class PermanentPpEvent {
  const PermanentPpEvent();

  const factory PermanentPpEvent.loaded(int probaInfoId) = _Loaded;

  const factory PermanentPpEvent.sentInfo(TreeInformationRecord record) =
      _SentInfo;

  const factory PermanentPpEvent.deleted({
    required int id,
    required int probaInfoId,
  }) = _Deleted;
}

final class _Loaded extends PermanentPpEvent {
  const _Loaded(this.probaInfoId);

  final int probaInfoId;
}

final class _SentInfo extends PermanentPpEvent {
  const _SentInfo(this.record);

  final TreeInformationRecord record;
}

final class _Deleted extends PermanentPpEvent {
  const _Deleted({required this.id, required this.probaInfoId});

  final int id;
  final int probaInfoId;
}

enum PermanentPpStatus { idle, loading, success, failure }

final class PermanentPpState {
  const PermanentPpState({
    this.records = const [],
    this.status = PermanentPpStatus.idle,
    this.message,
  });

  final List<TreeInformationRecord> records;
  final PermanentPpStatus status;
  final String? message;

  bool get isLoading => status == PermanentPpStatus.loading;

  PermanentPpState copyWith({
    List<TreeInformationRecord>? records,
    PermanentPpStatus? status,
    String? message,
  }) {
    return PermanentPpState(
      records: records ?? this.records,
      status: status ?? this.status,
      message: message,
    );
  }
}

final class PermanentPpBloc extends Bloc<PermanentPpEvent, PermanentPpState> {
  PermanentPpBloc({required TreeInformationRepository repository})
    : _repository = repository,
      super(const PermanentPpState()) {
    on<_Loaded>(_onLoaded);
    on<_SentInfo>(_onSentInfo);
    on<_Deleted>(_onDeleted);
  }

  final TreeInformationRepository _repository;

  Future<void> _onLoaded(_Loaded event, Emitter<PermanentPpState> emit) async {
    emit(state.copyWith(status: PermanentPpStatus.loading));

    try {
      final records = await _repository.getLatestByProbaInfoId(
        event.probaInfoId,
      );
      emit(state.copyWith(records: records, status: PermanentPpStatus.idle));
    } on Object catch (_) {
      emit(
        state.copyWith(
          status: PermanentPpStatus.failure,
          message: 'Не удалось загрузить последние записи.',
        ),
      );
    }
  }

  Future<void> _onSentInfo(
    _SentInfo event,
    Emitter<PermanentPpState> emit,
  ) async {
    emit(state.copyWith(status: PermanentPpStatus.loading));

    try {
      await _repository.insert(event.record);
      final records = await _repository.getLatestByProbaInfoId(
        event.record.probaInfoId,
      );
      emit(
        state.copyWith(
          records: records,
          status: PermanentPpStatus.success,
          message: 'Данные сохранены.',
        ),
      );
    } on Object catch (_) {
      emit(
        state.copyWith(
          status: PermanentPpStatus.failure,
          message: 'Не удалось сохранить данные.',
        ),
      );
    }
  }

  Future<void> _onDeleted(
    _Deleted event,
    Emitter<PermanentPpState> emit,
  ) async {
    emit(state.copyWith(status: PermanentPpStatus.loading));

    try {
      await _repository.deleteById(event.id);
      final records = await _repository.getLatestByProbaInfoId(
        event.probaInfoId,
      );
      emit(
        state.copyWith(
          records: records,
          status: PermanentPpStatus.success,
          message: 'Запись удалена.',
        ),
      );
    } on Object catch (_) {
      emit(
        state.copyWith(
          status: PermanentPpStatus.failure,
          message: 'Не удалось удалить запись.',
        ),
      );
    }
  }
}
