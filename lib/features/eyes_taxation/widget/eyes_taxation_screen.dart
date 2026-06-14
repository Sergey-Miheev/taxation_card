import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxation_card/core/widgets/species_picker_dialog.dart';
import 'package:taxation_card/features/di/widget/dependencies_scope.dart';
import 'package:taxation_card/features/home/bloc/main_tabs_bloc.dart';
import 'package:taxation_card/features/taxation_characteristic/bloc/taxation_characteristic_bloc.dart';

final class EyesTaxationScreen extends StatefulWidget {
  const EyesTaxationScreen({super.key});

  @override
  State<EyesTaxationScreen> createState() => _EyesTaxationScreenState();
}

final class _EyesTaxationScreenState extends State<EyesTaxationScreen>
    with AutomaticKeepAliveClientMixin {
  static const _initialRowCount = 10;
  static const _defaultOrigin = 'семенное естественное';
  static const _defaultMerchantabilityClass = '1';

  final List<_TaxationRowData> _rows = [];
  int? _loadedProbaInfoId;
  bool _isLoading = false;
  bool _isSavingRows = false;
  bool _saveAgainRequested = false;
  var _lastSavedRowsSignature = '';

  @override
  void initState() {
    super.initState();
    _setRows(const []);
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final selectedProbaInfoId = context.select<MainTabsBloc, int?>(
      (bloc) => bloc.state.selectedProbaInfoId,
    );
    _loadRowsIfNeeded(selectedProbaInfoId);

    return Scaffold(
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _buildRowActionButtons(enabled: selectedProbaInfoId != null),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 720;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isTablet ? 12 : 16,
              16,
              isTablet ? 12 : 16,
              96,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
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
                          ? 'Выберите пробную площадь для заполнения таблицы.'
                          : 'Заполните таксационные характеристики ярусов.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      _TaxationTable(
                        rows: _rows,
                        onSpeciesPressed: _selectSpecies,
                        onSpeciesCleared: _clearSpecies,
                        onCellFocusLost: _saveRows,
                        onOriginChanged: _saveRows,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  void _loadRowsIfNeeded(int? selectedProbaInfoId) {
    if (_loadedProbaInfoId == selectedProbaInfoId) {
      return;
    }

    _loadedProbaInfoId = selectedProbaInfoId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loadedProbaInfoId != selectedProbaInfoId) {
        return;
      }

      unawaited(_loadRows(selectedProbaInfoId));
    });
  }

  Future<void> _loadRows(int? selectedProbaInfoId) async {
    if (selectedProbaInfoId == null) {
      setState(() => _setRows(const []));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repository = DependenciesScope.of(
        context,
      ).taxationCharacteristicRepository;
      final records = await repository.getByProbaInfoId(selectedProbaInfoId);
      if (!mounted || _loadedProbaInfoId != selectedProbaInfoId) {
        return;
      }

      setState(() => _setRows(records));
    } on Object catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось загрузить таксационные записи.'),
        ),
      );
    } finally {
      if (mounted && _loadedProbaInfoId == selectedProbaInfoId) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveRows() async {
    if (_isLoading) {
      return;
    }

    final selectedProbaInfoId = _loadedProbaInfoId;
    if (selectedProbaInfoId == null) {
      return;
    }

    final currentSignature = _rowsSignature();
    if (currentSignature == _lastSavedRowsSignature) {
      return;
    }

    if (_isSavingRows) {
      _saveAgainRequested = true;
      return;
    }

    _isSavingRows = true;
    try {
      final records = [
        for (final row in _rows)
          if (!row.isEmpty) row.toRecord(probaInfoId: selectedProbaInfoId),
      ];
      final repository = DependenciesScope.of(
        context,
      ).taxationCharacteristicRepository;
      await repository.replaceForProbaInfoId(
        probaInfoId: selectedProbaInfoId,
        records: records,
      );

      if (!mounted) {
        return;
      }

      _lastSavedRowsSignature = currentSignature;
    } on Object catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось сохранить таксационные записи.'),
        ),
      );
    } finally {
      _isSavingRows = false;
      if (_saveAgainRequested) {
        _saveAgainRequested = false;
        unawaited(_saveRows());
      }
    }
  }

  Future<void> _selectSpecies(_TaxationRowData row) async {
    final selectedSpecies = row.speciesController.text.trim();
    final result = await showSpeciesPickerDialog(
      context: context,
      selectedSpecies: selectedSpecies.isEmpty ? null : selectedSpecies,
    );
    if (result == null || !mounted) {
      return;
    }

    setState(() {
      row.speciesController.text = result;
      if (row.originController.text.trim().isEmpty) {
        row.originController.text = _defaultOrigin;
      }
      if (row.merchantabilityClassController.text.trim().isEmpty) {
        row.merchantabilityClassController.text = _defaultMerchantabilityClass;
      }
    });
    unawaited(_saveRows());
  }

  void _clearSpecies(_TaxationRowData row) {
    setState(row.speciesController.clear);
    unawaited(_saveRows());
  }

  Widget _buildRowActionButtons({required bool enabled}) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: enabled ? _addRow : null,
            icon: const Icon(Icons.add),
            label: const Text('Добавить'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enabled && _rows.isNotEmpty ? _removeLastRow : null,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Удалить'),
          ),
        ),
      ],
    );
  }

  void _addRow() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _rows.add(_TaxationRowData.empty()));
  }

  void _removeLastRow() {
    if (_rows.isEmpty) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    late final _TaxationRowData removedRow;
    setState(() => removedRow = _rows.removeLast());

    final shouldSave = !removedRow.isEmpty;
    removedRow.dispose();
    if (shouldSave) {
      unawaited(_saveRows());
    }
  }

  void _setRows(List<TaxationCharacteristicRecord> records) {
    for (final row in _rows) {
      row.dispose();
    }
    _rows
      ..clear()
      ..addAll(records.map(_TaxationRowData.fromRecord));

    while (_rows.length < _initialRowCount) {
      _rows.add(_TaxationRowData.empty());
    }
    _lastSavedRowsSignature = _rowsSignature();
  }

  String _rowsSignature() {
    return _rows.map((row) => row.signature).join('\u001e');
  }
}

