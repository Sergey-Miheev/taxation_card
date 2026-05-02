import 'package:sqflite/sqflite.dart';
import 'package:taxation_card/features/taxation_characteristic/bloc/taxation_characteristic_bloc.dart';

final class TaxationCharacteristicRepository {
  const TaxationCharacteristicRepository({required Database database})
    : _database = database;

  final Database _database;

  Future<List<TaxationCharacteristicRecord>> getAll() async {
    final rows = await _database.query('eyes_taxation', orderBy: 'id ASC');

    return rows.map(_recordFromRow).toList();
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

  Future<String> buildCsv() async {
    final records = await getAll();
    final buffer = StringBuffer('\uFEFF')
      ..writeln(
        [
          'id',
          'Ярус',
          'Преобладающая порода',
          'Коэффициент состава',
          'Возраст',
          'Средняя высота, м',
          'Диаметр, см',
          'Полнота',
          'Запас, м³',
          'Тип леса',
          'Класс бонитета',
          'ТЛУ',
          'Лесные насаждения: Всего',
          'В том числе хвойных',
          'Сомкнутость',
          'Изреженность',
          '% выхода деловой древесины',
          'Класс товарности',
        ].map(_escapeCsvValue).join(';'),
      );

    for (final record in records) {
      buffer.writeln(
        [
          record.id?.toString() ?? '',
          record.tier ?? '',
          record.dominantSpecies,
          record.compositionCoefficient,
          record.age,
          record.averageHeight,
          record.diameter,
          record.density,
          record.stock,
          record.forestType ?? '',
          record.siteClass ?? '',
          record.tlu ?? '',
          record.plantationsTotal,
          record.coniferousTotal,
          record.canopyClosure,
          record.sparseness,
          record.commercialWoodOutput,
          record.merchantabilityClass ?? '',
        ].map(_escapeCsvValue).join(';'),
      );
    }

    return buffer.toString();
  }

  double _parseDouble(String value) {
    return double.parse(value.trim().replaceAll(',', '.'));
  }

  int _parseInt(String value) {
    return int.parse(value.trim());
  }

  TaxationCharacteristicRecord _recordFromRow(Map<String, Object?> row) {
    return TaxationCharacteristicRecord(
      id: row['id'] as int?,
      tier: row['tier'].toString(),
      dominantSpecies: row['dominant_species'].toString(),
      compositionCoefficient: _stringifyNumber(row['composition_coefficient']),
      age: row['age'].toString(),
      averageHeight: _stringifyNumber(row['average_height']),
      diameter: _stringifyNumber(row['diameter']),
      density: _stringifyNumber(row['density']),
      stock: _stringifyNumber(row['stock']),
      forestType: row['forest_type'].toString(),
      siteClass: row['site_class'].toString(),
      tlu: row['tlu'].toString(),
      plantationsTotal: row['plantations_total'].toString(),
      coniferousTotal: row['coniferous_total'].toString(),
      canopyClosure: _stringifyNumber(row['canopy_closure']),
      sparseness: _stringifyNumber(row['sparseness']),
      commercialWoodOutput: _stringifyNumber(row['commercial_wood_output']),
      merchantabilityClass: row['merchantability_class'].toString(),
    );
  }

  String _stringifyNumber(Object? value) {
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
      'tier': _parseInt(record.tier!),
      'dominant_species': record.dominantSpecies,
      'composition_coefficient': _parseDouble(record.compositionCoefficient),
      'age': _parseInt(record.age),
      'average_height': _parseDouble(record.averageHeight),
      'diameter': _parseDouble(record.diameter),
      'density': _parseDouble(record.density),
      'stock': _parseDouble(record.stock),
      'forest_type': record.forestType,
      'site_class': record.siteClass,
      'tlu': record.tlu,
      'plantations_total': _parseInt(record.plantationsTotal),
      'coniferous_total': _parseInt(record.coniferousTotal),
      'canopy_closure': _parseDouble(record.canopyClosure),
      'sparseness': _parseDouble(record.sparseness),
      'commercial_wood_output': _parseDouble(record.commercialWoodOutput),
      'merchantability_class': record.merchantabilityClass,
    };
  }

  String _escapeCsvValue(String value) {
    if (value.contains(';') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }

    return value;
  }
}
