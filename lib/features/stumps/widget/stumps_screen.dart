import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxation_card/core/constants/constants.dart';
import 'package:taxation_card/core/widgets/diameter_picker.dart';
import 'package:taxation_card/features/home/bloc/main_tabs_bloc.dart';
import 'package:taxation_card/features/stumps/bloc/stumps_bloc.dart';
import 'package:taxation_card/features/stumps/domain/stumps_repository.dart';

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

  String? _selectedSpecies;
  String? _selectedDecayStage = _decayStageOptions.first;
  int? _selectedStumpHeightDiameter;
  int? _selectedStumpHeightMillimeter;
  int? _selectedRootCollarDiameter;
  int? _selectedRootCollarMillimeter;
  bool _isSelectedStumpHeightDiameterManual = false;
  bool _isSelectedRootCollarDiameterManual = false;
  int? _loadedProbaInfoId;

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
                Text(
                  'Диаметр пня на высоте пня',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                DiameterPicker(
                  selections: _selectedStumpHeightDiameter == null
                      ? const []
                      : [
                          DiameterPickerSelection(
                            diameter: _selectedStumpHeightDiameter!,
                            millimeter: _selectedStumpHeightMillimeter ?? 0,
                            isManual: _isSelectedStumpHeightDiameterManual,
                          ),
                        ],
                  onDiameterSelected: _toggleStumpHeightDiameter,
                  onMillimeterSelected: (number) {
                    setState(() {
                      _selectedStumpHeightMillimeter = number;
                    });
                    _notifyStumpHeightDiameterChanged();
                  },
                  onManualSelectionSubmitted: (selection) {
                    setState(() {
                      _selectedStumpHeightDiameter = selection.diameter;
                      _selectedStumpHeightMillimeter = selection.millimeter;
                      _isSelectedStumpHeightDiameterManual = true;
                    });
                    _notifyStumpHeightDiameterChanged();
                  },
                  onSelectionRemoved: (_) {
                    setState(() {
                      _selectedStumpHeightDiameter = null;
                      _selectedStumpHeightMillimeter = null;
                      _isSelectedStumpHeightDiameterManual = false;
                    });
                    _notifyStumpHeightDiameterChanged();
                  },
                  maxSelections: 1,
                ),
                const SizedBox(height: 16),
                Text(
                  'Диаметр пня на высоте шейки корня',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                DiameterPicker(
                  selections: _selectedRootCollarDiameter == null
                      ? const []
                      : [
                          DiameterPickerSelection(
                            diameter: _selectedRootCollarDiameter!,
                            millimeter: _selectedRootCollarMillimeter ?? 0,
                            isManual: _isSelectedRootCollarDiameterManual,
                          ),
                        ],
                  onDiameterSelected: _toggleRootCollarDiameter,
                  onMillimeterSelected: (number) {
                    setState(() {
                      _selectedRootCollarMillimeter = number;
                    });
                    _notifyRootCollarDiameterChanged();
                  },
                  onManualSelectionSubmitted: (selection) {
                    setState(() {
                      _selectedRootCollarDiameter = selection.diameter;
                      _selectedRootCollarMillimeter = selection.millimeter;
                      _isSelectedRootCollarDiameterManual = true;
                    });
                    _notifyRootCollarDiameterChanged();
                  },
                  onSelectionRemoved: (_) {
                    setState(() {
                      _selectedRootCollarDiameter = null;
                      _selectedRootCollarMillimeter = null;
                      _isSelectedRootCollarDiameterManual = false;
                    });
                    _notifyRootCollarDiameterChanged();
                  },
                  maxSelections: 1,
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

  Widget _buildRecentRecords({
    required BuildContext context,
    required List<StumpRecord> records,
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
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<StumpsBloc>().add(StumpsEvent.loaded(selectedProbaInfoId));
    });
  }

  void _toggleStumpHeightDiameter(int number) {
    setState(() {
      _selectedStumpHeightDiameter = _selectedStumpHeightDiameter == number
          ? null
          : number;
      _isSelectedStumpHeightDiameterManual = false;
    });
    _notifyStumpHeightDiameterChanged();
  }

  void _notifyStumpHeightDiameterChanged() {
    context.read<StumpsBloc>().add(
      StumpsEvent.stumpHeightDiameterChanged(
        diameter: _selectedStumpHeightDiameter,
        millimeter: _selectedStumpHeightDiameter == null
            ? null
            : _selectedStumpHeightMillimeter ?? 0,
      ),
    );
  }

  void _toggleRootCollarDiameter(int number) {
    setState(() {
      _selectedRootCollarDiameter = _selectedRootCollarDiameter == number
          ? null
          : number;
      _isSelectedRootCollarDiameterManual = false;
    });
    _notifyRootCollarDiameterChanged();
  }

  void _notifyRootCollarDiameterChanged() {
    context.read<StumpsBloc>().add(
      StumpsEvent.rootCollarDiameterChanged(
        diameter: _selectedRootCollarDiameter,
        millimeter: _selectedRootCollarDiameter == null
            ? null
            : _selectedRootCollarMillimeter ?? 0,
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

    if (_selectedStumpHeightDiameter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите диаметр пня на высоте пня.')),
      );
      return;
    }

    if (_selectedRootCollarDiameter == null) {
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
      stumpHeightDiameter: _selectedStumpHeightDiameter!,
      stumpHeightMillimeter: _selectedStumpHeightMillimeter ?? 0,
      rootCollarDiameter: _selectedRootCollarDiameter!,
      rootCollarMillimeter: _selectedRootCollarMillimeter ?? 0,
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
    var localSelected = _selectedSpecies;

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
                    final isSelected = localSelected == species;

                    return ListTile(
                      title: Text(species),
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                      ),
                      onTap: () {
                        setDialogState(() => localSelected = species);
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
        _dynamicElements
          ..clear()
          ..add(result);
        _selectedSpecies = result;
      });
      context.read<StumpsBloc>().add(StumpsEvent.speciesChanged(result));
    }
  }
}
