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

enum _CountEditMode { increment, decrement }

final class _UnderstoryScreenState extends State<UnderstoryScreen>
    with AutomaticKeepAliveClientMixin {
  final List<_UnderstoryTableRow> _rows = [];
  int? _selectedIndex;
  int? _loadedProbaInfoId;
  int? _plotCount;
  double? _totalPlotArea;
  _CountEditMode _countEditMode = _CountEditMode.increment;
  bool _isLoading = false;
  bool _showPlotSetup = false;

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
                const SizedBox(height: 8),
                _TotalPlotAreaLabel(
                  totalPlotArea: _totalPlotArea,
                  onEditPressed:
                      selectedProbaInfoId == null ||
                          _isLoading ||
                          _plotCount == null ||
                          _plotCount! <= 0 ||
                          _totalPlotArea == null ||
                          _totalPlotArea! <= 0
                      ? null
                      : () => _showPlotSetupDialog(selectedProbaInfoId),
                ),
                const SizedBox(height: 16),
                if (_isLoading) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                ],
                if (_showPlotSetup)
                  Expanded(
                    child: _UnderstoryPlotSetupForm(
                      isSaving: _isLoading,
                      onSave: (plotCount, singlePlotArea) => _savePlotSetup(
                        selectedProbaInfoId,
                        plotCount,
                        singlePlotArea,
                      ),
                    ),
                  )
                else ...[
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _ScrollableTableCard(
                            child: _UnderstoryEditableTable(
                              rows: _rows,
                              selectedIndex: _selectedIndex,
                              editMode: _countEditMode,
                              onRowSelected: (index) {
                                setState(() => _selectedIndex = index);
                              },
                              onRowChanged: _updateRow,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: _CountModeButtons(
                            selectedMode: _countEditMode,
                            onModeChanged: (mode) {
                              setState(() => _countEditMode = mode);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (!_showPlotSetup)
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
                          : () => _openAddDialog(selectedProbaInfoId),
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить запись'),
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
                      label: const Text('Удалить запись'),
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

  void _showTopSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          left: 16,
          top: MediaQuery.paddingOf(context).top + 16,
          right: 16,
          bottom: MediaQuery.sizeOf(context).height - 148,
        ),
        duration: duration,
      ),
    );
  }

  Future<void> _openAddDialog(int probaInfoId) async {
    final plotCount = _plotCount;
    if (plotCount == null || plotCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сначала заполните количество учетных площадок.'),
        ),
      );
      return;
    }

    final draft = await showDialog<_UnderstoryRecordDraft>(
      context: context,
      builder: (context) => _UnderstoryRecordDialog(plotCount: plotCount),
    );
    if (draft == null) {
      return;
    }
    if (!mounted) {
      return;
    }

    final repository = DependenciesScope.of(context).understoryRepository;
    final row = _UnderstoryTableRow.fromDraft(
      probaInfoId: probaInfoId,
      draft: draft,
    );

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
    _showTopSnackBar('Запись подлеска добавлена.');
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
      _plotCount = null;
      _totalPlotArea = null;
      _isLoading = false;
      _showPlotSetup = false;
      return;
    }

    final repository = DependenciesScope.of(context).understoryRepository;
    _rows.clear();
    _isLoading = true;
    _showPlotSetup = false;

    unawaited(
      () async {
        final dependencies = DependenciesScope.of(context);
        final records = await repository.getByProbaInfoId(selectedProbaInfoId);
        final probaInfo = await dependencies.probaInfoRepository.getById(
          selectedProbaInfoId,
        );

        if (!mounted || _loadedProbaInfoId != selectedProbaInfoId) {
          return;
        }

        setState(() {
          _rows
            ..clear()
            ..addAll(records.map(_UnderstoryTableRow.fromRecord));
          _plotCount = probaInfo?.understoryPlotCount;
          _totalPlotArea = probaInfo?.understoryPlotArea;
          _showPlotSetup =
              records.isEmpty &&
              (probaInfo == null ||
                  probaInfo.understoryPlotCount <= 0 ||
                  probaInfo.understoryPlotArea <= 0);
          _isLoading = false;
        });
      }().catchError((Object _) {
        if (!mounted || _loadedProbaInfoId != selectedProbaInfoId) {
          return;
        }

        setState(() {
          _isLoading = false;
          _showPlotSetup = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось загрузить записи подлеска.'),
          ),
        );
      }),
    );
  }

  Future<void> _savePlotSetup(
    int? selectedProbaInfoId,
    int plotCount,
    double singlePlotArea,
  ) async {
    if (selectedProbaInfoId == null || _isLoading) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await DependenciesScope.of(
        context,
      ).probaInfoRepository.updateUnderstoryPlotInfo(
        id: selectedProbaInfoId,
        plotCount: plotCount,
        plotArea: plotCount * singlePlotArea,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _plotCount = plotCount;
        _totalPlotArea = plotCount * singlePlotArea;
        _showPlotSetup = false;
        _isLoading = false;
      });
    } on Object catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось сохранить параметры площадок подлеска.'),
        ),
      );
    }
  }

  Future<void> _showPlotSetupDialog(int selectedProbaInfoId) async {
    final plotCount = _plotCount;
    final totalPlotArea = _totalPlotArea;
    if (plotCount == null || plotCount <= 0 || totalPlotArea == null) {
      return;
    }

    final setup = await showDialog<_PlotSetupDraft>(
      context: context,
      builder: (context) => _PlotSetupDialog(
        title: 'Учетные площадки подлеска',
        initialPlotCount: plotCount,
        initialSinglePlotArea: totalPlotArea / plotCount,
      ),
    );

    if (setup != null && mounted) {
      await _savePlotSetup(
        selectedProbaInfoId,
        setup.plotCount,
        setup.singlePlotArea,
      );
    }
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

final class _PlotSetupDraft {
  const _PlotSetupDraft({
    required this.plotCount,
    required this.singlePlotArea,
  });

  final int plotCount;
  final double singlePlotArea;
}

final class _PlotSetupDialog extends StatefulWidget {
  const _PlotSetupDialog({
    required this.title,
    required this.initialPlotCount,
    required this.initialSinglePlotArea,
  });

  final String title;
  final int initialPlotCount;
  final double initialSinglePlotArea;

  @override
  State<_PlotSetupDialog> createState() => _PlotSetupDialogState();
}

final class _PlotSetupDialogState extends State<_PlotSetupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _plotCountController = TextEditingController();
  final _singlePlotAreaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _plotCountController.text = widget.initialPlotCount.toString();
    _singlePlotAreaController.text = _formatDouble(
      widget.initialSinglePlotArea,
    );
  }

  @override
  void dispose() {
    _plotCountController.dispose();
    _singlePlotAreaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _plotCountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Количество учетных площадок',
                border: OutlineInputBorder(),
              ),
              validator: _validatePositiveInt,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _singlePlotAreaController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Площадь одной учетной площадки, га',
                border: OutlineInputBorder(),
              ),
              validator: _validatePositiveNumber,
              onFieldSubmitted: (_) => _onSavePressed(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(onPressed: _onSavePressed, child: const Text('Сохранить')),
      ],
    );
  }

  void _onSavePressed() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop(
      _PlotSetupDraft(
        plotCount: int.parse(_plotCountController.text.trim()),
        singlePlotArea: double.parse(
          _normalizeNumber(_singlePlotAreaController.text),
        ),
      ),
    );
  }

  String? _validatePositiveInt(String? value) {
    final parsedValue = int.tryParse(value?.trim() ?? '');
    if (parsedValue == null) {
      return 'Введите целое число';
    }

    if (parsedValue <= 0) {
      return 'Значение должно быть больше 0';
    }

    return null;
  }

  String? _validatePositiveNumber(String? value) {
    final parsedValue = double.tryParse(_normalizeNumber(value ?? ''));
    if (parsedValue == null) {
      return 'Введите корректное число';
    }

    if (parsedValue <= 0) {
      return 'Значение должно быть больше 0';
    }

    return null;
  }

  String _normalizeNumber(String value) {
    return value.trim().replaceAll(',', '.');
  }

  String _formatDouble(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }
}

