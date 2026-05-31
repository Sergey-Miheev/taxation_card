import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxation_card/core/widgets/diameter_picker.dart';
import 'package:taxation_card/core/widgets/species_picker_dialog.dart';
import 'package:taxation_card/features/di/widget/dependencies_scope.dart';
import 'package:taxation_card/features/home/bloc/main_tabs_bloc.dart';
import 'package:taxation_card/features/stumps/bloc/stumps_bloc.dart';
import 'package:taxation_card/features/stumps/domain/stumps_repository.dart';

final class _DiameterPurposeLabel extends StatelessWidget {
  const _DiameterPurposeLabel({required this.selections});

  final List<DiameterPickerSelection> selections;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _DiameterPurposeChip(
          color: Colors.green.shade600,
          label: '1: на высоте пня',
          value: selections.isEmpty ? null : selections[0],
        ),
        _DiameterPurposeChip(
          color: Colors.blue.shade600,
          label: '2: на высоте шейки корня',
          value: selections.length < 2 ? null : selections[1],
        ),
      ],
    );
  }
}

final class _DiameterPurposeChip extends StatelessWidget {
  const _DiameterPurposeChip({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final DiameterPickerSelection? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selection = value;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: selection == null ? 0.12 : 1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          selection == null ? label : '$label: ${_formatValue(selection)} см',
          style: theme.textTheme.bodySmall?.copyWith(
            color: selection == null
                ? theme.colorScheme.onSurface
                : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static String _formatValue(DiameterPickerSelection selection) {
    return selection.value.toStringAsFixed(1).replaceAll('.', ',');
  }
}

final class StumpsScreen extends StatefulWidget {
  const StumpsScreen({super.key});

  @override
  State<StumpsScreen> createState() => _StumpsScreenState();
}

final class _StumpsScreenState extends State<StumpsScreen>
    with AutomaticKeepAliveClientMixin {
  static const _decayStageOptions = [
    'Начальная',
    'Слабая',
    'Средняя',
    'Сильная',
    'Полная',
  ];

  final _formKey = GlobalKey<FormState>();
  final _stumpHeightController = TextEditingController();
  final _rotSizeController = TextEditingController();
  final _rotLengthController = TextEditingController();
  final List<String> _dynamicElements = [];
  final List<DiameterPickerSelection> _selectedDiameters = [];

  String? _selectedSpecies;
  String? _selectedDecayStage = _decayStageOptions.first;
  int? _activeDiameterIndex;
  int? _loadedProbaInfoId;
  double? _stumpsAccountingArea;
  final Set<int> _promptedStumpsAccountingAreaIds = {};

  @override
  void initState() {
    super.initState();
    _stumpHeightController.addListener(_onStumpHeightChanged);
    _rotSizeController.addListener(_onRotSizeChanged);
    _rotLengthController.addListener(_onRotLengthChanged);
    context.read<StumpsBloc>().add(
      StumpsEvent.decayClassChanged(_decayStageOptions.first),
    );
  }

  @override
  void dispose() {
    _stumpHeightController
      ..removeListener(_onStumpHeightChanged)
      ..dispose();
    _rotSizeController
      ..removeListener(_onRotSizeChanged)
      ..dispose();
    _rotLengthController
      ..removeListener(_onRotLengthChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final selectedProbaInfoId = context.select<MainTabsBloc, int?>(
      (bloc) => bloc.state.selectedProbaInfoId,
    );
    _loadRecordsIfNeeded(selectedProbaInfoId);

    return BlocListener<StumpsBloc, StumpsState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == StumpsStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'Данные по пням сохранены.'),
            ),
          );
        }
        if (state.status == StumpsStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'Не удалось выполнить действие.'),
            ),
          );
        }
      },
      child: Scaffold(
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: BlocBuilder<StumpsBloc, StumpsState>(
              builder: (context, state) {
                final isLoading = state.status == StumpsStatus.loading;

                return FilledButton(
                  onPressed: isLoading ? null : _onSavePressed,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Сохранить'),
                );
              },
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAreaInfo(
                  context: context,
                  label: 'Площадь учёта пней',
                  value: _stumpsAccountingArea,
                ),
                const SizedBox(height: 16),
                Text('Порода', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ..._dynamicElements.map((element) {
                        final isSelected = _selectedSpecies == element;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: Text(element),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedSpecies = selected ? element : null;
                              });
                              context.read<StumpsBloc>().add(
                                StumpsEvent.speciesChanged(_selectedSpecies),
                              );
                            },
                            onDeleted: () {
                              setState(() {
                                _dynamicElements.remove(element);
                                if (_selectedSpecies == element) {
                                  _selectedSpecies = null;
                                }
                              });
                              context.read<StumpsBloc>().add(
                                StumpsEvent.speciesChanged(_selectedSpecies),
                              );
                            },
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: theme
                                .colorScheme
                                .secondaryContainer
                                .withValues(alpha: 0.5),
                          ),
                        );
                      }),
                      IconButton.filledTonal(
                        onPressed: _showSpeciesDialog,
                        icon: const Icon(Icons.add, size: 20),
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Диаметр пня', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                _DiameterPurposeLabel(selections: _selectedDiameters),
                const SizedBox(height: 8),
                DiameterPicker(
                  selections: _selectedDiameters,
                  activeSelectionIndex: _activeDiameterIndex,
                  onDiameterSelected: _onDiameterSelected,
                  onMillimeterSelected: _onMillimeterSelected,
                  onManualSelectionSubmitted: _onManualDiameterSubmitted,
                  onSelectionRemoved: _onDiameterRemoved,
                ),
                const SizedBox(height: 16),
                _buildNumberField(
                  controller: _stumpHeightController,
                  labelText: 'Высота пня',
                  allowDecimal: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        controller: _rotSizeController,
                        labelText: 'Размер гнили, см',
                        allowDecimal: true,
                        optional: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildNumberField(
                        controller: _rotLengthController,
                        labelText: 'Длина гнили, м',
                        allowDecimal: true,
                        optional: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDecayStage,
                  decoration: _inputDecoration(
                    labelText: 'Стадия разложения КДО',
                  ),
                  items: _decayStageOptions
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _selectedDecayStage = value);
                    context.read<StumpsBloc>().add(
                      StumpsEvent.decayClassChanged(value),
                    );
                  },
                  validator: (value) =>
                      value == null ? 'Выберите значение' : null,
                ),
                const SizedBox(height: 24),
                BlocBuilder<StumpsBloc, StumpsState>(
                  builder: (context, state) {
                    return _buildRecentRecords(
                      context: context,
                      records: state.records,
                      selectedProbaInfoId: selectedProbaInfoId,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildAreaInfo({
    required BuildContext context,
    required String label,
    required double? value,
  }) {
    final theme = Theme.of(context);
    final valueText = value == null || value <= 0
        ? 'не указана'
        : _formatNumber(value);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
            Text(
              valueText,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRecords({
    required BuildContext context,
    required List<StumpRecord> records,
    required int? selectedProbaInfoId,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Список пней', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (selectedProbaInfoId == null)
          Text(
            'Сначала выберите пробную площадь.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else if (records.isEmpty)
          Text(
            'Записей пока нет.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...records.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                  title: Text(
                    _formatRecordTitle(record),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    _formatRecordSubtitle(record),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: 'Удалить запись',
                    onPressed: record.id == null
                        ? null
                        : () => _onDeleteRecord(record, selectedProbaInfoId),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  TextFormField _buildNumberField({
    required TextEditingController controller,
    required String labelText,
    bool allowDecimal = false,
    bool optional = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      textInputAction: TextInputAction.next,
      decoration: _inputDecoration(labelText: labelText),
      validator: (value) => _validatePositiveNumber(
        value,
        allowDecimal: allowDecimal,
        optional: optional,
      ),
    );
  }

  InputDecoration _inputDecoration({required String labelText}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }

  String? _validatePositiveNumber(
    String? value, {
    required bool allowDecimal,
    bool optional = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      return optional ? null : 'Заполните поле';
    }

    final normalized = value.replaceAll(',', '.').trim();
    final parsedValue = allowDecimal
        ? double.tryParse(normalized)
        : int.tryParse(normalized);

    if (parsedValue == null) {
      return 'Введите корректное число';
    }

    if (parsedValue <= 0) {
      return 'Значение должно быть больше 0';
    }

    return null;
  }

  void _loadRecordsIfNeeded(int? selectedProbaInfoId) {
    if (_loadedProbaInfoId == selectedProbaInfoId) {
      return;
    }

    _loadedProbaInfoId = selectedProbaInfoId;
    if (selectedProbaInfoId == null) {
      _stumpsAccountingArea = null;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<StumpsBloc>().add(StumpsEvent.loaded(selectedProbaInfoId));
      unawaited(_showStumpsAccountingAreaDialogIfNeeded(selectedProbaInfoId));
    });
  }

  Future<void> _showStumpsAccountingAreaDialogIfNeeded(int probaInfoId) async {
    if (_promptedStumpsAccountingAreaIds.contains(probaInfoId)) {
      return;
    }

    _promptedStumpsAccountingAreaIds.add(probaInfoId);
    final repository = DependenciesScope.of(context).probaInfoRepository;
    final probaInfo = await repository.getById(probaInfoId);
    if (mounted && _loadedProbaInfoId == probaInfoId) {
      setState(() => _stumpsAccountingArea = probaInfo?.stumpsAccountingArea);
    }

    if (!mounted ||
        probaInfo == null ||
        probaInfo.stumpsAccountingArea > 0 ||
        _loadedProbaInfoId != probaInfoId) {
      return;
    }

    final area = await _showStumpsAccountingAreaDialog();
    if (!mounted || area == null || _loadedProbaInfoId != probaInfoId) {
      return;
    }

    try {
      await repository.updateStumpsAccountingArea(id: probaInfoId, area: area);
      if (!mounted) {
        return;
      }

      setState(() => _stumpsAccountingArea = area);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Площадь учёта пней сохранена.')),
      );
    } on Object catch (_) {
      if (!mounted) {
        return;
      }

      _promptedStumpsAccountingAreaIds.remove(probaInfoId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось сохранить площадь учёта пней.'),
        ),
      );
    }
  }

  Future<double?> _showStumpsAccountingAreaDialog() {
    return showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _RequiredAreaDialog(
        title: 'Площадь учёта пней',
        labelText: 'Площадь учёта пней',
        validator: (value) =>
            _validatePositiveNumber(value, allowDecimal: true),
        parseValue: _parseRequiredDouble,
      ),
    );
  }

  void _onDiameterSelected(int number) {
    final selectedIndex = _selectedDiameters.indexWhere(
      (selection) => !selection.isManual && selection.diameter == number,
    );

    setState(() {
      if (selectedIndex != -1) {
        if (_activeDiameterIndex == selectedIndex) {
          _selectedDiameters.removeAt(selectedIndex);
          _activeDiameterIndex = _selectedDiameters.isEmpty
              ? null
              : selectedIndex.clamp(0, _selectedDiameters.length - 1);
        } else {
          _activeDiameterIndex = selectedIndex;
        }
        return;
      }

      if (_selectedDiameters.length < 2) {
        _selectedDiameters.add(DiameterPickerSelection(diameter: number));
        _activeDiameterIndex = _selectedDiameters.length - 1;
      }
    });
    _notifyDiametersChanged();
  }

  void _onMillimeterSelected(int number) {
    final activeIndex = _activeDiameterIndex;
    if (activeIndex == null || activeIndex >= _selectedDiameters.length) {
      return;
    }

    setState(() {
      final activeSelection = _selectedDiameters[activeIndex];
      _selectedDiameters[activeIndex] = DiameterPickerSelection(
        diameter: activeSelection.diameter,
        millimeter: number,
        isManual: activeSelection.isManual,
      );
    });
    _notifyDiametersChanged();
  }

  void _onManualDiameterSubmitted(DiameterPickerSelection selection) {
    setState(() {
      _selectedDiameters.add(selection);
      _activeDiameterIndex = _selectedDiameters.length - 1;
    });
    _notifyDiametersChanged();
  }

  void _onDiameterRemoved(int index) {
    if (index < 0 || index >= _selectedDiameters.length) {
      return;
    }

    setState(() {
      _selectedDiameters.removeAt(index);
      _activeDiameterIndex = _selectedDiameters.isEmpty
          ? null
          : index.clamp(0, _selectedDiameters.length - 1);
    });
    _notifyDiametersChanged();
  }

  void _notifyDiametersChanged() {
    final stumpHeightDiameter = _selectedDiameters.isEmpty
        ? null
        : _selectedDiameters[0];
    final rootCollarDiameter = _selectedDiameters.length < 2
        ? null
        : _selectedDiameters[1];

    context.read<StumpsBloc>().add(
      StumpsEvent.stumpHeightDiameterChanged(
        diameter: stumpHeightDiameter?.diameter,
        millimeter: stumpHeightDiameter?.millimeter,
      ),
    );
    context.read<StumpsBloc>().add(
      StumpsEvent.rootCollarDiameterChanged(
        diameter: rootCollarDiameter?.diameter,
        millimeter: rootCollarDiameter?.millimeter,
      ),
    );
  }

  void _onStumpHeightChanged() {
    context.read<StumpsBloc>().add(
      StumpsEvent.stumpHeightChanged(_stumpHeightController.text),
    );
  }

  void _onRotSizeChanged() {
    context.read<StumpsBloc>().add(
      StumpsEvent.rotSizeChanged(_rotSizeController.text),
    );
  }

  void _onRotLengthChanged() {
    context.read<StumpsBloc>().add(
      StumpsEvent.rotLengthChanged(_rotLengthController.text),
    );
  }

  void _onSavePressed() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedSpecies == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите породу.')));
      return;
    }

    if (_selectedDiameters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите диаметр пня на высоте пня.')),
      );
      return;
    }

    if (_selectedDiameters.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите диаметр пня на высоте шейки корня.'),
        ),
      );
      return;
    }

    final selectedProbaInfoId = context
        .read<MainTabsBloc>()
        .state
        .selectedProbaInfoId;
    if (selectedProbaInfoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала выберите пробную площадь.')),
      );
      return;
    }

    final record = StumpRecord(
      probaInfoId: selectedProbaInfoId,
      species: _selectedSpecies!,
      stumpHeight: _parseRequiredDouble(_stumpHeightController.text),
      stumpHeightDiameter: _selectedDiameters[0].diameter,
      stumpHeightMillimeter: _selectedDiameters[0].millimeter,
      rootCollarDiameter: _selectedDiameters[1].diameter,
      rootCollarMillimeter: _selectedDiameters[1].millimeter,
      rotSize: _parseOptionalDouble(_rotSizeController.text),
      rotLength: _parseOptionalDouble(_rotLengthController.text),
      decayStage: _selectedDecayStage!,
    );

    context.read<StumpsBloc>().add(StumpsEvent.saved(record));
  }

  void _onDeleteRecord(StumpRecord record, int? selectedProbaInfoId) {
    final id = record.id;
    if (id == null || selectedProbaInfoId == null) {
      return;
    }

    context.read<StumpsBloc>().add(
      StumpsEvent.deleted(id: id, probaInfoId: selectedProbaInfoId),
    );
  }

  String _formatRecordTitle(StumpRecord record) {
    return '${record.species} • высота: ${_formatNumber(record.stumpHeight)}';
  }

  String _formatRecordSubtitle(StumpRecord record) {
    final stumpHeightDiameter = _formatDiameter(
      record.stumpHeightDiameter,
      record.stumpHeightMillimeter,
    );
    final rootCollarDiameter = _formatDiameter(
      record.rootCollarDiameter,
      record.rootCollarMillimeter,
    );
    final parts = <String>[
      'ПП: ${record.probaInfoId}',
      'на высоте пня: $stumpHeightDiameter',
      'шейка корня: $rootCollarDiameter',
      if (record.rotSize != null) 'гниль: ${_formatNumber(record.rotSize!)} см',
      if (record.rotLength != null)
        'длина гнили: ${_formatNumber(record.rotLength!)} м',
      record.decayStage,
    ];

    return parts.join(' • ');
  }

  String _formatDiameter(int diameter, int? millimeter) {
    return millimeter == null ? '$diameter' : '$diameter, $millimeter мм';
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  double _parseRequiredDouble(String value) {
    return double.parse(value.trim().replaceAll(',', '.'));
  }

  double? _parseOptionalDouble(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return double.parse(trimmed.replaceAll(',', '.'));
  }

  Future<void> _showSpeciesDialog() async {
    final result = await showSpeciesPickerDialog(
      context: context,
      selectedSpecies: _selectedSpecies,
    );

    if (result != null && mounted) {
      setState(() {
        _dynamicElements
          ..clear()
          ..add(result);
        _selectedSpecies = result;
      });
      context.read<StumpsBloc>().add(StumpsEvent.speciesChanged(result));
    }
  }
}

final class _RequiredAreaDialog extends StatefulWidget {
  const _RequiredAreaDialog({
    required this.title,
    required this.labelText,
    required this.validator,
    required this.parseValue,
  });

  final String title;
  final String labelText;
  final FormFieldValidator<String> validator;
  final double Function(String value) parseValue;

  @override
  State<_RequiredAreaDialog> createState() => _RequiredAreaDialogState();
}

final class _RequiredAreaDialogState extends State<_RequiredAreaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(widget.title),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: widget.labelText,
              border: const OutlineInputBorder(),
            ),
            validator: widget.validator,
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              if (!(_formKey.currentState?.validate() ?? false)) {
                return;
              }

              Navigator.of(context).pop(widget.parseValue(_controller.text));
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}
