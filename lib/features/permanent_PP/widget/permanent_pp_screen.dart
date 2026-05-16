import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxation_card/core/constants/constants.dart';
import 'package:taxation_card/core/widgets/diameter_picker.dart';
import 'package:taxation_card/features/home/bloc/main_tabs_bloc.dart';
import 'package:taxation_card/features/permanent_PP/bloc/permanent_pp_bloc.dart';
import 'package:taxation_card/features/permanent_PP/domain/tree_information_repository.dart';

final class PermanentPpScreen extends StatefulWidget {
  const PermanentPpScreen({super.key});

  @override
  State<PermanentPpScreen> createState() => _PermanentPpScreenState();
}

final class _PermanentPpScreenState extends State<PermanentPpScreen>
    with AutomaticKeepAliveClientMixin {
  static const _woodQualityOptions = ['Деловая', 'Полуделовая', 'Дровянная'];

  final _formKey = GlobalKey<FormState>();
  final _treeAgeController = TextEditingController();
  final _treeHeightController = TextEditingController();

  String? _selectedWoodQuality = 'Деловая';
  final List<String> _dynamicElements = [];
  String? _selectedDynamicElement;
  final List<DiameterPickerSelection> _selectedDiameters = [];
  int? _activeDiameterIndex;
  int? _loadedProbaInfoId;

  @override
  void dispose() {
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
    _loadRecordsIfNeeded(selectedProbaInfoId);

    return BlocListener<PermanentPpBloc, PermanentPpState>(
      listener: (context, state) {
        switch (state.status) {
          case PermanentPpStatus.success:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message ?? 'Данные сохранены.')),
            );
          case PermanentPpStatus.failure:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message ?? 'Не удалось выполнить действие.',
                ),
              ),
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
                          child: Row(
                            children: [
                              ..._dynamicElements.map((element) {
                                final isSelected =
                                    _selectedDynamicElement == element;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: InputChip(
                                    label: Text(element),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      final value = selected ? element : null;
                                      setState(() {
                                        _selectedDynamicElement = value;
                                      });
                                      field.didChange(value);
                                    },
                                    onDeleted: () {
                                      setState(() {
                                        _dynamicElements.remove(element);
                                        if (_selectedDynamicElement ==
                                            element) {
                                          _selectedDynamicElement = null;
                                        }
                                      });
                                      field.didChange(_selectedDynamicElement);
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
                        if (field.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 12),
                            child: Text(
                              field.errorText!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text('Выберите диаметр', style: theme.textTheme.labelLarge),
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
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        controller: _treeAgeController,
                        labelText: 'Возраст дерева',
                        optional: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildNumberField(
                        controller: _treeHeightController,
                        labelText: 'Высота дерева',
                        allowDecimal: true,
                        optional: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                BlocBuilder<PermanentPpBloc, PermanentPpState>(
                  builder: (context, state) {
                    return _buildRecentRecords(
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

  Widget _buildRecentRecords({
    required BuildContext context,
    required List<TreeInformationRecord> records,
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
          ...records
              .take(4)
              .map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
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
                            : () =>
                                  _onDeleteRecord(record, selectedProbaInfoId),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ),
                ),
              ),
      ],
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<PermanentPpBloc>().add(
        PermanentPpEvent.loaded(selectedProbaInfoId),
      );
    });
  }

  void _onDeleteRecord(TreeInformationRecord record, int selectedProbaInfoId) {
    final id = record.id;
    if (id == null) {
      return;
    }

    context.read<PermanentPpBloc>().add(
      PermanentPpEvent.deleted(id: id, probaInfoId: selectedProbaInfoId),
    );
  }

  String _formatRecordTitle(TreeInformationRecord record) {
    final species = record.species?.trim();
    final woodQuality = record.woodQuality?.trim();

    if (species != null && species.isNotEmpty) {
      return species;
    }
    if (woodQuality != null && woodQuality.isNotEmpty) {
      return woodQuality;
    }

    return 'Запись #${record.id ?? '-'}';
  }

  String _formatRecordSubtitle(TreeInformationRecord record) {
    final parts = <String>[
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

  void _onSavePressed() {
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
      woodQuality: _selectedWoodQuality,
      species: _selectedDynamicElement,
      d1: _selectedDiameters[0].value,
      d2: _selectedDiameters.length > 1 ? _selectedDiameters[1].value : 0,
      treeAge: _parseOptionalInt(_treeAgeController.text),
      treeHeight: _parseOptionalDouble(_treeHeightController.text),
    );

    context.read<PermanentPpBloc>().add(PermanentPpEvent.sentInfo(record));
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
    String? localSelected;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Выберите породу'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allSpecies.length,
                  itemBuilder: (context, index) {
                    final species = allSpecies[index];
                    return RadioListTile<String>(
                      title: Text(species),
                      value: species,
                      groupValue: localSelected,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setDialogState(() => localSelected = value);
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: localSelected == null
                      ? null
                      : () => Navigator.pop(context, localSelected),
                  child: const Text('Подтвердить'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        if (!_dynamicElements.contains(result)) {
          _dynamicElements.add(result);
        }
        _selectedDynamicElement = result;
      });
      _formKey.currentState?.validate();
    }
  }
}
