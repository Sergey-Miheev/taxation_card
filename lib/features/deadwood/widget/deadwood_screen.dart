import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxation_card/core/widgets/species_picker_dialog.dart';
import 'package:taxation_card/features/deadwood/bloc/deadwood_bloc.dart';
import 'package:taxation_card/features/deadwood/domain/deadwood_repository.dart';
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
  int? _loadedProbaInfoId;

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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 10,
                      child: Container(
                        padding: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 10,
                                mainAxisSpacing: 4,
                                crossAxisSpacing: 4,
                              ),
                          itemCount: 100,
                          itemBuilder: (context, index) {
                            final number = index + 1;
                            final isSelected =
                                _selectedDiameterNumber == number;

                            return GestureDetector(
                              onTap: () => _toggleDiameterNumber(number),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$number',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    color: isSelected
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 1,
                              mainAxisSpacing: 4,
                            ),
                        itemCount: 10,
                        itemBuilder: (context, index) {
                          final number = 9 - index;
                          final isSelected =
                              _selectedMillimeterNumber == number;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMillimeterNumber = isSelected
                                    ? null
                                    : number;
                              });
                              _notifyDiameterChanged();
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$number',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 16,
                                  color: isSelected
                                      ? theme.colorScheme.onSecondary
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<DeadwoodBloc>().add(
        DeadwoodEvent.loaded(selectedProbaInfoId),
      );
    });
  }

  void _toggleDiameterNumber(int number) {
    setState(() {
      _selectedDiameterNumber = _selectedDiameterNumber == number
          ? null
          : number;
    });
    _notifyDiameterChanged();
  }

  void _notifyDiameterChanged() {
    context.read<DeadwoodBloc>().add(
      DeadwoodEvent.diameterChanged(
        diameter: _selectedDiameterNumber,
        millimeter: _selectedMillimeterNumber,
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
      millimeter: _selectedMillimeterNumber,
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