final class _UnderstoryPlotSetupForm extends StatefulWidget {
  const _UnderstoryPlotSetupForm({
    required this.isSaving,
    required this.onSave,
  });

  final bool isSaving;
  final void Function(int plotCount, double singlePlotArea) onSave;

  @override
  State<_UnderstoryPlotSetupForm> createState() =>
      _UnderstoryPlotSetupFormState();
}

final class _UnderstoryPlotSetupFormState
    extends State<_UnderstoryPlotSetupForm> {
  final _formKey = GlobalKey<FormState>();
  final _plotCountController = TextEditingController();
  final _singlePlotAreaController = TextEditingController();

  @override
  void dispose() {
    _plotCountController.dispose();
    _singlePlotAreaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Учетные площадки подлеска',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _plotCountController,
                    enabled: !widget.isSaving,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Количество учетных площадок',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validatePositiveInt,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _singlePlotAreaController,
                    enabled: !widget.isSaving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Площадь одной учетной площадки, га',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validatePositiveNumber,
                    onFieldSubmitted: (_) => _onSavePressed(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: widget.isSaving ? null : _onSavePressed,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: widget.isSaving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Сохранить'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSavePressed() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    widget.onSave(
      int.parse(_plotCountController.text.trim()),
      double.parse(_normalizeNumber(_singlePlotAreaController.text)),
    );
  }

  String? _validatePositiveInt(String? value) {
    final parsedValue = int.tryParse(value?.trim() ?? '');
    if (parsedValue == null) {
      return 'Введите целое число';
    }

    if (parsedValue <= 0) {
      return 'Значение должно быть больше 0';
    }

    return null;
  }

  String? _validatePositiveNumber(String? value) {
    final parsedValue = double.tryParse(_normalizeNumber(value ?? ''));
    if (parsedValue == null) {
      return 'Введите корректное число';
    }

    if (parsedValue <= 0) {
      return 'Значение должно быть больше 0';
    }

    return null;
  }

  String _normalizeNumber(String value) {
    return value.trim().replaceAll(',', '.');
  }
}

