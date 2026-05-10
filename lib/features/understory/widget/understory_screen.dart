import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxation_card/core/constants/constants.dart';
import 'package:taxation_card/features/di/widget/dependencies_scope.dart';
import 'package:taxation_card/features/home/bloc/main_tabs_bloc.dart';
import 'package:taxation_card/features/understory/domain/understory_repository.dart';

final class UnderstoryScreen extends StatefulWidget {
  const UnderstoryScreen({super.key});

  @override
  State<UnderstoryScreen> createState() => _UnderstoryScreenState();
}

final class _UnderstoryScreenState extends State<UnderstoryScreen>
    with AutomaticKeepAliveClientMixin {
  final List<_UnderstoryTableRow> _rows = [];
  int? _selectedIndex;
  int? _loadedProbaInfoId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final selectedProbaInfoId = context.select<MainTabsBloc, int?>(
      (bloc) => bloc.state.selectedProbaInfoId,
    );
    _loadRowsIfNeeded(selectedProbaInfoId);

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Подлесок', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  selectedProbaInfoId == null
                      ? 'Выберите пробную площадь, чтобы заполнить подлесок.'
                      : 'Заполните показатели мелкого, среднего и крупного подлеска.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                if (_isLoading) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                ],
                Expanded(
                  child: _ScrollableTableCard(
                    child: _UnderstoryEditableTable(
                      rows: _rows,
                      selectedIndex: _selectedIndex,
                      onRowSelected: (index) {
                        setState(() => _selectedIndex = index);
                      },
                      onRowFocusLost: _updateRow,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _ScrollableTableCard(
                    child: _LargeUnderstoryEditableTable(
                      rows: _rows,
                      selectedIndex: _selectedIndex,
                      onRowSelected: (index) {
                        setState(() => _selectedIndex = index);
                      },
                      onRowFocusLost: _updateRow,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: selectedProbaInfoId == null || _isLoading
                        ? null
                        : () => _addRow(selectedProbaInfoId),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectedIndex == null || _isLoading
                        ? null
                        : _deleteRow,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Удалить'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _addRow(int probaInfoId) async {
    final repository = DependenciesScope.of(context).understoryRepository;
    final row = _UnderstoryTableRow.empty(probaInfoId: probaInfoId);

    try {
      final id = await repository.insert(row.toRecord());
      row.id = id;
    } on Object catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось добавить запись подлеска.')),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _rows.add(row);
      _selectedIndex = _rows.length - 1;
    });
  }

  Future<void> _deleteRow() async {
    final selectedIndex = _selectedIndex;
    if (selectedIndex == null) {
      return;
    }

    final repository = DependenciesScope.of(context).understoryRepository;
    final row = _rows[selectedIndex];
    final id = row.id;

    if (id != null) {
      try {
        await repository.deleteById(id);
      } on Object catch (_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось удалить запись подлеска.')),
        );
        return;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _rows.removeAt(selectedIndex);
      if (_rows.isEmpty) {
        _selectedIndex = null;
        return;
      }

      _selectedIndex = selectedIndex >= _rows.length
          ? _rows.length - 1
          : selectedIndex;
    });
  }

  void _loadRowsIfNeeded(int? selectedProbaInfoId) {
    if (_loadedProbaInfoId == selectedProbaInfoId) {
      return;
    }

    _loadedProbaInfoId = selectedProbaInfoId;
    _selectedIndex = null;

    if (selectedProbaInfoId == null) {
      _rows.clear();
      _isLoading = false;
      return;
    }

    final repository = DependenciesScope.of(context).understoryRepository;
    _rows.clear();
    _isLoading = true;

    unawaited(
      repository
          .getByProbaInfoId(selectedProbaInfoId)
          .then((records) {
            if (!mounted || _loadedProbaInfoId != selectedProbaInfoId) {
              return;
            }

            setState(() {
              _rows
                ..clear()
                ..addAll(records.map(_UnderstoryTableRow.fromRecord));
              _isLoading = false;
            });
          })
          .catchError((Object _) {
            if (!mounted || _loadedProbaInfoId != selectedProbaInfoId) {
              return;
            }

            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Не удалось загрузить записи подлеска.'),
              ),
            );
          }),
    );
  }

  Future<void> _updateRow(_UnderstoryTableRow row) async {
    final id = row.id;
    if (id == null) {
      return;
    }

    try {
      await DependenciesScope.of(
        context,
      ).understoryRepository.update(row.toRecord());
    } on Object catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось обновить запись подлеска.')),
      );
    }
  }
}

