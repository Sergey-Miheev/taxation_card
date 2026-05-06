import 'package:sqflite/sqflite.dart';

final class ProbaInfoRecord {
  const ProbaInfoRecord({
    required this.quarter,
    required this.allotment,
    required this.samplePlotNumber,
    required this.samplePlotArea,
    this.id,
    this.region,
    this.district,
    this.forestry,
    this.subForestry,
  });

  final int? id;
  final String? region;
  final String? district;
  final String? forestry;
  final String? subForestry;
  final int quarter;
  final int allotment;
  final int samplePlotNumber;
  final double samplePlotArea;
}

final class ProbaInfoRepository {
  const ProbaInfoRepository({required Database database})
    : _database = database;

  final Database _database;

  Future<List<ProbaInfoRecord>> getAll() async {
    final rows = await _database.query('proba_info', orderBy: 'id ASC');

    return rows.map(_fromRow).toList();
  }

  Future<int> insert(ProbaInfoRecord record) {
    return _database.insert('proba_info', _toRow(record));
  }

  Future<int> update(ProbaInfoRecord record) {
    return _database.update(
      'proba_info',
      _toRow(record),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  ProbaInfoRecord _fromRow(Map<String, Object?> row) {
    return ProbaInfoRecord(
      id: row['id'] as int?,
      region: row['region'] as String?,
      district: row['district'] as String?,
      forestry: row['forestry'] as String?,
      subForestry: row['sub_forestry'] as String?,
      quarter: row['quarter']! as int,
      allotment: row['allotment']! as int,
      samplePlotNumber: row['sample_plot_number']! as int,
      samplePlotArea: (row['sample_plot_area']! as num).toDouble(),
    );
  }

  Map<String, Object?> _toRow(ProbaInfoRecord record) {
    return {
      'region': record.region,
      'district': record.district,
      'forestry': record.forestry,
      'sub_forestry': record.subForestry,
      'quarter': record.quarter,
      'allotment': record.allotment,
      'sample_plot_number': record.samplePlotNumber,
      'sample_plot_area': record.samplePlotArea,
    };
  }
}