final class _TotalPlotAreaLabel extends StatelessWidget {
  const _TotalPlotAreaLabel({
    required this.totalPlotArea,
    required this.onEditPressed,
  });

  final double? totalPlotArea;
  final VoidCallback? onEditPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final area = totalPlotArea;
    final text = area == null
        ? 'Общая площадь подлеска: -, га'
        : 'Общая площадь подлеска: ${_formatDouble(area)}, га';

    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (onEditPressed != null)
          TextButton.icon(
            onPressed: onEditPressed,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Редактировать'),
          ),
      ],
    );
  }

  String _formatDouble(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }
}

final class _CountModeButtons extends StatelessWidget {
  const _CountModeButtons({
    required this.selectedMode,
    required this.onModeChanged,
  });

  final _CountEditMode selectedMode;
  final ValueChanged<_CountEditMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CountModeButton(
              icon: Icons.add,
              tooltip: 'Режим увеличения',
              isSelected: selectedMode == _CountEditMode.increment,
              onPressed: () => onModeChanged(_CountEditMode.increment),
            ),
            const SizedBox(width: 8),
            _CountModeButton(
              icon: Icons.remove,
              tooltip: 'Режим уменьшения',
              isSelected: selectedMode == _CountEditMode.decrement,
              onPressed: () => onModeChanged(_CountEditMode.decrement),
            ),
          ],
        ),
      ),
    );
  }
}

final class _CountModeButton extends StatelessWidget {
  const _CountModeButton({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return isSelected
        ? FloatingActionButton(
            heroTag: 'understory-$tooltip',
            tooltip: tooltip,
            onPressed: onPressed,
            child: Icon(icon),
          )
        : FloatingActionButton(
            heroTag: 'understory-$tooltip',
            tooltip: tooltip,
            onPressed: onPressed,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            child: Icon(icon),
          );
  }
}

final class _UnderstoryRecordDraft {
  const _UnderstoryRecordDraft({
    required this.plotNumber,
    required this.species,
    required this.modelAge,
    required this.modelDiameter,
    required this.modelHeight,
    required this.largeModelAge,
    required this.largeModelDiameter,
    required this.largeModelHeight,
  });

  final int plotNumber;
  final String species;
  final int modelAge;
  final double modelDiameter;
  final double modelHeight;
  final int largeModelAge;
  final double largeModelDiameter;
  final double largeModelHeight;
}

final class _UnderstoryRecordDialog extends StatefulWidget {
  const _UnderstoryRecordDialog({required this.plotCount});

  final int plotCount;

  @override
  State<_UnderstoryRecordDialog> createState() =>
      _UnderstoryRecordDialogState();
}

final class _UnderstoryRecordDialogState
    extends State<_UnderstoryRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _modelAgeController = TextEditingController(text: '0');
  final _modelDiameterController = TextEditingController(text: '0');
  final _modelHeightController = TextEditingController(text: '0');
  final _largeModelAgeController = TextEditingController(text: '0');
  final _largeModelDiameterController = TextEditingController(text: '0');
  final _largeModelHeightController = TextEditingController(text: '0');
  final _speciesController = TextEditingController();
  final _speciesFocusNode = FocusNode();

  int? _selectedPlotNumber;

