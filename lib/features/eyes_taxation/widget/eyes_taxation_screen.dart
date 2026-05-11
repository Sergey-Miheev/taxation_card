import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxation_card/features/home/bloc/main_tabs_bloc.dart';
import 'package:taxation_card/features/taxation_characteristic/bloc/taxation_characteristic_bloc.dart';
import 'package:taxation_card/features/taxation_characteristic/widget/taxation_characteristic_screen.dart';

final class EyesTaxationScreen extends StatefulWidget {
  const EyesTaxationScreen({super.key});

  @override
  State<EyesTaxationScreen> createState() => _EyesTaxationScreenState();
}

final class _EyesTaxationScreenState extends State<EyesTaxationScreen>
    with AutomaticKeepAliveClientMixin {
  int? _loadedProbaInfoId;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final selectedProbaInfoId = context.select<MainTabsBloc, int?>(
      (bloc) => bloc.state.selectedProbaInfoId,
    );
    _loadRecordsIfNeeded(selectedProbaInfoId);

    return LayoutBuilder(
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
                    'Глазомерная таксация',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedProbaInfoId == null
                        ? 'Выберите пробную площадь для добавления записей'
                        : 'Добавьте таксационные характеристики ярусов',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildTaxationRecordsList(),
                  const SizedBox(height: 16),
                  _buildAddButton(selectedProbaInfoId),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildTaxationRecordsList() {
    return BlocBuilder<TaxationCharacteristicBloc, TaxationCharacteristicState>(
      buildWhen: (previous, current) => previous.records != current.records,
      builder: (context, state) {
        if (state.records.isEmpty) {
          return const SizedBox.shrink();
        }

        return _SectionCard(
          title: 'Таксационные записи',
          child: Column(
            children: [
              for (var index = 0; index < state.records.length; index++) ...[
                _TaxationRecordTile(record: state.records[index]),
                if (index != state.records.length - 1)
                  const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }

  void _loadRecordsIfNeeded(int? selectedProbaInfoId) {
    if (_loadedProbaInfoId == selectedProbaInfoId) {
      return;
    }

    _loadedProbaInfoId = selectedProbaInfoId;
    if (selectedProbaInfoId == null) {
      return;
    }

    context.read<TaxationCharacteristicBloc>().add(
      TaxationCharacteristicEvent.loaded(selectedProbaInfoId),
    );
  }

  Widget _buildAddButton(int? selectedProbaInfoId) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: selectedProbaInfoId == null
            ? null
            : () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const TaxationCharacteristicScreen(),
                  ),
                );
              },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text('Добавить'),
      ),
    );
  }
}

final class _TaxationRecordTile extends StatelessWidget {
  const _TaxationRecordTile({required this.record});

  final TaxationCharacteristicRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(14);
    final tier = record.tier ?? '-';

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) =>
                  TaxationCharacteristicScreen(initialRecord: record),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Ярус $tier',
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

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
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
