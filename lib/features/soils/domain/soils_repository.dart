import 'package:sqflite/sqflite.dart';

final class SoilRecord {
  const SoilRecord({
    required this.probaInfoId,
    required this.soilType,
    required this.soilMoisture,
    required this.soilDepth,
    required this.upperSoilHorizon,
    required this.lowerSoilHorizon,
    required this.groundWaterLevel,
    required this.litterSubhorizon,
    required this.fermentativeLitter,
    required this.humifiedLitter,
    required this.peatyHumus,
    required this.coarseHumus,
    required this.humus,
    required this.humusToEluvialTransition,
    required this.podzolicHorizon,
    required this.secondHumus,
    required this.classification1977,
    required this.classification2004,
    required this.wrb2015,
    required this.note,
    this.id,
  });

  final int? id;
  final int probaInfoId;
  final String soilType;
  final String soilMoisture;
  final String soilDepth;
  final String upperSoilHorizon;
  final String lowerSoilHorizon;
  final double groundWaterLevel;
  final double litterSubhorizon;
  final double fermentativeLitter;
  final double humifiedLitter;
  final double peatyHumus;
  final double coarseHumus;
  final double humus;
  final double humusToEluvialTransition;
  final double podzolicHorizon;
  final double secondHumus;
  final String classification1977;
  final String classification2004;
  final String wrb2015;
  final String note;
}

final class SoilsRepository {
  const SoilsRepository({required Database database}) : _database = database;

  final Database _database;

  Future<List<SoilRecord>> getLatestByProbaInfoId(int probaInfoId) async {
    final rows = await _database.query(
      'soils',
      where: 'proba_info_id = ?',
      whereArgs: [probaInfoId],
      orderBy: 'id DESC',
    );

    return rows.map(_fromRow).toList();
  }

  Future<int> insert(SoilRecord record) {
    return _database.insert('soils', _toRow(record));
  }

  Future<int> delete(int id) {
    return _database.delete('soils', where: 'id = ?', whereArgs: [id]);
  }

  SoilRecord _fromRow(Map<String, Object?> row) {
    return SoilRecord(
      id: row['id'] as int?,
      probaInfoId: row['proba_info_id']! as int,
      soilType: row['soil_type'].toString(),
      soilMoisture: row['soil_moisture'].toString(),
      soilDepth: row['soil_depth'].toString(),
      upperSoilHorizon: row['upper_soil_horizon'].toString(),
      lowerSoilHorizon: row['lower_soil_horizon'].toString(),
      groundWaterLevel: (row['ground_water_level']! as num).toDouble(),
      litterSubhorizon: (row['litter_subhorizon']! as num).toDouble(),
      fermentativeLitter: (row['fermentative_litter']! as num).toDouble(),
      humifiedLitter: (row['humified_litter']! as num).toDouble(),
      peatyHumus: (row['peaty_humus']! as num).toDouble(),
      coarseHumus: (row['coarse_humus']! as num).toDouble(),
      humus: (row['humus']! as num).toDouble(),
      humusToEluvialTransition: (row['humus_to_eluvial_transition']! as num)
          .toDouble(),
      podzolicHorizon: (row['podzolic_horizon']! as num).toDouble(),
      secondHumus: (row['second_humus']! as num).toDouble(),
      classification1977: row['classification_1977'].toString(),
      classification2004: row['classification_2004'].toString(),
      wrb2015: row['wrb_2015'].toString(),
      note: row['note'].toString(),
    );
  }

  Map<String, Object?> _toRow(SoilRecord record) {
    return {
      'proba_info_id': record.probaInfoId,
      'soil_type': record.soilType,
      'soil_moisture': record.soilMoisture,
      'soil_depth': record.soilDepth,
      'upper_soil_horizon': record.upperSoilHorizon,
      'lower_soil_horizon': record.lowerSoilHorizon,
      'ground_water_level': record.groundWaterLevel,
      'litter_subhorizon': record.litterSubhorizon,
      'fermentative_litter': record.fermentativeLitter,
      'humified_litter': record.humifiedLitter,
      'peaty_humus': record.peatyHumus,
      'coarse_humus': record.coarseHumus,
      'humus': record.humus,
      'humus_to_eluvial_transition': record.humusToEluvialTransition,
      'podzolic_horizon': record.podzolicHorizon,
      'second_humus': record.secondHumus,
      'classification_1977': record.classification1977,
      'classification_2004': record.classification2004,
      'wrb_2015': record.wrb2015,
      'note': record.note,
    };
  }
}