  @override
  void dispose() {
    _modelAgeController.dispose();
    _modelDiameterController.dispose();
    _modelHeightController.dispose();
    _largeModelAgeController.dispose();
    _largeModelDiameterController.dispose();
    _largeModelHeightController.dispose();
    _speciesController.dispose();
    _speciesFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить запись подлеска'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _selectedPlotNumber,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Номер учетной площадки',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (var number = 1; number <= widget.plotCount; number++)
                      DropdownMenuItem<int>(
                        value: number,
                        child: Text(number.toString()),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedPlotNumber = value);
                  },
                  validator: (value) =>
                      value == null ? 'Выберите номер площадки' : null,
                ),
                const SizedBox(height: 12),
                RawAutocomplete<String>(
                  textEditingController: _speciesController,
                  focusNode: _speciesFocusNode,
                  displayStringForOption: (option) => option,
                  optionsBuilder: (textEditingValue) {
                    final query = textEditingValue.text.trim().toLowerCase();
                    if (query.isEmpty) {
                      return allSpecies;
                    }

                    return allSpecies.where(
                      (species) => species.toLowerCase().contains(query),
                    );
                  },
                  onSelected: (value) {
                    _speciesController.text = value;
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Порода',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Выберите породу'
                              : null,
                          onFieldSubmitted: (_) => onFieldSubmitted(),
                        );
                      },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 280,
                            maxWidth: 360,
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);

                              return InkWell(
                                onTap: () => onSelected(option),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Text(option),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Модельное дерево',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 460;
                    final children = [
                      _ModelTreeFields(
                        title: 'Мелкий подлесок',
                        ageController: _modelAgeController,
                        diameterController: _modelDiameterController,
                        heightController: _modelHeightController,
                      ),
                      _ModelTreeFields(
                        title: 'Крупный подлесок',
                        ageController: _largeModelAgeController,
                        diameterController: _largeModelDiameterController,
                        heightController: _largeModelHeightController,
                      ),
                    ];

                    if (!isWide) {
                      return Column(
                        children: [
                          children[0],
                          const SizedBox(height: 12),
                          children[1],
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: children[0]),
                        const SizedBox(width: 12),
                        Expanded(child: children[1]),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(onPressed: _onSavePressed, child: const Text('Сохранить')),
      ],
    );
  }

  void _onSavePressed() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop(
      _UnderstoryRecordDraft(
        plotNumber: _selectedPlotNumber!,
        species: _speciesController.text.trim(),
        modelAge: _tryParseInt(_modelAgeController.text),
        modelDiameter: _tryParseDouble(_modelDiameterController.text),
        modelHeight: _tryParseDouble(_modelHeightController.text),
        largeModelAge: _tryParseInt(_largeModelAgeController.text),
        largeModelDiameter: _tryParseDouble(_largeModelDiameterController.text),
        largeModelHeight: _tryParseDouble(_largeModelHeightController.text),
      ),
    );
  }

  int _tryParseInt(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }

  double _tryParseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }
}

final class _ModelTreeFields extends StatelessWidget {
  const _ModelTreeFields({
    required this.title,
    required this.ageController,
    required this.diameterController,
    required this.heightController,
  });

