import 'package:flutter/material.dart';

final class DiameterPickerSelection {
  const DiameterPickerSelection({
    required this.diameter,
    this.millimeter = 0,
    this.isManual = false,
  });

  final int diameter;
  final int millimeter;
  final bool isManual;

  double get value => diameter + millimeter / 10;
}

final class DiameterPicker extends StatelessWidget {
  const DiameterPicker({
    required this.selections,
    required this.onDiameterSelected,
    required this.onMillimeterSelected,
    this.onManualSelectionSubmitted,
    this.onSelectionRemoved,
    this.activeSelectionIndex,
    this.maxSelections = 2,
    super.key,
  });

  final List<DiameterPickerSelection> selections;
  final int? activeSelectionIndex;
  final ValueChanged<int> onDiameterSelected;
  final ValueChanged<int> onMillimeterSelected;
  final ValueChanged<DiameterPickerSelection>? onManualSelectionSubmitted;
  final ValueChanged<int>? onSelectionRemoved;
  final int maxSelections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 10,
              child: Container(
                padding: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 10,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: 100,
                  itemBuilder: (context, index) {
                    if (index == 99) {
                      return GestureDetector(
                        onTap: () => _showManualInputDialog(context),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '...',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    final number = index + 1;
                    final selectionIndex = selections.indexWhere(
                      (selection) =>
                          !selection.isManual && selection.diameter == number,
                    );
                    final isSelected = selectionIndex != -1;
                    final color = isSelected
                        ? _selectionColor(selectionIndex)
                        : theme.colorScheme.surfaceContainerHighest;

                    return GestureDetector(
                      onTap: () => onDiameterSelected(number),
                      child: DecoratedBox(
                        position: DecorationPosition.foreground,
                        decoration: BoxDecoration(
                          border: _activeBorder(theme, selectionIndex),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: ColoredBox(
                            color: color,
                            child: Center(
                              child: Text(
                                '$number',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 4,
                ),
                itemCount: 10,
                itemBuilder: (context, index) {
                  final number = 9 - index;
                  final matchingSelections = selections.indexed
                      .where((entry) => entry.$2.millimeter == number)
                      .map((entry) => entry.$1)
                      .toList();
                  final isSelected = matchingSelections.isNotEmpty;

                  return GestureDetector(
                    onTap: () => onMillimeterSelected(number),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _MillimeterCellBackground(
                            selectionIndexes: matchingSelections,
                            colorForIndex: _selectionColor,
                            fallbackColor: theme
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
                          ),
                          Center(
                            child: Text(
                              '$number',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        _ManualSelectionTags(
          selections: selections,
          colorForIndex: _selectionColor,
          onSelectionRemoved: onSelectionRemoved,
        ),
      ],
    );
  }

  Future<void> _showManualInputDialog(BuildContext context) async {
    final onSubmitted = onManualSelectionSubmitted;
    if (onSubmitted == null) {
      return;
    }

    if (selections.length >= maxSelections) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Можно выбрать не больше $maxSelections.')),
      );
      return;
    }

    final result = await showDialog<DiameterPickerSelection>(
      context: context,
      builder: (_) => const _ManualDiameterDialog(),
    );

    if (result != null) {
      onSubmitted(result);
    }
  }

  Border? _activeBorder(ThemeData theme, int selectionIndex) {
    if (selectionIndex == -1 || selectionIndex != activeSelectionIndex) {
      return null;
    }

    return Border.all(color: theme.colorScheme.onSurface, width: 2);
  }

  Color _selectionColor(int index) {
    return switch (index) {
      0 => Colors.green.shade600,
      1 => Colors.blue.shade600,
      _ => Colors.purple.shade600,
    };
  }
}

final class _ManualDiameterDialog extends StatefulWidget {
  const _ManualDiameterDialog();

  @override
  State<_ManualDiameterDialog> createState() => _ManualDiameterDialogState();
}

final class _ManualDiameterDialogState extends State<_ManualDiameterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _diameterController = TextEditingController();
  final _millimeterController = TextEditingController(text: '0');

  @override
  void dispose() {
    _diameterController.dispose();
    _millimeterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Введите диаметр'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _diameterController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Диаметр',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final diameter = int.tryParse(value?.trim() ?? '');
                if (diameter == null || diameter <= 0) {
                  return 'Введите диаметр';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _millimeterController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Миллиметры',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final millimeter = int.tryParse(value?.trim() ?? '');
                if (millimeter == null || millimeter < 0 || millimeter > 9) {
                  return 'Введите значение от 0 до 9';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Добавить')),
      ],
    );
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    Navigator.pop(
      context,
      DiameterPickerSelection(
        diameter: int.parse(_diameterController.text.trim()),
        millimeter: int.parse(_millimeterController.text.trim()),
        isManual: true,
      ),
    );
  }
}

final class _ManualSelectionTags extends StatelessWidget {
  const _ManualSelectionTags({
    required this.selections,
    required this.colorForIndex,
    required this.onSelectionRemoved,
  });

  final List<DiameterPickerSelection> selections;
  final Color Function(int index) colorForIndex;
  final ValueChanged<int>? onSelectionRemoved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manualSelections = selections.indexed
        .where((entry) => entry.$2.isManual)
        .toList();

    if (manualSelections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: manualSelections.map((entry) {
          final index = entry.$1;
          final selection = entry.$2;
          return InputChip(
            label: Text(_formatValue(selection.value)),
            labelStyle: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            deleteIcon: const Icon(Icons.close, size: 18),
            deleteIconColor: Colors.white,
            onDeleted: onSelectionRemoved == null
                ? null
                : () => onSelectionRemoved!(index),
            backgroundColor: colorForIndex(index),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatValue(double value) {
    return '${value.toStringAsFixed(1).replaceAll('.', ',')} см';
  }
}

final class _MillimeterCellBackground extends StatelessWidget {
  const _MillimeterCellBackground({
    required this.selectionIndexes,
    required this.colorForIndex,
    required this.fallbackColor,
  });

  final List<int> selectionIndexes;
  final Color Function(int index) colorForIndex;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    if (selectionIndexes.isEmpty) {
      return ColoredBox(color: fallbackColor);
    }

    if (selectionIndexes.length == 1) {
      return ColoredBox(color: colorForIndex(selectionIndexes.first));
    }

    return Row(
      children: selectionIndexes
          .take(2)
          .map(
            (index) => Expanded(
              child: ColoredBox(
                color: colorForIndex(index),
                child: const SizedBox.expand(),
              ),
            ),
          )
          .toList(),
    );
  }
}
