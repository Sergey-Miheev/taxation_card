import 'package:sqflite/sqflite.dart';

final class TreeInformationRecord {
  const TreeInformationRecord({
    required this.probaInfoId,
    required this.d1,
    required this.d2,
    this.id,
    this.treeNumber,
    this.woodQuality,
    this.species,
    this.rightColumnNumber,
    this.treeAge,
    this.treeHeight,
  });

  final int? id;
  final int probaInfoId;
  final int? treeNumber;
  final String? woodQuality;
  final String? species;
  final double d1;
  final double d2;
  final int? rightColumnNumber;
  final int? treeAge;
  final double? treeHeight;
}

final class TreeInformationRepository {
  const TreeInformationRepository({required Database database})
    : _database = database;

  final Database _database;

  Future<int> insert(TreeInformationRecord record) async {
    final treeNumber =
        record.treeNumber ?? await _nextTreeNumber(record.probaInfoId);

    return _database.insert(
      'tree_information',
      _toRow(record, treeNumber: treeNumber),
    );
  }

  Future<List<TreeInformationRecord>> getLatestByProbaInfoId(
    int probaInfoId, {
    int? limit,
  }) async {
    final rows = await _database.query(
      'tree_information',
      where: 'proba_info_id = ?',
      whereArgs: [probaInfoId],
      orderBy: 'tree_number DESC',
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
      treeNumber: row['tree_number'] as int?,
      woodQuality: row['wood_quality']?.toString(),
      species: row['species']?.toString(),
      d1: (row['d1'] as num?)!.toDouble(),
      d2: (row['d2'] as num?)!.toDouble(),
      rightColumnNumber: row['right_column_number'] as int?,
      treeAge: row['tree_age'] as int?,
      treeHeight: (row['tree_height'] as num?)?.toDouble(),
    );
  }

  Future<int> _nextTreeNumber(int probaInfoId) async {
    final result = await _database.rawQuery(
      'SELECT MAX(tree_number) AS max_tree_number FROM tree_information WHERE proba_info_id = ?',
      [probaInfoId],
    );
    final maxTreeNumber = result.single['max_tree_number'] as int?;

    return (maxTreeNumber ?? 0) + 1;
  }

  Map<String, Object?> _toRow(
    TreeInformationRecord record, {
    required int treeNumber,
  }) {
    return {
      'proba_info_id': record.probaInfoId,
      'tree_number': treeNumber,
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
