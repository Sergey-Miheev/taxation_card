import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxation_card/core/widgets/diameter_picker.dart';
import 'package:taxation_card/core/widgets/species_picker_dialog.dart';
import 'package:taxation_card/features/di/widget/dependencies_scope.dart';
import 'package:taxation_card/features/home/bloc/main_tabs_bloc.dart';
import 'package:taxation_card/features/permanent_PP/bloc/permanent_pp_bloc.dart';
import 'package:taxation_card/features/permanent_PP/domain/tree_information_repository.dart';

final class PermanentPpScreen extends StatefulWidget {
  const PermanentPpScreen({super.key});

  @override
  State<PermanentPpScreen> createState() => _PermanentPpScreenState();
}

final class _HighlightedRecordRow extends StatelessWidget {
  const _HighlightedRecordRow({
    required this.text,
    required this.onDeletePressed,
  });

  final String text;
  final VoidCallback? onDeletePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(12);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: borderRadius,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Row(
          children: [
            ColoredBox(
              color: theme.colorScheme.primary,
              child: const SizedBox(width: 5, height: 52),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Удалить',
              onPressed: onDeletePressed,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

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
          label: 'Диаметр 1',
          value: selections.isEmpty ? null : selections[0],
        ),
        _DiameterPurposeChip(
          color: Colors.blue.shade600,
          label: 'Диаметр 2',
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
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          selection == null ? label : '$label: ${_formatValue(selection)} см',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white,
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

final class _PermanentPpScreenState extends State<PermanentPpScreen>
    with AutomaticKeepAliveClientMixin {
  static const _woodQualityOptions = [
    'Деловая',
    'Полуделовая',
    'Дровянная',
    'Сух 1',
    'Сух 2',
    'Сух 3',
    'Сух 4',
  ];

  final _formKey = GlobalKey<FormState>();
  final _treeNumberController = TextEditingController();
  final _treeAgeController = TextEditingController();
  final _treeHeightController = TextEditingController();

  String? _selectedWoodQuality = 'Деловая';
  String? _selectedDynamicElement;
  final List<DiameterPickerSelection> _selectedDiameters = [];
  int? _activeDiameterIndex;
  int? _loadedProbaInfoId;
  var _isSavePending = false;

  @override
  void dispose() {
    _treeNumberController.dispose();
    _treeAgeController.dispose();
    _treeHeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final selectedProbaInfoId = context.select<MainTabsBloc, int?>(
      (bloc) => bloc.state.selectedProbaInfoId,
    );
    final speciesOptionsController = DependenciesScope.of(
      context,
    ).speciesOptionsController;
    _loadRecordsIfNeeded(selectedProbaInfoId);

    return BlocListener<PermanentPpBloc, PermanentPpState>(
      listener: (context, state) {
        switch (state.status) {
          case PermanentPpStatus.success:
            if (_isSavePending) {
              _clearSavedRecordSelection();
            }
            _showTopSnackBar(
              context,
              state.message ?? 'Данные сохранены.',
              duration: const Duration(milliseconds: 700),
            );
          case PermanentPpStatus.failure:
            _isSavePending = false;
            _showTopSnackBar(
              context,
              state.message ?? 'Не удалось выполнить действие.',
            );
          case PermanentPpStatus.idle:
          case PermanentPpStatus.loading:
            break;
        }
      },
      child: Scaffold(
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: BlocBuilder<PermanentPpBloc, PermanentPpState>(
              builder: (context, state) {
                final isLoading = state.isLoading;

                return FilledButton(
                  onPressed: isLoading ? null : _onSavePressed,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _woodQualityOptions.map((quality) {
                      final isSelected = _selectedWoodQuality == quality;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(quality),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedWoodQuality = quality);
                            }
                          },
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                FormField<String>(
                  validator: (_) {
                    final species = _selectedDynamicElement?.trim();
                    if (species == null || species.isEmpty) {
                      return 'Выберите породу';
                    }
                    return null;
                  },
                  builder: (field) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ValueListenableBuilder<List<String>>(
                            valueListenable: speciesOptionsController,
                            builder: (context, speciesOptions, _) {
                              return Row(
                                children: [
                                  ...speciesOptions.map((element) {
                                    final isSelected =
                                        _selectedDynamicElement == element;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: InputChip(
                                        label: Text(element),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          final value = selected
                                              ? element
                                              : null;
                                          setState(() {
                                            _selectedDynamicElement = value;
                                          });
                                          field.didChange(value);
                                        },
                                        showCheckmark: false,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        backgroundColor: Colors.transparent,
                                        selectedColor: theme
                                            .colorScheme
                                            .secondaryContainer,
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
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          height: 28,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8, left: 12),
                            child: field.hasError
                                ? Text(
                                    field.errorText!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.error,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Text('Выберите диаметр', style: theme.textTheme.labelLarge),
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
                  controller: _treeNumberController,
                  labelText: 'Номер дерева',
                  optional: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        controller: _treeAgeController,
                        labelText: 'Возраст дерева, лет',
                        optional: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildNumberField(
                        controller: _treeHeightController,
                        labelText: 'Высота дерева, м',
                        allowDecimal: true,
                        optional: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                BlocBuilder<PermanentPpBloc, PermanentPpState>(
                  builder: (context, state) {
                    return _buildRecords(
                      context: context,
                      records: state.records,
                      selectedProbaInfoId: selectedProbaInfoId,
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  void _showTopSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
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

  Widget _buildRecords({
    required BuildContext context,
    required List<TreeInformationRecord> records,
    required int? selectedProbaInfoId,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Все записи', style: theme.textTheme.titleMedium),
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
              child: _HighlightedRecordRow(
                text:
                    '${_formatRecordTitle(record)} • ${_formatRecordSubtitle(record)}',
                onDeletePressed: record.id == null
                    ? null
                    : () => _onDeleteRecord(record, selectedProbaInfoId),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _onDeleteRecord(
    TreeInformationRecord record,
    int selectedProbaInfoId,
  ) async {
    final id = record.id;
    if (id == null) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить запись?'),
          content: Text(
            '${_formatRecordTitle(record)}\n${_formatRecordSubtitle(record)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    context.read<PermanentPpBloc>().add(
      PermanentPpEvent.deleted(id: id, probaInfoId: selectedProbaInfoId),
    );
  }

  void _loadRecordsIfNeeded(int? selectedProbaInfoId) {
    if (_loadedProbaInfoId == selectedProbaInfoId) {
      return;
    }

    _loadedProbaInfoId = selectedProbaInfoId;
    _selectedDynamicElement = null;
    unawaited(
      DependenciesScope.of(
        context,
      ).speciesOptionsController.loadForProbaInfo(selectedProbaInfoId),
    );
    if (selectedProbaInfoId == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<PermanentPpBloc>().add(
        PermanentPpEvent.loaded(selectedProbaInfoId),
      );
    });
  }

  String _formatRecordTitle(TreeInformationRecord record) {
    final species = record.species?.trim();
    final woodQuality = record.woodQuality?.trim();
    final treeNumber = record.treeNumber;

    if (treeNumber != null && species != null && species.isNotEmpty) {
      return 'Дерево №$treeNumber • $species';
    }
    if (treeNumber != null) {
      return 'Дерево №$treeNumber';
    }
    if (woodQuality != null && woodQuality.isNotEmpty) {
      return woodQuality;
    }

    return 'Дерево №${record.treeNumber ?? '-'}';
  }

  String _formatRecordSubtitle(TreeInformationRecord record) {
    final parts = <String>[
      if (record.treeNumber != null) '№ дерева: ${record.treeNumber}',
      'D1: ${_formatDiameterValue(record.d1)}',
      'D2: ${_formatDiameterValue(record.d2)}',
      if (record.rightColumnNumber != null) 'ряд: ${record.rightColumnNumber}',
      if (record.treeAge != null) 'возраст: ${record.treeAge}',
      if (record.treeHeight != null) 'высота: ${record.treeHeight}',
    ];

    return parts.join(' • ');
  }

  String _formatDiameterValue(double value) {
    return value.toStringAsFixed(1).replaceAll('.', ',');
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
  }

  void _onMillimeterSelected(int number) {
    final activeIndex = _activeDiameterIndex;
    if (activeIndex == null || activeIndex >= _selectedDiameters.length) {
      return;
    }

    final activeSelection = _selectedDiameters[activeIndex];
    setState(() {
      _selectedDiameters[activeIndex] = DiameterPickerSelection(
        diameter: activeSelection.diameter,
        millimeter: number,
        isManual: activeSelection.isManual,
      );
    });
  }

  void _onManualDiameterSubmitted(DiameterPickerSelection selection) {
    setState(() {
      _selectedDiameters.add(selection);
      _activeDiameterIndex = _selectedDiameters.length - 1;
    });
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
  }

  Future<void> _onSavePressed() async {
    if (_selectedDynamicElement?.trim().isEmpty ?? true) {
      await _showSpeciesDialog();
      if (!mounted) {
        return;
      }
    }

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
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

    if (_selectedDiameters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите значение диаметра.')),
      );
      return;
    }

    final record = TreeInformationRecord(
      probaInfoId: selectedProbaInfoId,
      treeNumber: _parseOptionalInt(_treeNumberController.text),
      woodQuality: _selectedWoodQuality,
      species: _selectedDynamicElement,
      d1: _selectedDiameters[0].value,
      d2: _selectedDiameters.length > 1 ? _selectedDiameters[1].value : 0,
      treeAge: _parseOptionalInt(_treeAgeController.text),
      treeHeight: _parseOptionalDouble(_treeHeightController.text),
    );

    FocusManager.instance.primaryFocus?.unfocus();
    _isSavePending = true;
    context.read<PermanentPpBloc>().add(PermanentPpEvent.sentInfo(record));
  }

  void _clearSavedRecordSelection() {
    _isSavePending = false;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selectedWoodQuality = 'Деловая';
      _selectedDynamicElement = null;
      _selectedDiameters.clear();
      _activeDiameterIndex = null;
      _treeNumberController.clear();
      _treeAgeController.clear();
      _treeHeightController.clear();
    });
  }

  int? _parseOptionalInt(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return int.parse(trimmed);
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
      selectedSpecies: _selectedDynamicElement,
    );

    if (result != null && mounted) {
      DependenciesScope.of(context).speciesOptionsController.add(result);
      setState(() {
        _selectedDynamicElement = result;
      });
      _formKey.currentState?.validate();
    }
  }
}