final class _TaxationTable extends StatelessWidget {
  const _TaxationTable({
    required this.rows,
    required this.onSpeciesPressed,
    required this.onSpeciesCleared,
    required this.onCellFocusLost,
    required this.onOriginChanged,
  });

  final List<_TaxationRowData> rows;
  final ValueChanged<_TaxationRowData> onSpeciesPressed;
  final ValueChanged<_TaxationRowData> onSpeciesCleared;
  final VoidCallback onCellFocusLost;
  final VoidCallback onOriginChanged;
  static const _originOptions = [
    'семенное естественное',
    'семенное искусственное',
    'вегетативное порослевое',
    'вегетативное корнеотпрысковое',
    'вегетативное отводковое',
  ];
  static const _merchantabilityClassOptions = ['1', '2', '3', '4'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FixedColumnWidth(60),
              1: FixedColumnWidth(60),
              2: FixedColumnWidth(130),
              3: FixedColumnWidth(70),
              4: FixedColumnWidth(70),
              5: FixedColumnWidth(80),
              6: FixedColumnWidth(100),
              7: FixedColumnWidth(70),
            },
            border: TableBorder(
              horizontalInside: BorderSide(color: borderColor),
              verticalInside: BorderSide(color: borderColor),
            ),
            children: [
              _buildHeaderRow(context),
              for (var index = 0; index < rows.length; index++)
                _buildDataRow(context, rows[index], index),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildHeaderRow(BuildContext context) {
    final theme = Theme.of(context);
    final headers = [
      '№',
      'Состав яруса',
      'Порода',
      'Высота, м',
      'Диаметр, см',
      'Возраст, лет',
      'Происхождение',
      'Класс товарности',
    ];

    return TableRow(
      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer),
      children: [
        for (final header in headers)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            child: Text(
              header,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  TableRow _buildDataRow(
    BuildContext context,
    _TaxationRowData row,
    int index,
  ) {
    final theme = Theme.of(context);
    final fillColor = index.isEven
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.32)
        : theme.colorScheme.surface;

    return TableRow(
      decoration: BoxDecoration(color: fillColor),
      children: [
        _TableTextField(
          controller: row.tierController,
          isNumber: true,
          onFocusLost: onCellFocusLost,
        ),
        _TableTextField(
          controller: row.compositionController,
          onFocusLost: onCellFocusLost,
        ),
        _SpeciesTableCell(
          row: row,
          onPressed: () => onSpeciesPressed(row),
          onCleared: () => onSpeciesCleared(row),
        ),
        _TableTextField(
          controller: row.heightController,
          isDecimal: true,
          onFocusLost: onCellFocusLost,
        ),
        _TableTextField(
          controller: row.diameterController,
          isDecimal: true,
          onFocusLost: onCellFocusLost,
        ),
        _TableTextField(
          controller: row.ageController,
          isNumber: true,
          onFocusLost: onCellFocusLost,
        ),
        _OriginDropdownCell(
          controller: row.originController,
          options: _originOptions,
          onChanged: onOriginChanged,
        ),
        _MerchantabilityClassDropdownCell(
          controller: row.merchantabilityClassController,
          options: _merchantabilityClassOptions,
          onChanged: onOriginChanged,
        ),
      ],
    );
  }
}

final class _MerchantabilityClassDropdownCell extends StatefulWidget {
  const _MerchantabilityClassDropdownCell({
    required this.controller,
    required this.options,
    required this.onChanged,
  });

  final TextEditingController controller;
  final List<String> options;
  final VoidCallback onChanged;

  @override
  State<_MerchantabilityClassDropdownCell> createState() =>
      _MerchantabilityClassDropdownCellState();
}

final class _MerchantabilityClassDropdownCellState
    extends State<_MerchantabilityClassDropdownCell> {
  @override
  Widget build(BuildContext context) {
    final currentValue = widget.controller.text.trim();
    final value = widget.options.contains(currentValue) ? currentValue : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        items: [
          for (final option in widget.options)
            DropdownMenuItem<String>(value: option, child: Text(option)),
        ],
        onChanged: (value) {
          setState(() => widget.controller.text = value ?? '');
          widget.onChanged();
        },
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        ),
      ),
    );
  }
}

