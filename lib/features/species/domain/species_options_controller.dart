import 'package:flutter/foundation.dart';
import 'package:taxation_card/features/permanent_PP/domain/tree_information_repository.dart';
import 'package:taxation_card/features/taxation_characteristic/domain/taxation_characteristic_repository.dart';

final class SpeciesOptionsController extends ValueNotifier<List<String>> {
  SpeciesOptionsController({
    required TreeInformationRepository treeInformationRepository,
    required TaxationCharacteristicRepository taxationCharacteristicRepository,
  }) : _treeInformationRepository = treeInformationRepository,
       _taxationCharacteristicRepository = taxationCharacteristicRepository,
       super(const []);

  final TreeInformationRepository _treeInformationRepository;
  final TaxationCharacteristicRepository _taxationCharacteristicRepository;
  int? _probaInfoId;

  Future<void> loadForProbaInfo(int? probaInfoId) async {
    final shouldMergeWithCurrentValue = _probaInfoId == probaInfoId;
    _probaInfoId = probaInfoId;
    if (probaInfoId == null) {
      value = const [];
      return;
    }

    final treeSpecies = await _treeInformationRepository
        .getUniqueSpeciesByProbaInfoId(probaInfoId);
    final taxationSpecies = await _taxationCharacteristicRepository
        .getUniqueSpeciesByProbaInfoId(probaInfoId);
    if (_probaInfoId == probaInfoId) {
      value = _normalizeSpecies(
        shouldMergeWithCurrentValue
            ? [...value, ...treeSpecies, ...taxationSpecies]
            : [...treeSpecies, ...taxationSpecies],
      );
    }
  }

  void add(String species) {
    value = _normalizeSpecies([...value, species]);
  }

  void addForProbaInfo({required int? probaInfoId, required String species}) {
    if (_probaInfoId != probaInfoId) {
      _probaInfoId = probaInfoId;
      value = _normalizeSpecies([species]);
      return;
    }

    add(species);
  }

  void remove(String species) {
    final normalizedSpecies = species.trim().toLowerCase();
    value = value
        .where((item) => item.trim().toLowerCase() != normalizedSpecies)
        .toList(growable: false);
  }

  List<String> _normalizeSpecies(Iterable<String> species) {
    final uniqueSpecies = <String>[];
    final seenSpecies = <String>{};

    for (final item in species) {
      final trimmedItem = item.trim();
      if (trimmedItem.isEmpty) {
        continue;
      }

      final normalizedItem = trimmedItem.toLowerCase();
      if (seenSpecies.add(normalizedItem)) {
        uniqueSpecies.add(trimmedItem);
      }
    }

    uniqueSpecies.sort(
      (left, right) => left.toLowerCase().compareTo(right.toLowerCase()),
    );

    return List.unmodifiable(uniqueSpecies);
  }
}
