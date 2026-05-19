import 'package:flutter/material.dart';
import 'package:taxation_card/core/constants/constants.dart';

Future<String?> showSpeciesPickerDialog({
  required BuildContext context,
  String? selectedSpecies,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) {
      return SpeciesPickerDialog(selectedSpecies: selectedSpecies);
    },
  );
}

final class SpeciesPickerDialog extends StatefulWidget {
  const SpeciesPickerDialog({super.key, this.selectedSpecies});

  final String? selectedSpecies;

  @override
  State<SpeciesPickerDialog> createState() => _SpeciesPickerDialogState();
}

final class _SpeciesPickerDialogState extends State<SpeciesPickerDialog> {
  final _searchController = TextEditingController();

  late String? _selectedSpecies = widget.selectedSpecies;
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom;
    final dialogHeight = (availableHeight < 760 ? availableHeight * 0.45 : 420)
        .clamp(160.0, 420.0)
        .toDouble();
    final filteredSpecies = _filteredSpecies;

    return AlertDialog(
      title: const Text('Выберите породу'),
      content: SizedBox(
        width: 360,
        height: dialogHeight,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск породы',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Очистить',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filteredSpecies.isEmpty
                  ? const Center(child: Text('Порода не найдена'))
                  : RadioGroup<String>(
                      groupValue: _selectedSpecies,
                      onChanged: (value) {
                        setState(() => _selectedSpecies = value);
                      },
                      child: ListView.builder(
                        itemCount: filteredSpecies.length,
                        itemBuilder: (context, index) {
                          final species = filteredSpecies[index];
                          final isSelected = _selectedSpecies == species;

                          return RadioListTile<String>(
                            title: Text(species),
                            value: species,
                            contentPadding: EdgeInsets.zero,
                            selected: isSelected,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _selectedSpecies == null
              ? null
              : () => Navigator.pop(context, _selectedSpecies),
          child: const Text('Подтвердить'),
        ),
      ],
    );
  }

  List<String> get _filteredSpecies {
    final normalizedQuery = _query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return allSpecies;
    }

    return allSpecies
        .where((species) => species.toLowerCase().contains(normalizedQuery))
        .toList();
  }
}
