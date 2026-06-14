import 'package:flutter/foundation.dart';
import 'package:taxation_card/features/permanent_PP/domain/tree_information_repository.dart';

final class SpeciesOptionsController extends ValueNotifier<List<String>> {
  SpeciesOptionsController({
    required TreeInformationRepository treeInformationRepository,
  }) : _treeInformationRepository = treeInformationRepository,
       super(const []);

  final TreeInformationRepository _treeInformationRepository;
  int? _probaInfoId;

  Future<void> loadForProbaInfo(int? probaInfoId) async {
    final shouldMergeWithCurrentValue = _probaInfoId == probaInfoId;
    _probaInfoId = probaInfoId;
    if (probaInfoId == null) {
      value = const [];
      return;
    }

    final species = await _treeInformationRepository
        .getUniqueSpeciesByProbaInfoId(probaInfoId);
    if (_probaInfoId == probaInfoId) {
      value = _normalizeSpecies(
        shouldMergeWithCurrentValue ? [...value, ...species] : species,
      );
    }
  }

  void add(String species) {
    value = _normalizeSpecies([...value, species]);
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
