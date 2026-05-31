import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxation_card/core/widgets/diameter_picker.dart';
import 'package:taxation_card/core/widgets/species_picker_dialog.dart';
import 'package:taxation_card/features/deadwood/bloc/deadwood_bloc.dart';
import 'package:taxation_card/features/deadwood/domain/deadwood_repository.dart';
import 'package:taxation_card/features/di/widget/dependencies_scope.dart';
import 'package:taxation_card/features/home/bloc/main_tabs_bloc.dart';

final class DeadwoodScreen extends StatefulWidget {
  const DeadwoodScreen({super.key});

  @override
  State<DeadwoodScreen> createState() => _DeadwoodScreenState();
}

final class _DeadwoodScreenState extends State<DeadwoodScreen>
    with AutomaticKeepAliveClientMixin {
  static const _decayStageOptions = [
    'Начальная',
    'Слабая',
    'Средняя',
    'Сильная',
    'Полная',
  ];

  final _formKey = GlobalKey<FormState>();
  final _lengthController = TextEditingController();
  final _rotSizeController = TextEditingController();
  final _rotLengthController = TextEditingController();
  final List<String> _dynamicElements = [];

  String? _selectedSpecies;
  String? _selectedDecayStage = _decayStageOptions.first;
  int? _selectedDiameterNumber;
  int? _selectedMillimeterNumber;
  bool _isSelectedDiameterManual = false;
  int? _loadedProbaInfoId;
  double? _deadwoodArea;
  final Set<int> _promptedDeadwoodAreaIds = {};

  @override
  void initState() {
    super.initState();
    _lengthController.addListener(_onLengthChanged);
    _rotSizeController.addListener(_onRotSizeChanged);
    _rotLengthController.addListener(_onRotLengthChanged);
    context.read<DeadwoodBloc>().add(
      DeadwoodEvent.decayClassChanged(_decayStageOptions.first),
    );
  }

  @override
  void dispose() {
    _lengthController
      ..removeListener(_onLengthChanged)
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

    return BlocListener<DeadwoodBloc, DeadwoodState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == DeadwoodStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'Данные по валёжнику сохранены.'),
            ),
          );
        }
        if (state.status == DeadwoodStatus.failure) {
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
            child: BlocBuilder<DeadwoodBloc, DeadwoodState>(
              builder: (context, state) {
                final isLoading = state.status == DeadwoodStatus.loading;

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
                  label: 'Площадь учёта валёжника',
                  value: _deadwoodArea,
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
                              context.read<DeadwoodBloc>().add(
                                DeadwoodEvent.speciesChanged(_selectedSpecies),
                              );
                            },
                            onDeleted: () {
                              setState(() {
                                _dynamicElements.remove(element);
                                if (_selectedSpecies == element) {
                                  _selectedSpecies = null;
                                }
                              });
                              context.read<DeadwoodBloc>().add(
                                DeadwoodEvent.speciesChanged(_selectedSpecies),
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
                _buildNumberField(
                  controller: _lengthController,
                  labelText: 'Длина, м',
                  allowDecimal: true,
                ),
                const SizedBox(height: 16),
                Text('Средний диаметр', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                DiameterPicker(
                  selections: _selectedDiameterNumber == null
                      ? const []
                      : [
                          DiameterPickerSelection(
                            diameter: _selectedDiameterNumber!,
                            millimeter: _selectedMillimeterNumber ?? 0,
                            isManual: _isSelectedDiameterManual,
                          ),
                        ],
                  onDiameterSelected: _toggleDiameterNumber,
                  onMillimeterSelected: (number) {
                    setState(() {
                      _selectedMillimeterNumber = number;
                    });
                    _notifyDiameterChanged();
                  },
                  onManualSelectionSubmitted: (selection) {
                    setState(() {
                      _selectedDiameterNumber = selection.diameter;
                      _selectedMillimeterNumber = selection.millimeter;
                      _isSelectedDiameterManual = true;
                    });
                    _notifyDiameterChanged();
                  },
                  onSelectionRemoved: (_) {
                    setState(() {
                      _selectedDiameterNumber = null;
                      _selectedMillimeterNumber = null;
                      _isSelectedDiameterManual = false;
                    });
                    _notifyDiameterChanged();
                  },
                  maxSelections: 1,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        controller: _rotSizeController,
                        labelText: 'Размер гнили',
                        allowDecimal: true,
                        optional: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildNumberField(
                        controller: _rotLengthController,
                        labelText: 'Длина гнили',
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
                    context.read<DeadwoodBloc>().add(
                      DeadwoodEvent.decayClassChanged(value),
                    );
                  },
                  validator: (value) =>
                      value == null ? 'Выберите значение' : null,
                ),
                const SizedBox(height: 24),
                BlocBuilder<DeadwoodBloc, DeadwoodState>(
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
    required List<DeadwoodRecord> records,
    required int? selectedProbaInfoId,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Последние записи', style: theme.textTheme.titleMedium),
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
      _deadwoodArea = null;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<DeadwoodBloc>().add(
        DeadwoodEvent.loaded(selectedProbaInfoId),
      );
      unawaited(_showDeadwoodAreaDialogIfNeeded(selectedProbaInfoId));
    });
  }

  Future<void> _showDeadwoodAreaDialogIfNeeded(int probaInfoId) async {
    if (_promptedDeadwoodAreaIds.contains(probaInfoId)) {
      return;
    }

    _promptedDeadwoodAreaIds.add(probaInfoId);
    final repository = DependenciesScope.of(context).probaInfoRepository;
    final probaInfo = await repository.getById(probaInfoId);
    if (mounted && _loadedProbaInfoId == probaInfoId) {
      setState(() => _deadwoodArea = probaInfo?.deadwoodArea);
    }

    if (!mounted ||
        probaInfo == null ||
        probaInfo.deadwoodArea > 0 ||
        _loadedProbaInfoId != probaInfoId) {
      return;
    }

    final area = await _showDeadwoodAreaDialog();
    if (!mounted || area == null || _loadedProbaInfoId != probaInfoId) {
      return;
    }

    try {
      await repository.updateDeadwoodArea(id: probaInfoId, area: area);
      if (!mounted) {
        return;
      }

      setState(() => _deadwoodArea = area);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Площадь учёта валёжника сохранена.')),
      );
    } on Object catch (_) {
      if (!mounted) {
        return;
      }

      _promptedDeadwoodAreaIds.remove(probaInfoId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось сохранить площадь учёта валёжника.'),
        ),
      );
    }
  }

  Future<double?> _showDeadwoodAreaDialog() {
    return showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _RequiredAreaDialog(
        title: 'Площадь учёта валёжника',
        labelText: 'Площадь учёта валёжника',
        validator: (value) =>
            _validatePositiveNumber(value, allowDecimal: true),
        parseValue: _parseRequiredDouble,
      ),
    );
  }

  void _toggleDiameterNumber(int number) {
    setState(() {
      _selectedDiameterNumber = _selectedDiameterNumber == number
          ? null
          : number;
      _isSelectedDiameterManual = false;
    });
    _notifyDiameterChanged();
  }

  void _notifyDiameterChanged() {
    context.read<DeadwoodBloc>().add(
      DeadwoodEvent.diameterChanged(
        diameter: _selectedDiameterNumber,
        millimeter: _selectedDiameterNumber == null
            ? null
            : _selectedMillimeterNumber ?? 0,
      ),
    );
  }

  void _onLengthChanged() {
    context.read<DeadwoodBloc>().add(
      DeadwoodEvent.lengthChanged(_lengthController.text),
    );
  }

  void _onRotSizeChanged() {
    context.read<DeadwoodBloc>().add(
      DeadwoodEvent.rotSizeChanged(_rotSizeController.text),
    );
  }

  void _onRotLengthChanged() {
    context.read<DeadwoodBloc>().add(
      DeadwoodEvent.rotLengthChanged(_rotLengthController.text),
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

    if (_selectedDiameterNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите значение диаметра.')),
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

    final record = DeadwoodRecord(
      probaInfoId: selectedProbaInfoId,
      species: _selectedSpecies!,
      length: _parseRequiredDouble(_lengthController.text),
      diameter: _selectedDiameterNumber!,
      millimeter: _selectedMillimeterNumber ?? 0,
      rotSize: _parseOptionalDouble(_rotSizeController.text),
      rotLength: _parseOptionalDouble(_rotLengthController.text),
      decayStage: _selectedDecayStage!,
    );

    context.read<DeadwoodBloc>().add(DeadwoodEvent.saved(record));
  }

  void _onDeleteRecord(DeadwoodRecord record, int? selectedProbaInfoId) {
    final id = record.id;
    if (id == null || selectedProbaInfoId == null) {
      return;
    }

    context.read<DeadwoodBloc>().add(
      DeadwoodEvent.deleted(id: id, probaInfoId: selectedProbaInfoId),
    );
  }

  String _formatRecordTitle(DeadwoodRecord record) {
    return '${record.species} • ${_formatNumber(record.length)} м';
  }

  String _formatRecordSubtitle(DeadwoodRecord record) {
    final millimeter = record.millimeter;
    final diameter = millimeter == null
        ? '${record.diameter}'
        : '${record.diameter}, $millimeter мм';
    final parts = <String>[
      'ПП: ${record.probaInfoId}',
      'диаметр: $diameter',
      if (record.rotSize != null) 'гниль: ${_formatNumber(record.rotSize!)}',
      if (record.rotLength != null)
        'длина гнили: ${_formatNumber(record.rotLength!)}',
      record.decayStage,
    ];

    return parts.join(' • ');
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
        if (!_dynamicElements.contains(result)) {
          _dynamicElements.add(result);
        }
        _selectedSpecies = result;
      });
      context.read<DeadwoodBloc>().add(DeadwoodEvent.speciesChanged(result));
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
