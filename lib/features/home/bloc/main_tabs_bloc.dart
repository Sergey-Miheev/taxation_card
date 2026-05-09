import 'package:bloc/bloc.dart';

enum MainTab {
  eyesTaxation('Глазомерная таксация'),
  permanentPp('Перечётная ведомость'),
  undergrowth('Подрост/подлесок'),
  deadwood('Валёжник'),
  soils('Почвы');

  const MainTab(this.title);

  final String title;
}

sealed class MainTabsEvent {
  const MainTabsEvent();

  const factory MainTabsEvent.tabSelected(MainTab tab) = MainTabSelected;
}

final class MainTabSelected extends MainTabsEvent {
  const MainTabSelected(this.tab);

  final MainTab tab;
}

final class MainTabsState {
  const MainTabsState({this.selectedTab = MainTab.eyesTaxation});

  final MainTab selectedTab;

  MainTabsState copyWith({MainTab? selectedTab}) {
    return MainTabsState(selectedTab: selectedTab ?? this.selectedTab);
  }
}

final class MainTabsBloc extends Bloc<MainTabsEvent, MainTabsState> {
  MainTabsBloc() : super(const MainTabsState()) {
    on<MainTabSelected>(_onTabSelected);
  }

  void _onTabSelected(MainTabSelected event, Emitter<MainTabsState> emit) {
    if (event.tab == state.selectedTab) {
      return;
    }

    emit(state.copyWith(selectedTab: event.tab));
  }
}
