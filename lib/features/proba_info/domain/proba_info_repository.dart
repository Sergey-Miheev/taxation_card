import 'package:sqflite/sqflite.dart';

final class ProbaInfoRecord {
  const ProbaInfoRecord({
    required this.quarter,
    required this.allotment,
    required this.samplePlotNumber,
    required this.samplePlotArea,
    required this.deadwoodArea,
    required this.stumpsAccountingArea,
    required this.undergrowthPlotCount,
    required this.undergrowthPlotArea,
    required this.understoryPlotCount,
    required this.understoryPlotArea,
    this.id,
    this.createdAt,
    this.plantingDate,
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
    this.x1,
    this.y1,
    this.x2,
    this.y2,
    this.x3,
    this.y3,
    this.x4,
    this.y4,
  });

  final int? id;
  final DateTime? createdAt;
  final DateTime? plantingDate;
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
  final String? x1;
  final String? y1;
  final String? x2;
  final String? y2;
  final String? x3;
  final String? y3;
  final String? x4;
  final String? y4;
  final int quarter;
  final int allotment;
  final int samplePlotNumber;
  final double samplePlotArea;
  final double deadwoodArea;
  final double stumpsAccountingArea;
  final int undergrowthPlotCount;
  final double undergrowthPlotArea;
  final int understoryPlotCount;
  final double understoryPlotArea;
}

final class ProbaInfoRepository {
  const ProbaInfoRepository({required Database database})
    : _database = database;

  final Database _database;

  Future<List<ProbaInfoRecord>> getAll() async {
    final rows = await _database.query('proba_info', orderBy: 'id ASC');

    return rows.map(_fromRow).toList();
  }

  Future<ProbaInfoRecord?> getById(int id) async {
    final rows = await _database.query(
      'proba_info',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _fromRow(rows.single);
  }

  Future<int> insert(ProbaInfoRecord record) {
    final row = _toRow(record)
      ..['created_at'] = (record.createdAt ?? DateTime.now()).toIso8601String();

    return _database.insert('proba_info', row);
  }

  Future<int> update(ProbaInfoRecord record) {
    return _database.update(
      'proba_info',
      _toRow(record),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> updateCoordinates({
    required int id,
    required String x1,
    required String y1,
    required String x2,
    required String y2,
    required String x3,
    required String y3,
    required String x4,
    required String y4,
  }) {
    return _database.update(
      'proba_info',
      {
        'x1': x1,
        'y1': y1,
        'x2': x2,
        'y2': y2,
        'x3': x3,
        'y3': y3,
        'x4': x4,
        'y4': y4,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateCoordinatePoint({
    required int id,
    required int pointNumber,
    required String x,
    required String y,
  }) {
    return _database.update(
      'proba_info',
      {'x$pointNumber': x, 'y$pointNumber': y},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateUndergrowthPlotInfo({
    required int id,
    required int plotCount,
    required double plotArea,
  }) {
    return _database.update(
      'proba_info',
      {'undergrowth_plot_count': plotCount, 'undergrowth_plot_area': plotArea},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateUnderstoryPlotInfo({
    required int id,
    required int plotCount,
    required double plotArea,
  }) {
    return _database.update(
      'proba_info',
      {'understory_plot_count': plotCount, 'understory_plot_area': plotArea},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateDeadwoodArea({required int id, required double area}) {
    return _database.update(
      'proba_info',
      {'deadwood_area': area},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateStumpsAccountingArea({
    required int id,
    required double area,
  }) {
    return _database.update(
      'proba_info',
      {'stumps_accounting_area': area},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  ProbaInfoRecord _fromRow(Map<String, Object?> row) {
    return ProbaInfoRecord(
      id: row['id'] as int?,
      createdAt: _dateTimeFromRow(row['created_at']),
      plantingDate: _dateTimeFromRow(row['planting_date']),
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
      x1: row['x1'] as String?,
      y1: row['y1'] as String?,
      x2: row['x2'] as String?,
      y2: row['y2'] as String?,
      x3: row['x3'] as String?,
      y3: row['y3'] as String?,
      x4: row['x4'] as String?,
      y4: row['y4'] as String?,
      quarter: row['quarter']! as int,
      allotment: row['allotment']! as int,
      samplePlotNumber: row['sample_plot_number']! as int,
      samplePlotArea: (row['sample_plot_area']! as num).toDouble(),
      deadwoodArea: (row['deadwood_area']! as num).toDouble(),
      stumpsAccountingArea: (row['stumps_accounting_area']! as num).toDouble(),
      undergrowthPlotCount: row['undergrowth_plot_count']! as int,
      undergrowthPlotArea: (row['undergrowth_plot_area']! as num).toDouble(),
      understoryPlotCount: row['understory_plot_count']! as int,
      understoryPlotArea: (row['understory_plot_area']! as num).toDouble(),
    );
  }

  Map<String, Object?> _toRow(ProbaInfoRecord record) {
    final row = <String, Object?>{
      'planting_date': _dateTimeToRow(record.plantingDate),
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
      'x1': record.x1,
      'y1': record.y1,
      'x2': record.x2,
      'y2': record.y2,
      'x3': record.x3,
      'y3': record.y3,
      'x4': record.x4,
      'y4': record.y4,
      'quarter': record.quarter,
      'allotment': record.allotment,
      'sample_plot_number': record.samplePlotNumber,
      'sample_plot_area': record.samplePlotArea,
      'deadwood_area': record.deadwoodArea,
      'stumps_accounting_area': record.stumpsAccountingArea,
      'undergrowth_plot_count': record.undergrowthPlotCount,
      'undergrowth_plot_area': record.undergrowthPlotArea,
      'understory_plot_count': record.understoryPlotCount,
      'understory_plot_area': record.understoryPlotArea,
    };

    if (record.createdAt != null) {
      row['created_at'] = _dateTimeToRow(record.createdAt);
    }

    return row;
  }

  DateTime? _dateTimeFromRow(Object? value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }

    final parsed =
        DateTime.tryParse(text) ??
        DateTime.tryParse(text.replaceFirst(' ', 'T'));
    if (parsed != null) {
      return parsed;
    }

    final parts = text.split('.');
    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }

    return DateTime(year, month, day);
  }

  String? _dateTimeToRow(DateTime? value) {
    return value?.toIso8601String();
  }
}
