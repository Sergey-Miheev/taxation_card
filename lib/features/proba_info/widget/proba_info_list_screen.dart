import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taxation_card/core/router/routes.dart';
import 'package:taxation_card/features/di/widget/dependencies_scope.dart';
import 'package:taxation_card/features/home/bloc/main_tabs_bloc.dart';
import 'package:taxation_card/features/proba_info/domain/proba_info_repository.dart';
import 'package:taxation_card/features/proba_info/widget/proba_info_screen.dart';

final class ProbaInfoListScreen extends StatefulWidget {
  const ProbaInfoListScreen({super.key});

  @override
  State<ProbaInfoListScreen> createState() => _ProbaInfoListScreenState();
}

final class _ProbaInfoListScreenState extends State<ProbaInfoListScreen> {
  late Future<List<ProbaInfoRecord>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _recordsFuture = _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Пробные площади')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 720;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 16,
              vertical: 16,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Пробные площади',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Выберите запись для перехода к таксационной карточке или измените данные пробной площади.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildRecordsList(),
                    const SizedBox(height: 16),
                    _buildAddButton(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<List<ProbaInfoRecord>> _loadRecords() {
    return DependenciesScope.of(context).probaInfoRepository.getAll();
  }

  Widget _buildRecordsList() {
    return FutureBuilder<List<ProbaInfoRecord>>(
      future: _recordsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const _InfoPanel(
            title: 'Не удалось загрузить данные',
            message: 'Попробуйте открыть список ещё раз.',
          );
        }

        final records = snapshot.data ?? const [];
        if (records.isEmpty) {
          return const _InfoPanel(
            title: 'Записей пока нет',
            message: 'Добавьте первую пробную площадь.',
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (var index = 0; index < records.length; index++) ...[
                  _ProbaInfoTile(
                    record: records[index],
                    onTap: () => _openEyesTaxation(records[index]),
                    onEditPressed: () => _openProbaInfoForm(records[index]),
                  ),
                  if (index != records.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _openProbaInfoForm,
        icon: const Icon(Icons.add),
        label: const Text('Добавить запись'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Future<void> _openProbaInfoForm([ProbaInfoRecord? record]) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => ProbaInfoScreen(initialRecord: record),
      ),
    );

    if (updated != true || !mounted) {
      return;
    }

    setState(() {
      _recordsFuture = _loadRecords();
    });
  }

  Future<void> _openEyesTaxation(ProbaInfoRecord record) async {
    final id = record.id;
    if (id == null) {
      return;
    }

    context.read<MainTabsBloc>()
      ..add(MainTabsEvent.probaInfoSelected(id))
      ..add(const MainTabsEvent.tabSelected(MainTab.eyesTaxation));
    await context.pushNamed(AppRoutes.home.name);
  }
}

final class _ProbaInfoTile extends StatelessWidget {
  const _ProbaInfoTile({
    required this.record,
    required this.onTap,
    required this.onEditPressed,
  });

  final ProbaInfoRecord record;
  final VoidCallback onTap;
  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(14);
    final subForestry = record.subForestry?.trim();

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Пробная площадь №${record.samplePlotNumber}',
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subForestry == null || subForestry.isEmpty
                          ? 'Участковое лесничество не указано'
                          : subForestry,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEditPressed,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Редактировать',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