final class _OriginDropdownCell extends StatefulWidget {
  const _OriginDropdownCell({
    required this.controller,
    required this.options,
    required this.onChanged,
  });

  final TextEditingController controller;
  final List<String> options;
  final VoidCallback onChanged;

  @override
  State<_OriginDropdownCell> createState() => _OriginDropdownCellState();
}

final class _OriginDropdownCellState extends State<_OriginDropdownCell> {
  @override
  Widget build(BuildContext context) {
    final currentValue = widget.controller.text.trim();
    final value = widget.options.contains(currentValue) ? currentValue : null;
    final originTextStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontSize: 14, height: 1.05);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        iconSize: 12,
        itemHeight: 64,
        items: [
          for (final option in widget.options)
            DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: originTextStyle,
              ),
            ),
        ],
        selectedItemBuilder: (context) {
          return [
            for (final option in widget.options)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  option,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: originTextStyle,
                ),
              ),
          ];
        },
        onChanged: (value) {
          setState(() => widget.controller.text = value ?? '');
          widget.onChanged();
        },
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

final class _SpeciesTableCell extends StatelessWidget {
  const _SpeciesTableCell({
    required this.row,
    required this.onPressed,
    required this.onCleared,
  });

  final _TaxationRowData row;
  final VoidCallback onPressed;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final species = row.speciesController.text.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: SizedBox(
        height: 48,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  species.isEmpty ? 'Выбрать' : species,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: species.isEmpty
                      ? theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )
                      : theme.textTheme.bodyMedium,
                ),
              ),
              if (species.isNotEmpty)
                IconButton(
                  tooltip: 'Очистить',
                  onPressed: onCleared,
                  icon: const Icon(Icons.close, size: 18),
                  visualDensity: VisualDensity.compact,
                )
              else
                Icon(
                  Icons.arrow_drop_down,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _TableTextField extends StatelessWidget {
  const _TableTextField({
    required this.controller,
    required this.onFocusLost,
    this.isNumber = false,
    this.isDecimal = false,
  });

  final TextEditingController controller;
  final VoidCallback onFocusLost;
  final bool isNumber;
  final bool isDecimal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus) {
            onFocusLost();
          }
        },
        child: TextField(
          controller: controller,
          keyboardType: isNumber || isDecimal
              ? TextInputType.numberWithOptions(decimal: isDecimal)
              : TextInputType.text,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
        ),
      ),
    );
  }
}