final class _ScrollableTableCard extends StatelessWidget {
  const _ScrollableTableCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: child,
          ),
        ),
      ),
    );
  }
}

final class _UnderstoryEditableTable extends StatelessWidget {
  const _UnderstoryEditableTable({
    required this.rows,
    required this.selectedIndex,
    required this.onRowSelected,
    required this.onRowFocusLost,
  });

  final List<_UnderstoryTableRow> rows;
  final int? selectedIndex;
  final ValueChanged<int> onRowSelected;
  final ValueChanged<_UnderstoryTableRow> onRowFocusLost;

  static const _borderColor = Color(0xFFE0E0E0);
  static const _rowHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(border: Border.all(color: _borderColor)),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(44),
          1: FixedColumnWidth(76),
          2: FixedColumnWidth(150),
          3: FixedColumnWidth(150),
          4: FixedColumnWidth(68),
          5: FixedColumnWidth(68),
          6: FixedColumnWidth(68),
          7: FixedColumnWidth(68),
          8: FixedColumnWidth(68),
          9: FixedColumnWidth(68),
          10: FixedColumnWidth(76),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFF8F8F8)),
            children: [
              _HeaderCell(text: '', height: 56),
              _HeaderCell(text: '№\nуч.\nпл.', height: 56),
              _HeaderCell(text: 'Древесная\nпорода', height: 56),
              _HeaderCell(text: 'Происхо-\nждение', height: 56),
              _HeaderCell(text: 'Мелкий, средний подлесок', height: 56),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell(text: 'показатели\nмодельного\nдерева', height: 56),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
            ],
          ),
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFF8F8F8)),
            children: [
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell(
                text: 'количество по\nгруппам высот, шт.',
                height: 50,
              ),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
            ],
          ),
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFF8F8F8)),
            children: [
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell(text: 'до 0.5', height: 42),
              _HeaderCell.empty(),
              _HeaderCell(text: '0.51-1.5', height: 42),
              _HeaderCell.empty(),
              _HeaderCell(text: 'A,\nлет', height: 42),
              _HeaderCell(text: 'h, м', height: 42),
              _HeaderCell(text: 'd0.5\nh, см', height: 42),
            ],
          ),
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFF8F8F8)),
            children: [
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell(text: 'ж.', height: 36),
              _HeaderCell(text: 'пог.', height: 36),
              _HeaderCell(text: 'ж.', height: 36),
              _HeaderCell(text: 'пог.', height: 36),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
            ],
          ),
          for (var index = 0; index < rows.length; index++)
            _buildDataRow(
              context: context,
              index: index,
              row: rows[index],
              isSelected: selectedIndex == index,
              theme: theme,
            ),
        ],
      ),
    );
  }

  TableRow _buildDataRow({
    required BuildContext context,
    required int index,
    required _UnderstoryTableRow row,
    required bool isSelected,
    required ThemeData theme,
  }) {
    final rowColor = isSelected
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
        : Colors.white;
    final rowKey = row.keySuffix;

    return TableRow(
      decoration: BoxDecoration(color: rowColor),
      children: [
        _SelectableIndexCell(
          text: '${index + 1}',
          isSelected: isSelected,
          onTap: () => onRowSelected(index),
        ),
        _EditableTableCell(
          initialValue: row.plotNumber,
          cellKey: ValueKey('plot-number-$rowKey'),
          keyboardType: TextInputType.number,
          onTap: () => onRowSelected(index),
          onChanged: (value) {
            row.plotNumber = value;
            onRowSelected(index);
          },
          onFocusLost: () => onRowFocusLost(row),
        ),
        _DropdownTableCell(
          value: allSpecies.contains(row.species) ? row.species : null,
          items: allSpecies,
          cellKey: ValueKey('species-$rowKey'),
          onTap: () => onRowSelected(index),
          onChanged: (value) {
            row.species = value ?? '';
            onRowFocusLost(row);
          },
        ),
        _DropdownTableCell(
          value: allOrigins.contains(row.origin) ? row.origin : null,
          items: allOrigins,
          cellKey: ValueKey('origin-$rowKey'),
          onTap: () => onRowSelected(index),
          onChanged: (value) {
            row.origin = value ?? '';
            onRowFocusLost(row);
          },
        ),
        _EditableTableCell(
          initialValue: row.smallLiving,
          cellKey: ValueKey('small-living-$rowKey'),
          keyboardType: TextInputType.number,
          onTap: () => onRowSelected(index),
          onChanged: (value) => row.smallLiving = value,
          onFocusLost: () => onRowFocusLost(row),
        ),
        _EditableTableCell(
          initialValue: row.smallDamaged,
          cellKey: ValueKey('small-damaged-$rowKey'),
          keyboardType: TextInputType.number,
          onTap: () => onRowSelected(index),
          onChanged: (value) => row.smallDamaged = value,
          onFocusLost: () => onRowFocusLost(row),
        ),
        _EditableTableCell(
          initialValue: row.mediumLiving,
          cellKey: ValueKey('medium-living-$rowKey'),
          keyboardType: TextInputType.number,
          onTap: () => onRowSelected(index),
          onChanged: (value) => row.mediumLiving = value,
          onFocusLost: () => onRowFocusLost(row),
        ),
        _EditableTableCell(
          initialValue: row.mediumDamaged,
          cellKey: ValueKey('medium-damaged-$rowKey'),
          keyboardType: TextInputType.number,
          onTap: () => onRowSelected(index),
          onChanged: (value) => row.mediumDamaged = value,
          onFocusLost: () => onRowFocusLost(row),
        ),
        _EditableTableCell(
          initialValue: row.modelAge,
          cellKey: ValueKey('model-age-$rowKey'),
          keyboardType: TextInputType.number,
          onTap: () => onRowSelected(index),
          onChanged: (value) => row.modelAge = value,
          onFocusLost: () => onRowFocusLost(row),
        ),
        _EditableTableCell(
          initialValue: row.modelHeight,
          cellKey: ValueKey('model-height-$rowKey'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onTap: () => onRowSelected(index),
          onChanged: (value) => row.modelHeight = value,
          onFocusLost: () => onRowFocusLost(row),
        ),
        _EditableTableCell(
          initialValue: row.modelDiameter,
          cellKey: ValueKey('model-diameter-$rowKey'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onTap: () => onRowSelected(index),
          onChanged: (value) => row.modelDiameter = value,
          onFocusLost: () => onRowFocusLost(row),
        ),
      ],
    );
  }
}

final class _LargeUnderstoryEditableTable extends StatelessWidget {
  const _LargeUnderstoryEditableTable({
    required this.rows,
    required this.selectedIndex,
    required this.onRowSelected,
    required this.onRowFocusLost,
  });

  final List<_UnderstoryTableRow> rows;
  final int? selectedIndex;
  final ValueChanged<int> onRowSelected;
  final ValueChanged<_UnderstoryTableRow> onRowFocusLost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: _UnderstoryEditableTable._borderColor),
      ),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(44),
          1: FixedColumnWidth(76),
          2: FixedColumnWidth(68),
          3: FixedColumnWidth(68),
          4: FixedColumnWidth(68),
          5: FixedColumnWidth(68),
          6: FixedColumnWidth(68),
          7: FixedColumnWidth(68),
          8: FixedColumnWidth(68),
          9: FixedColumnWidth(68),
          10: FixedColumnWidth(68),
          11: FixedColumnWidth(68),
          12: FixedColumnWidth(68),
          13: FixedColumnWidth(68),
          14: FixedColumnWidth(76),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFF8F8F8)),
            children: [
              _HeaderCell(text: '', height: 56),
              _HeaderCell(text: '№\nуч.\nпл.', height: 56),
              _HeaderCell(text: 'Крупный подлесок', height: 56),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell(text: 'показатели\nмодельного\nдерева', height: 56),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
            ],
          ),
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFF8F8F8)),
            children: [
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell(
                text: 'количество по\nгруппам высот, шт.',
                height: 50,
              ),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
            ],
          ),
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFF8F8F8)),
            children: [
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell(text: '1.51-2.5', height: 42),
              _HeaderCell.empty(),
              _HeaderCell(text: '2.51-3.5', height: 42),
              _HeaderCell.empty(),
              _HeaderCell(text: '3.51-4.5', height: 42),
              _HeaderCell.empty(),
              _HeaderCell(text: '4.51-5.5', height: 42),
              _HeaderCell.empty(),
              _HeaderCell(text: '5.51 и>', height: 42),
              _HeaderCell.empty(),
              _HeaderCell(text: 'A,\nлет', height: 42),
              _HeaderCell(text: 'h, м', height: 42),
              _HeaderCell(text: 'd1.3,\nсм', height: 42),
            ],
          ),
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFF8F8F8)),
            children: [
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell(text: 'ж.', height: 36),
              _HeaderCell(text: 'пог.', height: 36),
              _HeaderCell(text: 'ж.', height: 36),
              _HeaderCell(text: 'пог.', height: 36),
              _HeaderCell(text: 'ж.', height: 36),
              _HeaderCell(text: 'пог.', height: 36),
              _HeaderCell(text: 'ж.', height: 36),
              _HeaderCell(text: 'пог.', height: 36),
              _HeaderCell(text: 'ж.', height: 36),
              _HeaderCell(text: 'пог.', height: 36),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
              _HeaderCell.empty(),
            ],
          ),
          for (var index = 0; index < rows.length; index++)
            _buildDataRow(
              index: index,
              row: rows[index],
              isSelected: selectedIndex == index,
              theme: theme,
            ),
        ],
      ),
    );
  }

  TableRow _buildDataRow({
    required int index,
    required _UnderstoryTableRow row,
    required bool isSelected,
    required ThemeData theme,
  }) {
    final rowColor = isSelected
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
        : Colors.white;
    final rowKey = row.keySuffix;

    return TableRow(
      decoration: BoxDecoration(color: rowColor),
      children: [
        _SelectableIndexCell(
          text: '${index + 1}',
          isSelected: isSelected,
          onTap: () => onRowSelected(index),
        ),
        _ReadOnlyTableCell(
          text: row.plotNumber,
          onTap: () => onRowSelected(index),
        ),
        _EditableTableCell(
          initialValue: row.large15125Living,
          cellKey: ValueKey('large-151-25-living-$rowKey'),
          keyboardType: TextInputType.number,
          onTap: () => onRowSelected(index),
          onChanged: (value) => row.large15125Living = value,
          onFocusLost: () => onRowFocusLost(row),
        ),
        _EditableTableCell(
          initialValue: row.large15125Damaged,
          cellKey: ValueKey('large-151-25-damaged-$rowKey'),
          keyboardType: TextInputType.number,
          onTap: () => onRowSelected(index),
          onChanged: (value) => row.large15125Damaged = value,
          onFocusLost: () => onRowFocusLost(row),
        ),
        _EditableTableCell(
          initialValue: row.large25135Living,
          cellKey: ValueKey('large-251-35-living-$rowKey'),
          keyboardType: TextInputType.number,
          onTap: () => onRowSelected(index),
          onChanged: (value) => row.large25135Living = value,
          onFocusLost: () => onRowFocusLost(row),
        ),
        _EditableTableCell(
          initialValue: row.large25135Damaged,
          cellKey: ValueKey('large-251-35-damaged-$rowKey'),
          keyboardType: TextInputType.number,
          onTap: () => onRowSelected(index),
          onChanged: (value) => row.large25135Damaged = value,
          onFocusLost: () => onRowFocusLost(row),
        ),
        _EditableTableCell(
          initialValue: row.large35145Living,
          cellKey: ValueKey('large-351-45-living-$rowKey'),
          keyboardType: TextInputType.number,
          onTap: () => onRowSelected(index),
          onChanged: (value) => row.large35145Living = value,
          onFocusLost: () => onRowFocusLost(row),
        ),
        _EditableTableCell(
          initialValue: row.large35145Damaged,
          cellKey: ValueKey('large-351-45-damaged-$rowKey'),
          keyboardType: TextInputType.number,
          onTap: () => onRowSelected(index),
          onChanged: (value) => row.large35145Damaged = value,
          onFocusLost: () => onRowFocusLost(row),
        ),
        _EditableTableCell(
          initialValue: row.large45155Living,
          cellKey: ValueKey('large-451-55-living-$rowKey'),
          keyboardType: TextInputType.number,
          onTap: () => onRowSelected(index),
          onChanged: (value) => row.large45155Living = value,
          onFocusLost: () => onRowFocusLost(row),
        ),
        _EditableTableCell(
          initialValue: row.large45155Damaged,
          cellKey: ValueKey('large-451-55-damaged-$rowKey'),
          keyboardType: TextInputType.number,
          onTap: () => onRowSelected(index),
          onChanged: (value) => row.large45155Damaged = value,
          onFocusLost: () => onRowFocusLost(row),
        ),
        _EditableTableCell(
          initialValue: row.large551PlusLiving,
          cellKey: ValueKey('large-551-plus-living-$rowKey'),
          keyboardType: TextInputType.number,
          onTap: () => onRowSelected(index),
          onChanged: (value) => row.large551PlusLiving = value,
          onFocusLost: () => onRowFocusLost(row),
        ),
        _EditableTableCell(
          initialValue: row.large551PlusDamaged,
          cellKey: ValueKey('large-551-plus-damaged-$rowKey'),
          keyboardType: TextInputType.number,
          onTap: () => onRowSelected(index),
          onChanged: (value) => row.large551PlusDamaged = value,
          onFocusLost: () => onRowFocusLost(row),
        ),
        _EditableTableCell(
          initialValue: row.largeModelAge,
          cellKey: ValueKey('large-model-age-$rowKey'),
          keyboardType: TextInputType.number,
          onTap: () => onRowSelected(index),
          onChanged: (value) => row.largeModelAge = value,
          onFocusLost: () => onRowFocusLost(row),
        ),
        _EditableTableCell(
          initialValue: row.largeModelHeight,
          cellKey: ValueKey('large-model-height-$rowKey'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onTap: () => onRowSelected(index),
          onChanged: (value) => row.largeModelHeight = value,
          onFocusLost: () => onRowFocusLost(row),
        ),
        _EditableTableCell(
          initialValue: row.largeModelDiameter,
          cellKey: ValueKey('large-model-diameter-$rowKey'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onTap: () => onRowSelected(index),
          onChanged: (value) => row.largeModelDiameter = value,
          onFocusLost: () => onRowFocusLost(row),
        ),
      ],
    );
  }
}

final class _UnderstoryTableRow {
  _UnderstoryTableRow({
    required this.probaInfoId,
    required this.plotNumber,
    required this.species,
    required this.origin,
    required this.smallLiving,
    required this.smallDamaged,
    required this.mediumLiving,
    required this.mediumDamaged,
    required this.modelAge,
    required this.modelHeight,
    required this.modelDiameter,
    required this.large15125Living,
    required this.large15125Damaged,
    required this.large25135Living,
    required this.large25135Damaged,
    required this.large35145Living,
    required this.large35145Damaged,
    required this.large45155Living,
    required this.large45155Damaged,
    required this.large551PlusLiving,
    required this.large551PlusDamaged,
    required this.largeModelAge,
    required this.largeModelHeight,
    required this.largeModelDiameter,
    this.id,
  });

  factory _UnderstoryTableRow.empty({required int probaInfoId}) {
    return _UnderstoryTableRow(
      probaInfoId: probaInfoId,
      plotNumber: '0',
      species: '',
      origin: '',
      smallLiving: '0',
      smallDamaged: '0',
      mediumLiving: '0',
      mediumDamaged: '0',
      modelAge: '0',
      modelHeight: '0',
      modelDiameter: '0',
      large15125Living: '0',
      large15125Damaged: '0',
      large25135Living: '0',
      large25135Damaged: '0',
      large35145Living: '0',
      large35145Damaged: '0',
      large45155Living: '0',
      large45155Damaged: '0',
      large551PlusLiving: '0',
      large551PlusDamaged: '0',
      largeModelAge: '0',
      largeModelHeight: '0',
      largeModelDiameter: '0',
    );
  }

  factory _UnderstoryTableRow.fromRecord(UnderstoryRecord record) {
    return _UnderstoryTableRow(
      id: record.id,
      probaInfoId: record.probaInfoId,
      plotNumber: record.plotNumber.toString(),
      species: record.species ?? '',
      origin: record.origin ?? '',
      smallLiving: record.smallLiving.toString(),
      smallDamaged: record.smallDamaged.toString(),
      mediumLiving: record.mediumLiving.toString(),
      mediumDamaged: record.mediumDamaged.toString(),
      modelAge: record.modelAge.toString(),
      modelHeight: _formatDouble(record.modelHeight),
      modelDiameter: _formatDouble(record.modelDiameter),
      large15125Living: record.large15125Living.toString(),
      large15125Damaged: record.large15125Damaged.toString(),
      large25135Living: record.large25135Living.toString(),
      large25135Damaged: record.large25135Damaged.toString(),
      large35145Living: record.large35145Living.toString(),
      large35145Damaged: record.large35145Damaged.toString(),
      large45155Living: record.large45155Living.toString(),
      large45155Damaged: record.large45155Damaged.toString(),
      large551PlusLiving: record.large551PlusLiving.toString(),
      large551PlusDamaged: record.large551PlusDamaged.toString(),
      largeModelAge: record.largeModelAge.toString(),
      largeModelHeight: _formatDouble(record.largeModelHeight),
      largeModelDiameter: _formatDouble(record.largeModelDiameter),
    );
  }

  int? id;
  final int probaInfoId;
  String plotNumber;
  String species;
  String origin;
  String smallLiving;
  String smallDamaged;
  String mediumLiving;
  String mediumDamaged;
  String modelAge;
  String modelHeight;
  String modelDiameter;
  String large15125Living;
  String large15125Damaged;
  String large25135Living;
  String large25135Damaged;
  String large35145Living;
  String large35145Damaged;
  String large45155Living;
  String large45155Damaged;
  String large551PlusLiving;
  String large551PlusDamaged;
  String largeModelAge;
  String largeModelHeight;
  String largeModelDiameter;

  String get keySuffix => id?.toString() ?? identityHashCode(this).toString();

  UnderstoryRecord toRecord() {
    return UnderstoryRecord(
      id: id,
      probaInfoId: probaInfoId,
      plotNumber: _parseInt(plotNumber),
      species: _emptyToNull(species),
      origin: _emptyToNull(origin),
      smallLiving: _parseInt(smallLiving),
      smallDamaged: _parseInt(smallDamaged),
      mediumLiving: _parseInt(mediumLiving),
      mediumDamaged: _parseInt(mediumDamaged),
      modelAge: _parseInt(modelAge),
      modelHeight: _parseDouble(modelHeight),
      modelDiameter: _parseDouble(modelDiameter),
      large15125Living: _parseInt(large15125Living),
      large15125Damaged: _parseInt(large15125Damaged),
      large25135Living: _parseInt(large25135Living),
      large25135Damaged: _parseInt(large25135Damaged),
      large35145Living: _parseInt(large35145Living),
      large35145Damaged: _parseInt(large35145Damaged),
      large45155Living: _parseInt(large45155Living),
      large45155Damaged: _parseInt(large45155Damaged),
      large551PlusLiving: _parseInt(large551PlusLiving),
      large551PlusDamaged: _parseInt(large551PlusDamaged),
      largeModelAge: _parseInt(largeModelAge),
      largeModelHeight: _parseDouble(largeModelHeight),
      largeModelDiameter: _parseDouble(largeModelDiameter),
    );
  }

  static int _parseInt(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }

  static double _parseDouble(String value) {
    return double.tryParse(value.replaceAll(',', '.').trim()) ?? 0;
  }

  static String _formatDouble(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  static String? _emptyToNull(String value) {
    final trimmedValue = value.trim();
    return trimmedValue.isEmpty ? null : trimmedValue;
  }
}

final class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.text, required this.height});

  const _HeaderCell.empty() : text = '', height = 0;

  final String text;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (height == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: _UnderstoryEditableTable._borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

final class _SelectableIndexCell extends StatelessWidget {
  const _SelectableIndexCell({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        height: _UnderstoryEditableTable._rowHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: _UnderstoryEditableTable._borderColor),
        ),
        child: Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isSelected ? theme.colorScheme.primary : null,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

final class _ReadOnlyTableCell extends StatelessWidget {
  const _ReadOnlyTableCell({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: _UnderstoryEditableTable._rowHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: _UnderstoryEditableTable._borderColor),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}

final class _EditableTableCell extends StatefulWidget {
  const _EditableTableCell({
    required this.initialValue,
    required this.cellKey,
    required this.onChanged,
    required this.onTap,
    required this.onFocusLost,
    this.keyboardType,
  }) : super(key: cellKey);

  final String initialValue;
  final Key cellKey;
  final ValueChanged<String> onChanged;
  final VoidCallback onTap;
  final VoidCallback onFocusLost;
  final TextInputType? keyboardType;

  @override
  State<_EditableTableCell> createState() => _EditableTableCellState();
}

final class _EditableTableCellState extends State<_EditableTableCell> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      widget.onFocusLost();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _UnderstoryEditableTable._rowHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: _UnderstoryEditableTable._borderColor),
      ),
      child: TextFormField(
        focusNode: _focusNode,
        initialValue: widget.initialValue,
        keyboardType: widget.keyboardType,
        textAlign: TextAlign.center,
        onTap: widget.onTap,
        onChanged: widget.onChanged,
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        ),
      ),
    );
  }
}

final class _DropdownTableCell extends StatelessWidget {
  const _DropdownTableCell({
    required this.value,
    required this.items,
    required this.cellKey,
    required this.onChanged,
    required this.onTap,
  });

  final String? value;
  final List<String> items;
  final Key cellKey;
  final ValueChanged<String?> onChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _UnderstoryEditableTable._rowHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: _UnderstoryEditableTable._borderColor),
      ),
      child: DropdownButtonFormField<String>(
        key: cellKey,
        initialValue: value,
        isExpanded: true,
        menuMaxHeight: 360,
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, maxLines: 2, softWrap: true),
              ),
            )
            .toList(),
        selectedItemBuilder: (context) => items
            .map(
              (item) => Center(
                child: Text(
                  item,
                  maxLines: 2,
                  softWrap: true,
                  textAlign: TextAlign.center,
                ),
              ),
            )
            .toList(),
        onTap: onTap,
        onChanged: onChanged,
      ),
    );
  }
}
