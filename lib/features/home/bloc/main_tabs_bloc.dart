import 'package:bloc/bloc.dart';

enum MainTab {
  eyesTaxation('Глазомерная таксация'),
  permanentPp('Перечётная ведомость'),
  undergrowth('Подрост'),
  understory('Подлесок'),
  deadwood('Валёжник'),
  soils('Почвы');

  const MainTab(this.title);

  final String title;
}

sealed class MainTabsEvent {
  const MainTabsEvent();

  const factory MainTabsEvent.tabSelected(MainTab tab) = MainTabSelected;

  const factory MainTabsEvent.probaInfoSelected(int probaInfoId) =
      ProbaInfoSelected;
}

final class MainTabSelected extends MainTabsEvent {
  const MainTabSelected(this.tab);

  final MainTab tab;
}

final class ProbaInfoSelected extends MainTabsEvent {
  const ProbaInfoSelected(this.probaInfoId);

  final int probaInfoId;
}

final class MainTabsState {
  const MainTabsState({
    this.selectedTab = MainTab.eyesTaxation,
    this.selectedProbaInfoId,
  });

  final MainTab selectedTab;
  final int? selectedProbaInfoId;

  MainTabsState copyWith({MainTab? selectedTab, int? selectedProbaInfoId}) {
    return MainTabsState(
      selectedTab: selectedTab ?? this.selectedTab,
      selectedProbaInfoId: selectedProbaInfoId ?? this.selectedProbaInfoId,
    );
  }
}

final class MainTabsBloc extends Bloc<MainTabsEvent, MainTabsState> {
  MainTabsBloc() : super(const MainTabsState()) {
    on<MainTabSelected>(_onTabSelected);
    on<ProbaInfoSelected>(_onProbaInfoSelected);
  }

  void _onTabSelected(MainTabSelected event, Emitter<MainTabsState> emit) {
    if (event.tab == state.selectedTab) {
      return;
    }

    emit(state.copyWith(selectedTab: event.tab));
  }

  void _onProbaInfoSelected(
    ProbaInfoSelected event,
    Emitter<MainTabsState> emit,
  ) {
    emit(state.copyWith(selectedProbaInfoId: event.probaInfoId));
  }
}
