import 'package:sqflite/sqflite.dart';
import 'package:taxation_card/features/taxation_characteristic/bloc/taxation_characteristic_bloc.dart';

final class TaxationCharacteristicRepository {
  const TaxationCharacteristicRepository({required Database database})
    : _database = database;

  final Database _database;

  Future<List<TaxationCharacteristicRecord>> getByProbaInfoId(
    int probaInfoId,
  ) async {
    final rows = await _database.query(
      'eyes_taxation',
      where: 'proba_info_id = ?',
      whereArgs: [probaInfoId],
      orderBy: 'id ASC',
    );

    return rows.map(_recordFromRow).toList();
  }

  Future<List<String>> getUniqueSpeciesByProbaInfoId(int probaInfoId) async {
    final rows = await _database.rawQuery(
      '''
SELECT DISTINCT TRIM(species) AS species
FROM eyes_taxation
WHERE proba_info_id = ?
  AND species IS NOT NULL
  AND TRIM(species) != ''
ORDER BY species COLLATE NOCASE
''',
      [probaInfoId],
    );

    return rows
        .map((row) => row['species']?.toString())
        .whereType<String>()
        .toList();
  }

  Future<int> insert(TaxationCharacteristicRecord record) {
    return _database.insert('eyes_taxation', _toRow(record));
  }

  Future<int> update(TaxationCharacteristicRecord record) {
    return _database.update(
      'eyes_taxation',
      _toRow(record),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<void> replaceForProbaInfoId({
    required int probaInfoId,
    required List<TaxationCharacteristicRecord> records,
  }) {
    return _database.transaction((transaction) async {
      await transaction.delete(
        'eyes_taxation',
        where: 'proba_info_id = ?',
        whereArgs: [probaInfoId],
      );

      for (final record in records) {
        await transaction.insert('eyes_taxation', _toRow(record));
      }
    });
  }

  Future<String> buildCsv(int probaInfoId) async {
    final records = await getByProbaInfoId(probaInfoId);
    final buffer = StringBuffer('\uFEFF')
      ..writeln(
        [
          'id',
          'proba_info_id',
          'Номер яруса',
          'Состав яруса',
          'Порода',
          'Высота, м',
          'Диаметр, см',
          'Возраст, лет',
          'Происхождение',
          'Класс товарности',
        ].map(_escapeCsvValue).join(';'),
      );

    for (final record in records) {
      buffer.writeln(
        [
          record.id?.toString() ?? '',
          record.probaInfoId.toString(),
          record.tier ?? '',
          record.compositionCoefficient,
          record.species,
          record.averageHeight,
          record.diameter,
          record.age,
          record.origin,
          record.merchantabilityClass ?? '',
        ].map(_escapeCsvValue).join(';'),
      );
    }

    return buffer.toString();
  }

  TaxationCharacteristicRecord _recordFromRow(Map<String, Object?> row) {
    return TaxationCharacteristicRecord(
      id: row['id'] as int?,
      probaInfoId: (row['proba_info_id'] as int?)!,
      tier: row['tier'].toString(),
      compositionCoefficient: _stringifyValue(row['composition_coefficient']),
      species: row['species']?.toString() ?? '',
      age: row['age'].toString(),
      averageHeight: _stringifyValue(row['average_height']),
      diameter: _stringifyValue(row['diameter']),
      origin: row['origin']?.toString() ?? '',
      merchantabilityClass: row['merchantability_class'].toString(),
    );
  }

  String _stringifyValue(Object? value) {
    if (value is int) {
      return value.toString();
    }

    if (value is double) {
      return value.toString();
    }

    return value?.toString() ?? '';
  }

  Map<String, Object?> _toRow(TaxationCharacteristicRecord record) {
    return {
      'proba_info_id': record.probaInfoId,
      'tier': _parseIntOrZero(record.tier),
      'composition_coefficient': record.compositionCoefficient.trim(),
      'species': record.species.trim(),
      'age': _parseIntOrZero(record.age),
      'average_height': _parseDoubleOrZero(record.averageHeight),
      'diameter': _parseDoubleOrZero(record.diameter),
      'origin': record.origin.trim(),
      'merchantability_class': record.merchantabilityClass?.trim() ?? '',
    };
  }

  double _parseDoubleOrZero(String? value) {
    final normalized = value?.trim().replaceAll(',', '.') ?? '';
    if (normalized.isEmpty) {
      return 0;
    }

    return double.tryParse(normalized) ?? 0;
  }

  int _parseIntOrZero(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 0;
    }

    return int.tryParse(normalized) ?? 0;
  }

  String _escapeCsvValue(String value) {
    if (value.contains(';') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }

    return value;
  }
}
