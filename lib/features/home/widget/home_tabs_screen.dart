import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxation_card/features/deadwood/widget/deadwood_screen.dart';
import 'package:taxation_card/features/eyes_taxation/widget/eyes_taxation_screen.dart';
import 'package:taxation_card/features/home/bloc/main_tabs_bloc.dart';
import 'package:taxation_card/features/permanent_PP/widget/permanent_pp_screen.dart';
import 'package:taxation_card/features/soils/widget/soils_screen.dart';
import 'package:taxation_card/features/undergrowth/widget/undergrowth_screen.dart';
import 'package:taxation_card/features/understory/widget/understory_screen.dart';

final class HomeTabsScreen extends StatefulWidget {
  const HomeTabsScreen({super.key});

  @override
  State<HomeTabsScreen> createState() => _HomeTabsScreenState();
}

final class _HomeTabsScreenState extends State<HomeTabsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final selectedTab = context.read<MainTabsBloc>().state.selectedTab;
    _tabController = TabController(
      length: MainTab.values.length,
      vsync: this,
      initialIndex: selectedTab.index,
    );
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MainTabsBloc, MainTabsState>(
      listenWhen: (previous, current) =>
          previous.selectedTab != current.selectedTab,
      listener: (context, state) {
        if (_tabController.index != state.selectedTab.index) {
          _tabController.animateTo(state.selectedTab.index);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Таксационная карточка'),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white,
            onTap: _selectTab,
            tabs: [for (final tab in MainTab.values) Tab(text: tab.title)],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            EyesTaxationScreen(),
            PermanentPpScreen(),
            UndergrowthScreen(),
            UnderstoryScreen(),
            DeadwoodScreen(),
            SoilsScreen(),
          ],
        ),
      ),
    );
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }

    _selectTab(_tabController.index);
  }

  void _selectTab(int index) {
    context.read<MainTabsBloc>().add(
      MainTabsEvent.tabSelected(MainTab.values[index]),
    );
  }
}
