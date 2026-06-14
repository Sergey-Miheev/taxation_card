import 'package:sqflite/sqflite.dart';

final class DeadwoodRecord {
  const DeadwoodRecord({
    required this.probaInfoId,
    required this.species,
    required this.length,
    required this.diameter,
    required this.decayStage,
    this.id,
    this.millimeter,
    this.rotSize,
    this.rotLength,
  });

  final int? id;
  final int probaInfoId;
  final String species;
  final double length;
  final int diameter;
  final int? millimeter;
  final double? rotSize;
  final double? rotLength;
  final String decayStage;
}

final class DeadwoodRepository {
  const DeadwoodRepository({required Database database}) : _database = database;

  final Database _database;

  Future<int> insert(DeadwoodRecord record) {
    return _database.insert('deadwood', _toRow(record));
  }

  Future<List<DeadwoodRecord>> getLatestByProbaInfoId(int probaInfoId) async {
    final rows = await _database.query(
      'deadwood',
      where: 'proba_info_id = ?',
      whereArgs: [probaInfoId],
      orderBy: 'id DESC',
    );

    return rows.map(_fromRow).toList();
  }

  Future<void> deleteById(int id) async {
    await _database.delete('deadwood', where: 'id = ?', whereArgs: [id]);
  }

  DeadwoodRecord _fromRow(Map<String, Object?> row) {
    return DeadwoodRecord(
      id: row['id'] as int?,
      probaInfoId: (row['proba_info_id'] as int?)!,
      species: row['species'].toString(),
      length: (row['length'] as num?)!.toDouble(),
      diameter: (row['diameter'] as int?)!,
      millimeter: row['millimeter'] as int?,
      rotSize: (row['rot_size'] as num?)?.toDouble(),
      rotLength: (row['rot_length'] as num?)?.toDouble(),
      decayStage: row['decay_stage'].toString(),
    );
  }

  Map<String, Object?> _toRow(DeadwoodRecord record) {
    return {
      'proba_info_id': record.probaInfoId,
      'species': record.species,
      'length': record.length,
      'diameter': record.diameter,
      'millimeter': record.millimeter,
      'rot_size': record.rotSize,
      'rot_length': record.rotLength,
      'decay_stage': record.decayStage,
    };
  }
}
