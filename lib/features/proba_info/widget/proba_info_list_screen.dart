import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taxation_card/core/router/routes.dart';
import 'package:taxation_card/features/app/app_runner.dart';
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
  var _isExportingDatabase = false;
  var _isImportingDatabase = false;

  @override
  void initState() {
    super.initState();
    _recordsFuture = _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Пробные площади'),
        actions: [_buildAppBarActions()],
      ),
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

  Widget _buildAppBarActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showText = MediaQuery.sizeOf(context).width >= 560;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAppBarAction(
              isLoading: _isImportingDatabase,
              icon: Icons.file_download_outlined,
              label: 'Импорт',
              tooltip: 'Импортировать базу данных',
              onPressed: _confirmAndImportDatabase,
              showText: showText,
            ),
            _buildAppBarAction(
              isLoading: _isExportingDatabase,
              icon: Icons.file_upload_outlined,
              label: 'Экспорт',
              tooltip: 'Экспортировать базу данных',
              onPressed: _confirmAndExportDatabase,
              showText: showText,
            ),
            const SizedBox(width: 4),
          ],
        );
      },
    );
  }

  Widget _buildAppBarAction({
    required bool isLoading,
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback onPressed,
    required bool showText,
  }) {
    if (isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: showText ? 20 : 16),
        child: const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (!showText) {
      return IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        tooltip: tooltip,
        color: Theme.of(context).appBarTheme.foregroundColor,
      );
    }

    final appBarForegroundColor = Theme.of(context).appBarTheme.foregroundColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: TextButton.styleFrom(foregroundColor: appBarForegroundColor),
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

  Future<void> _exportDatabase() async {
    setState(() {
      _isExportingDatabase = true;
    });

    try {
      final exportedPath = await DependenciesScope.of(
        context,
      ).databaseExporter.exportToSelectedDirectory();
      if (!mounted || exportedPath == null) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('База данных экспортирована: $exportedPath')),
      );
    } on Object {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось экспортировать базу данных')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExportingDatabase = false;
        });
      }
    }
  }

  Future<void> _confirmAndExportDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Экспорт базы данных'),
          content: const Text(
            'Текущая база данных будет сохранена в выбранное место.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Экспортировать'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    await _exportDatabase();
  }

  Future<void> _confirmAndImportDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Импорт базы данных'),
          content: const Text(
            'Выбранная база станет текущей рабочей базой приложения.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Импортировать'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    await _importDatabase();
  }

  Future<void> _importDatabase() async {
    setState(() {
      _isImportingDatabase = true;
    });

    try {
      final imported = await DependenciesScope.of(
        context,
      ).databaseExporter.importFromSelectedFile();
      if (!mounted || !imported) {
        return;
      }

      await const AppRunner().initializeAndRun();
    } on Object {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось импортировать базу данных')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImportingDatabase = false;
        });
      }
    }
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
    final createdAt = _formatCreatedAt(record.createdAt);

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
              if (createdAt != null) ...[
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    createdAt,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
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

  String? _formatCreatedAt(DateTime? date) {
    if (date == null) {
      return null;
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day.$month.${date.year} $hour:$minute';
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
