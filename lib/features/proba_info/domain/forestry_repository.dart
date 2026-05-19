import 'package:sqflite/sqflite.dart';

final class DistrictForestryRecord {
  const DistrictForestryRecord({
    required this.fgisCode,
    required this.name,
    required this.regionCode,
  });

  final String fgisCode;
  final String name;
  final int regionCode;
}

final class SubForestryRecord {
  const SubForestryRecord({
    required this.fgisCode,
    required this.name,
    required this.regionCode,
    required this.districtForestryCode,
  });

  final String fgisCode;
  final String name;
  final int regionCode;
  final String districtForestryCode;
}

final class ForestryRepository {
  const ForestryRepository({required Database database}) : _database = database;

  final Database _database;

  Future<List<DistrictForestryRecord>> getDistrictForestries() async {
    final rows = await _database.query(
      'district_forestries',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows
        .map(
          (row) => DistrictForestryRecord(
            fgisCode: row['fgis_code'].toString(),
            name: row['name'].toString(),
            regionCode: row['region_code']! as int,
          ),
        )
        .toList();
  }

  Future<List<SubForestryRecord>> getSubForestries() async {
    final rows = await _database.query(
      'sub_forestries',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows
        .map(
          (row) => SubForestryRecord(
            fgisCode: row['fgis_code'].toString(),
            name: row['name'].toString(),
            regionCode: row['region_code']! as int,
            districtForestryCode: row['district_forestry_code'].toString(),
          ),
        )
        .toList();
  }
}