  final String title;
  final TextEditingController ageController;
  final TextEditingController diameterController;
  final TextEditingController heightController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        TextFormField(
          controller: ageController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Возраст, лет',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: diameterController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Диаметр',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: heightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Высота',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
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
    required this.editMode,
    required this.onRowSelected,
    required this.onRowChanged,
  });

  final List<_UnderstoryTableRow> rows;
  final int? selectedIndex;
  final _CountEditMode editMode;
  final ValueChanged<int> onRowSelected;
  final ValueChanged<_UnderstoryTableRow> onRowChanged;

  static const _borderColor = Color(0xFFE0E0E0);
  static const _rowHeight = 56.0;
  static const _plotNumberColumnWidth = 76.0;
  static const _speciesColumnWidth = 110.0;
  static const _countColumnWidth = 68.0;
  static const _smallGroupColumnCount = 4;
  static const _largeGroupColumnCount = 10;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(border: Border.all(color: _borderColor)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(theme),
          Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FixedColumnWidth(_plotNumberColumnWidth),
              1: FixedColumnWidth(_speciesColumnWidth),
              2: FixedColumnWidth(_countColumnWidth),
              3: FixedColumnWidth(_countColumnWidth),
              4: FixedColumnWidth(_countColumnWidth),
              5: FixedColumnWidth(_countColumnWidth),
              6: FixedColumnWidth(_countColumnWidth),
              7: FixedColumnWidth(_countColumnWidth),
              8: FixedColumnWidth(_countColumnWidth),
              9: FixedColumnWidth(_countColumnWidth),
              10: FixedColumnWidth(_countColumnWidth),
              11: FixedColumnWidth(_countColumnWidth),
              12: FixedColumnWidth(_countColumnWidth),
              13: FixedColumnWidth(_countColumnWidth),
              14: FixedColumnWidth(_countColumnWidth),
              15: FixedColumnWidth(_countColumnWidth),
            },
            children: [
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
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    const headerBackgroundColor = Color(0xFFF8F8F8);
    const topHeaderHeight = 56.0;
    const countHeaderHeight = 50.0;
    const heightGroupHeaderHeight = 42.0;
    const statusHeaderHeight = 36.0;
    const fullHeaderHeight =
        topHeaderHeight +
        countHeaderHeight +
        heightGroupHeaderHeight +
        statusHeaderHeight;
    const smallGroupWidth = _smallGroupColumnCount * _countColumnWidth;
    const largeGroupWidth = _largeGroupColumnCount * _countColumnWidth;
    const heightGroupWidth = 2 * _countColumnWidth;

    return ColoredBox(
      color: headerBackgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderBox(
            width: _plotNumberColumnWidth,
            height: fullHeaderHeight,
            text: '№\nуч.\nпл.',
            theme: theme,
          ),
          _HeaderBox(
            width: _speciesColumnWidth,
            height: fullHeaderHeight,
            text: 'Древесная\nпорода',
            theme: theme,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _HeaderBox(
                    width: smallGroupWidth,
                    height: topHeaderHeight,
                    text: 'Мелкий, средний подлесок',
                    theme: theme,
                  ),
                  _HeaderBox(
                    width: largeGroupWidth,
                    height: topHeaderHeight,
                    text: 'Крупный подлесок',
                    theme: theme,
                  ),
                ],
              ),
              Row(
                children: [
                  _HeaderBox(
                    width: smallGroupWidth,
                    height: countHeaderHeight,
                    text: 'количество по\nгруппам высот, шт.',
                    theme: theme,
                  ),
                  _HeaderBox(
                    width: largeGroupWidth,
                    height: countHeaderHeight,
                    text: 'количество по\nгруппам высот, шт.',
                    theme: theme,
                  ),
                ],
              ),
              Row(
                children: [
                  for (final title in const [
                    'до 0.5',
                    '0.51-1.5',
                    '1.51-2.5',
                    '2.51-3.5',
                    '3.51-4.5',
                    '4.51-5.5',
                    '5.51 и>',
                  ])
                    _HeaderBox(
                      width: heightGroupWidth,
                      height: heightGroupHeaderHeight,
                      text: title,
                      theme: theme,
                    ),
                ],
              ),
              Row(
                children: [
                  for (var index = 0; index < 7; index++) ...[
                    _HeaderBox(
                      width: _countColumnWidth,
                      height: statusHeaderHeight,
                      text: 'ж.',
                      theme: theme,
                    ),
                    _HeaderBox(
                      width: _countColumnWidth,
                      height: statusHeaderHeight,
                      text: 'пог.',
                      theme: theme,
                    ),
                  ],
                ],
              ),
            ],
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
        : index.isEven
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.34)
        : Colors.white;

    return TableRow(
      decoration: BoxDecoration(color: rowColor),
      children: [
        _ReadOnlyTableCell(
          text: row.plotNumber,
          onTap: () => onRowSelected(index),
        ),
        _ReadOnlyTableCell(
          text: row.species,
          onTap: () => onRowSelected(index),
        ),
        _CountTableCell(
          text: row.smallLiving,
          onTap: () => _changeCount(
            index: index,
            row: row,
            value: row.smallLiving,
            onChanged: (value) => row.smallLiving = value,
          ),
        ),
        _CountTableCell(
          text: row.smallDamaged,
          onTap: () => _changeCount(
            index: index,
            row: row,
            value: row.smallDamaged,
            onChanged: (value) => row.smallDamaged = value,
          ),
        ),
        _CountTableCell(
          text: row.mediumLiving,
          onTap: () => _changeCount(
            index: index,
            row: row,
            value: row.mediumLiving,
            onChanged: (value) => row.mediumLiving = value,
          ),
        ),
        _CountTableCell(
          text: row.mediumDamaged,
          onTap: () => _changeCount(
            index: index,
            row: row,
            value: row.mediumDamaged,
            onChanged: (value) => row.mediumDamaged = value,
          ),
        ),
        _CountTableCell(
          text: row.large15125Living,
          onTap: () => _changeCount(
            index: index,
            row: row,
            value: row.large15125Living,
            onChanged: (value) => row.large15125Living = value,
          ),
        ),
        _CountTableCell(
          text: row.large15125Damaged,
          onTap: () => _changeCount(
            index: index,
            row: row,
            value: row.large15125Damaged,
            onChanged: (value) => row.large15125Damaged = value,
          ),
        ),
        _CountTableCell(
          text: row.large25135Living,
          onTap: () => _changeCount(
            index: index,
            row: row,
            value: row.large25135Living,
            onChanged: (value) => row.large25135Living = value,
          ),
        ),
        _CountTableCell(
          text: row.large25135Damaged,
          onTap: () => _changeCount(
            index: index,
            row: row,
            value: row.large25135Damaged,
            onChanged: (value) => row.large25135Damaged = value,
          ),
        ),
        _CountTableCell(
          text: row.large35145Living,
          onTap: () => _changeCount(
            index: index,
            row: row,
            value: row.large35145Living,
            onChanged: (value) => row.large35145Living = value,
          ),
        ),
        _CountTableCell(
          text: row.large35145Damaged,
          onTap: () => _changeCount(
            index: index,
            row: row,
            value: row.large35145Damaged,
            onChanged: (value) => row.large35145Damaged = value,
          ),
        ),
        _CountTableCell(
          text: row.large45155Living,
          onTap: () => _changeCount(
            index: index,
            row: row,
            value: row.large45155Living,
            onChanged: (value) => row.large45155Living = value,
          ),
        ),
        _CountTableCell(
          text: row.large45155Damaged,
          onTap: () => _changeCount(
            index: index,
            row: row,
            value: row.large45155Damaged,
            onChanged: (value) => row.large45155Damaged = value,
          ),
        ),
        _CountTableCell(
          text: row.large551PlusLiving,
          onTap: () => _changeCount(
            index: index,
            row: row,
            value: row.large551PlusLiving,
            onChanged: (value) => row.large551PlusLiving = value,
          ),
        ),
        _CountTableCell(
          text: row.large551PlusDamaged,
          onTap: () => _changeCount(
            index: index,
            row: row,
            value: row.large551PlusDamaged,
            onChanged: (value) => row.large551PlusDamaged = value,
          ),
        ),
      ],
    );
  }

  void _changeCount({
    required int index,
    required _UnderstoryTableRow row,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    final currentValue = int.tryParse(value.trim()) ?? 0;
    final nextValue = switch (editMode) {
      _CountEditMode.increment => currentValue + 1,
      _CountEditMode.decrement => currentValue <= 0 ? 0 : currentValue - 1,
    };

    onChanged(nextValue.toString());
    onRowSelected(index);
    onRowChanged(row);
  }
}

