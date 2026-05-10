import 'package:sqflite/sqflite.dart';

final class StumpRecord {
  const StumpRecord({
    required this.probaInfoId,
    required this.species,
    required this.stumpHeight,
    required this.stumpHeightDiameter,
    required this.rootCollarDiameter,
    required this.decayStage,
    this.id,
    this.stumpHeightMillimeter,
    this.rootCollarMillimeter,
    this.rotSize,
    this.rotLength,
  });

  final int? id;
  final int probaInfoId;
  final String species;
  final double stumpHeight;
  final int stumpHeightDiameter;
  final int? stumpHeightMillimeter;
  final int rootCollarDiameter;
  final int? rootCollarMillimeter;
  final double? rotSize;
  final double? rotLength;
  final String decayStage;
}

final class StumpsRepository {
  const StumpsRepository({required Database database}) : _database = database;

  final Database _database;

  Future<int> insert(StumpRecord record) {
    return _database.insert('stumps', _toRow(record));
  }

  Future<List<StumpRecord>> getLatestByProbaInfoId(
    int probaInfoId, {
    int limit = 4,
  }) async {
    final rows = await _database.query(
      'stumps',
      where: 'proba_info_id = ?',
      whereArgs: [probaInfoId],
      orderBy: 'id DESC',
      limit: limit,
    );

    return rows.map(_fromRow).toList();
  }

  Future<void> deleteById(int id) async {
    await _database.delete('stumps', where: 'id = ?', whereArgs: [id]);
  }

  StumpRecord _fromRow(Map<String, Object?> row) {
    return StumpRecord(
      id: row['id'] as int?,
      probaInfoId: (row['proba_info_id'] as int?)!,
      species: row['species'].toString(),
      stumpHeight: (row['stump_height'] as num?)!.toDouble(),
      stumpHeightDiameter: (row['stump_height_diameter'] as int?)!,
      stumpHeightMillimeter: row['stump_height_millimeter'] as int?,
      rootCollarDiameter: (row['root_collar_diameter'] as int?)!,
      rootCollarMillimeter: row['root_collar_millimeter'] as int?,
      rotSize: (row['rot_size'] as num?)?.toDouble(),
      rotLength: (row['rot_length'] as num?)?.toDouble(),
      decayStage: row['decay_stage'].toString(),
    );
  }

  Map<String, Object?> _toRow(StumpRecord record) {
    return {
      'proba_info_id': record.probaInfoId,
      'species': record.species,
      'stump_height': record.stumpHeight,
      'stump_height_diameter': record.stumpHeightDiameter,
      'stump_height_millimeter': record.stumpHeightMillimeter,
      'root_collar_diameter': record.rootCollarDiameter,
      'root_collar_millimeter': record.rootCollarMillimeter,
      'rot_size': record.rotSize,
      'rot_length': record.rotLength,
      'decay_stage': record.decayStage,
    };
  }
}
