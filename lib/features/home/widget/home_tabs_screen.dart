import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxation_card/features/coordinates/widget/coordinates_screen.dart';
import 'package:taxation_card/features/deadwood/widget/deadwood_screen.dart';
import 'package:taxation_card/features/di/widget/dependencies_scope.dart';
import 'package:taxation_card/features/eyes_taxation/widget/eyes_taxation_screen.dart';
import 'package:taxation_card/features/home/bloc/main_tabs_bloc.dart';
import 'package:taxation_card/features/permanent_PP/widget/permanent_pp_screen.dart';
import 'package:taxation_card/features/soils/widget/soils_screen.dart';
import 'package:taxation_card/features/stumps/widget/stumps_screen.dart';
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
  bool _isExporting = false;

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
    final selectedProbaInfoId = context.select<MainTabsBloc, int?>(
      (bloc) => bloc.state.selectedProbaInfoId,
    );

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
          actions: [
            IconButton(
              onPressed: selectedProbaInfoId == null
                  ? null
                  : () => _openCoordinatesScreen(selectedProbaInfoId),
              icon: const Icon(Icons.pin_drop_outlined),
              tooltip: 'Координаты',
            ),
            IconButton(
              onPressed: _isExporting || selectedProbaInfoId == null
                  ? null
                  : () => _showExportDialog(selectedProbaInfoId),
              icon: _isExporting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.ios_share),
              tooltip: 'Выгрузить CSV',
            ),
          ],
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
            StumpsScreen(),
            SoilsScreen(),
          ],
        ),
      ),
    );
  }

  Future<void> _openCoordinatesScreen(int probaInfoId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CoordinatesScreen(probaInfoId: probaInfoId),
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

  Future<void> _showExportDialog(int probaInfoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Выгрузить данные в CSV?'),
          content: const Text(
            'Будут созданы отдельные CSV-файлы по таблицам для текущей пробной площади.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Нет'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Да'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _exportCsv(probaInfoId);
  }

  Future<void> _exportCsv(int probaInfoId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isExporting = true);

    try {
      final exportedFilesCount = await DependenciesScope.of(
        context,
      ).homeCsvExporter.exportProbaInfoData(probaInfoId);

      if (!mounted || exportedFilesCount == null) {
        return;
      }

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Выгружено файлов: $exportedFilesCount')),
      );
    } on Object {
      if (!mounted) {
        return;
      }

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Не удалось выгрузить CSV')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}