final class _UnderstoryTableRow {
  _UnderstoryTableRow({
    required this.probaInfoId,
    required this.plotNumber,
    required this.species,
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

  factory _UnderstoryTableRow.fromDraft({
    required int probaInfoId,
    required _UnderstoryRecordDraft draft,
  }) {
    return _UnderstoryTableRow(
      probaInfoId: probaInfoId,
      plotNumber: draft.plotNumber.toString(),
      species: draft.species,
      smallLiving: '0',
      smallDamaged: '0',
      mediumLiving: '0',
      mediumDamaged: '0',
      modelAge: draft.modelAge.toString(),
      modelHeight: _formatDouble(draft.modelHeight),
      modelDiameter: _formatDouble(draft.modelDiameter),
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
      largeModelAge: draft.largeModelAge.toString(),
      largeModelHeight: _formatDouble(draft.largeModelHeight),
      largeModelDiameter: _formatDouble(draft.largeModelDiameter),
    );
  }

  factory _UnderstoryTableRow.fromRecord(UnderstoryRecord record) {
    return _UnderstoryTableRow(
      id: record.id,
      probaInfoId: record.probaInfoId,
      plotNumber: record.plotNumber.toString(),
      species: record.species ?? '',
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

final class _HeaderBox extends StatelessWidget {
  const _HeaderBox({
    required this.width,
    required this.height,
    required this.text,
    required this.theme,
  });

  final double width;
  final double height;
  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
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
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

final class _CountTableCell extends StatelessWidget {
  const _CountTableCell({required this.text, required this.onTap});

  final String text;
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
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