final class _TaxationRowData {
  _TaxationRowData({
    String tier = '',
    String composition = '',
    String species = '',
    String height = '',
    String diameter = '',
    String age = '',
    String origin = '',
    String merchantabilityClass = '',
  }) : tierController = TextEditingController(text: tier),
       compositionController = TextEditingController(text: composition),
       speciesController = TextEditingController(text: species),
       heightController = TextEditingController(text: height),
       diameterController = TextEditingController(text: diameter),
       ageController = TextEditingController(text: age),
       originController = TextEditingController(text: origin),
       merchantabilityClassController = TextEditingController(
         text: merchantabilityClass,
       );

  factory _TaxationRowData.empty() => _TaxationRowData();

  factory _TaxationRowData.fromRecord(TaxationCharacteristicRecord record) {
    return _TaxationRowData(
      tier: record.tier ?? '',
      composition: record.compositionCoefficient,
      species: record.species,
      height: record.averageHeight,
      diameter: record.diameter,
      age: record.age,
      origin: record.origin,
      merchantabilityClass: record.merchantabilityClass ?? '',
    );
  }

  final TextEditingController tierController;
  final TextEditingController compositionController;
  final TextEditingController speciesController;
  final TextEditingController heightController;
  final TextEditingController diameterController;
  final TextEditingController ageController;
  final TextEditingController originController;
  final TextEditingController merchantabilityClassController;

  bool get isEmpty {
    return [
      tierController,
      compositionController,
      speciesController,
      heightController,
      diameterController,
      ageController,
      originController,
      merchantabilityClassController,
    ].every((controller) => controller.text.trim().isEmpty);
  }

  String get signature {
    return [
      tierController,
      compositionController,
      speciesController,
      heightController,
      diameterController,
      ageController,
      originController,
      merchantabilityClassController,
    ].map((controller) => controller.text.trim()).join('\u001f');
  }

  TaxationCharacteristicRecord toRecord({required int probaInfoId}) {
    return TaxationCharacteristicRecord(
      probaInfoId: probaInfoId,
      tier: tierController.text.trim(),
      compositionCoefficient: compositionController.text.trim(),
      species: speciesController.text.trim(),
      averageHeight: heightController.text.trim(),
      diameter: diameterController.text.trim(),
      age: ageController.text.trim(),
      origin: originController.text.trim(),
      merchantabilityClass: merchantabilityClassController.text.trim(),
    );
  }

  void dispose() {
    tierController.dispose();
    compositionController.dispose();
    speciesController.dispose();
    heightController.dispose();
    diameterController.dispose();
    ageController.dispose();
    originController.dispose();
    merchantabilityClassController.dispose();
  }
}
