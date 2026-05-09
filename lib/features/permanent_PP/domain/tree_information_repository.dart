import 'package:sqflite/sqflite.dart';

final class TreeInformationRecord {
  const TreeInformationRecord({
    required this.probaInfoId,
    required this.d1,
    required this.d2,
    this.id,
    this.woodQuality,
    this.species,
    this.rightColumnNumber,
    this.treeAge,
    this.treeHeight,
  });

  final int? id;
  final int probaInfoId;
  final String? woodQuality;
  final String? species;
  final int d1;
  final int d2;
  final int? rightColumnNumber;
  final int? treeAge;
  final double? treeHeight;
}

final class TreeInformationRepository {
  const TreeInformationRepository({required Database database})
    : _database = database;

  final Database _database;

  Future<int> insert(TreeInformationRecord record) {
    return _database.insert('tree_information', _toRow(record));
  }

  Future<List<TreeInformationRecord>> getLatestByProbaInfoId(
    int probaInfoId, {
    int limit = 4,
  }) async {
    final rows = await _database.query(
      'tree_information',
      where: 'proba_info_id = ?',
      whereArgs: [probaInfoId],
      orderBy: 'id DESC',
      limit: limit,
    );

    return rows.map(_fromRow).toList();
  }

  Future<void> deleteById(int id) async {
    await _database.delete(
      'tree_information',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  TreeInformationRecord _fromRow(Map<String, Object?> row) {
    return TreeInformationRecord(
      id: row['id'] as int?,
      probaInfoId: (row['proba_info_id'] as int?)!,
      woodQuality: row['wood_quality']?.toString(),
      species: row['species']?.toString(),
      d1: (row['d1'] as int?)!,
      d2: (row['d2'] as int?)!,
      rightColumnNumber: row['right_column_number'] as int?,
      treeAge: row['tree_age'] as int?,
      treeHeight: (row['tree_height'] as num?)?.toDouble(),
    );
  }

  Map<String, Object?> _toRow(TreeInformationRecord record) {
    return {
      'proba_info_id': record.probaInfoId,
      'wood_quality': record.woodQuality,
      'species': record.species,
      'd1': record.d1,
      'd2': record.d2,
      'right_column_number': record.rightColumnNumber,
      'tree_age': record.treeAge,
      'tree_height': record.treeHeight,
    };
  }
}
