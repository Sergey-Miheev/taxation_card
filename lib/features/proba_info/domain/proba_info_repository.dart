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
    this.dominantSpecies,
    this.siteClass,
    this.forestType,
    this.tlu,
    this.soil,
    this.livingGroundCover,
    this.undergrowth,
    this.understory,
  });

  final int? id;
  final String? region;
  final String? district;
  final String? forestry;
  final String? subForestry;
  final String? dominantSpecies;
  final String? siteClass;
  final String? forestType;
  final String? tlu;
  final String? soil;
  final String? livingGroundCover;
  final String? undergrowth;
  final String? understory;
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
      dominantSpecies: row['dominant_species'] as String?,
      siteClass: row['site_class'] as String?,
      forestType: row['forest_type'] as String?,
      tlu: row['tlu'] as String?,
      soil: row['soil'] as String?,
      livingGroundCover: row['living_ground_cover'] as String?,
      undergrowth: row['undergrowth'] as String?,
      understory: row['understory'] as String?,
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
      'dominant_species': record.dominantSpecies,
      'site_class': record.siteClass,
      'forest_type': record.forestType,
      'tlu': record.tlu,
      'soil': record.soil,
      'living_ground_cover': record.livingGroundCover,
      'undergrowth': record.undergrowth,
      'understory': record.understory,
      'quarter': record.quarter,
      'allotment': record.allotment,
      'sample_plot_number': record.samplePlotNumber,
      'sample_plot_area': record.samplePlotArea,
    };
  }
}
