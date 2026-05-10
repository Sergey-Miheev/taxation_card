import 'package:sqflite/sqflite.dart';

final class UndergrowthRecord {
  const UndergrowthRecord({
    required this.probaInfoId,
    required this.plotNumber,
    required this.smallLiving,
    required this.smallDamaged,
    required this.mediumLiving,
    required this.mediumDamaged,
    required this.modelAge,
    required this.modelHeight,
    required this.modelDiameter,
    required this.large15125Living,
    required this.large15125Damaged,
    required this.large25135Living,
    required this.large25135Damaged,
    required this.large35145Living,
    required this.large35145Damaged,
    required this.large45155Living,
    required this.large45155Damaged,
    required this.large551PlusLiving,
    required this.large551PlusDamaged,
    required this.largeModelAge,
    required this.largeModelHeight,
    required this.largeModelDiameter,
    this.id,
    this.species,
    this.origin,
  });

  final int? id;
  final int probaInfoId;
  final int plotNumber;
  final String? species;
  final String? origin;
  final int smallLiving;
  final int smallDamaged;
  final int mediumLiving;
  final int mediumDamaged;
  final int modelAge;
  final double modelHeight;
  final double modelDiameter;
  final int large15125Living;
  final int large15125Damaged;
  final int large25135Living;
  final int large25135Damaged;
  final int large35145Living;
  final int large35145Damaged;
  final int large45155Living;
  final int large45155Damaged;
  final int large551PlusLiving;
  final int large551PlusDamaged;
  final int largeModelAge;
  final double largeModelHeight;
  final double largeModelDiameter;
}

final class UndergrowthRepository {
  const UndergrowthRepository({required Database database})
    : _database = database;

  final Database _database;

  Future<int> insert(UndergrowthRecord record) {
    return _database.insert('undergrowth', _toRow(record));
  }

  Future<void> update(UndergrowthRecord record) async {
    final id = record.id;
    if (id == null) {
      return;
    }

    await _database.update(
      'undergrowth',
      _toRow(record),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<UndergrowthRecord>> getByProbaInfoId(int probaInfoId) async {
    final rows = await _database.query(
      'undergrowth',
      where: 'proba_info_id = ?',
      whereArgs: [probaInfoId],
      orderBy: 'id ASC',
    );

    return rows.map(_fromRow).toList();
  }

  Future<void> deleteById(int id) async {
    await _database.delete('undergrowth', where: 'id = ?', whereArgs: [id]);
  }

  UndergrowthRecord _fromRow(Map<String, Object?> row) {
    return UndergrowthRecord(
      id: row['id'] as int?,
      probaInfoId: (row['proba_info_id'] as int?)!,
      plotNumber: (row['plot_number'] as int?)!,
      species: row['species']?.toString(),
      origin: row['origin']?.toString(),
      smallLiving: (row['small_living'] as int?)!,
      smallDamaged: (row['small_damaged'] as int?)!,
      mediumLiving: (row['medium_living'] as int?)!,
      mediumDamaged: (row['medium_damaged'] as int?)!,
      modelAge: (row['model_age'] as int?)!,
      modelHeight: (row['model_height'] as num?)!.toDouble(),
      modelDiameter: (row['model_diameter'] as num?)!.toDouble(),
      large15125Living: (row['large_151_25_living'] as int?)!,
      large15125Damaged: (row['large_151_25_damaged'] as int?)!,
      large25135Living: (row['large_251_35_living'] as int?)!,
      large25135Damaged: (row['large_251_35_damaged'] as int?)!,
      large35145Living: (row['large_351_45_living'] as int?)!,
      large35145Damaged: (row['large_351_45_damaged'] as int?)!,
      large45155Living: (row['large_451_55_living'] as int?)!,
      large45155Damaged: (row['large_451_55_damaged'] as int?)!,
      large551PlusLiving: (row['large_551_plus_living'] as int?)!,
      large551PlusDamaged: (row['large_551_plus_damaged'] as int?)!,
      largeModelAge: (row['large_model_age'] as int?)!,
      largeModelHeight: (row['large_model_height'] as num?)!.toDouble(),
      largeModelDiameter: (row['large_model_diameter'] as num?)!.toDouble(),
    );
  }

  Map<String, Object?> _toRow(UndergrowthRecord record) {
    return {
      'proba_info_id': record.probaInfoId,
      'plot_number': record.plotNumber,
      'species': record.species,
      'origin': record.origin,
      'small_living': record.smallLiving,
      'small_damaged': record.smallDamaged,
      'medium_living': record.mediumLiving,
      'medium_damaged': record.mediumDamaged,
      'model_age': record.modelAge,
      'model_height': record.modelHeight,
      'model_diameter': record.modelDiameter,
      'large_151_25_living': record.large15125Living,
      'large_151_25_damaged': record.large15125Damaged,
      'large_251_35_living': record.large25135Living,
      'large_251_35_damaged': record.large25135Damaged,
      'large_351_45_living': record.large35145Living,
      'large_351_45_damaged': record.large35145Damaged,
      'large_451_55_living': record.large45155Living,
      'large_451_55_damaged': record.large45155Damaged,
      'large_551_plus_living': record.large551PlusLiving,
      'large_551_plus_damaged': record.large551PlusDamaged,
      'large_model_age': record.largeModelAge,
      'large_model_height': record.largeModelHeight,
      'large_model_diameter': record.largeModelDiameter,
    };
  }
}
