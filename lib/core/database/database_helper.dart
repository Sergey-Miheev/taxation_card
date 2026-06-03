import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:taxation_card/core/database/forestry_seed_data.dart';
import 'package:taxation_card/core/database/seed_data.dart';

class DatabaseHelper {
  DatabaseHelper._init();
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB('taxation_card.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE federation_subjects (
  id $idType,
  name $textType
)
''');

    await db.execute('''
CREATE TABLE subject_districts (
  id $idType,
  name $textType,
  id_subject $integerType,
  FOREIGN KEY (id_subject) REFERENCES federation_subjects (id) ON DELETE CASCADE
)
''');

    await _createDistrictForestriesTable(db);
    await _createSubForestriesTable(db);
    await _seedFederationData(db);
    await _seedForestryData(db);
    await _createProbaInfoTable(db);
    await _createEyesTaxationTable(db);
    await _createTreeInformationTable(db);
    await _createUndergrowthTable(db);
    await _createUnderstoryTable(db);
    await _createDeadwoodTable(db);
    await _createStumpsTable(db);
    await _createSoilsTable(db);
  }

  Future<void> _createDistrictForestriesTable(Database db) async {
    await db.execute('''
CREATE TABLE district_forestries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fgis_code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  region_code INTEGER NOT NULL
)
''');
  }

  Future<void> _createSubForestriesTable(Database db) async {
    await db.execute('''
CREATE TABLE sub_forestries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fgis_code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  region_code INTEGER NOT NULL,
  district_forestry_code TEXT NOT NULL,
  FOREIGN KEY (district_forestry_code) REFERENCES district_forestries (fgis_code) ON DELETE CASCADE
)
''');
  }

  Future<void> _seedFederationData(Database db) async {
    for (final entry in russianFederationData.entries) {
      final subjectId = await db.insert('federation_subjects', {
        'name': entry.key,
      });
      final batch = db.batch();
      for (final district in entry.value) {
        batch.insert('subject_districts', {
          'name': district,
          'id_subject': subjectId,
        });
      }
      await batch.commit(noResult: true);
    }
  }

  Future<void> _seedForestryData(Database db) async {
    final districtBatch = db.batch();
    for (final forestry in districtForestrySeedData) {
      districtBatch.insert('district_forestries', {
        'fgis_code': forestry.fgisCode,
        'name': forestry.name,
        'region_code': forestry.regionCode,
      });
    }
    await districtBatch.commit(noResult: true);

    final subForestryBatch = db.batch();
    for (final forestry in subForestrySeedData) {
      subForestryBatch.insert('sub_forestries', {
        'fgis_code': forestry.fgisCode,
        'name': forestry.name,
        'region_code': forestry.regionCode,
        'district_forestry_code': forestry.districtForestryCode,
      });
    }
    await subForestryBatch.commit(noResult: true);
  }

  Future<void> _createEyesTaxationTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS eyes_taxation (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  proba_info_id INTEGER NOT NULL,
  tier INTEGER NOT NULL,
  composition_coefficient TEXT NOT NULL,
  species TEXT NOT NULL DEFAULT '',
  age INTEGER NOT NULL,
  average_height REAL NOT NULL,
  diameter REAL NOT NULL,
  origin TEXT NOT NULL DEFAULT '',
  merchantability_class TEXT NOT NULL,
  FOREIGN KEY (proba_info_id) REFERENCES proba_info (id) ON DELETE CASCADE
)
''');
  }

  Future<void> _createProbaInfoTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS proba_info (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  region TEXT,
  district TEXT,
  forestry TEXT,
  sub_forestry TEXT,
  dominant_species TEXT,
  site_class TEXT,
  forest_type TEXT,
  tlu TEXT,
  soil TEXT,
  living_ground_cover TEXT,
  undergrowth TEXT,
  understory TEXT,
  undergrowth_plot_count INTEGER NOT NULL,
  undergrowth_plot_area REAL NOT NULL,
  understory_plot_count INTEGER NOT NULL,
  understory_plot_area REAL NOT NULL,
  quarter INTEGER NOT NULL,
  allotment INTEGER NOT NULL,
  sample_plot_number INTEGER NOT NULL,
  sample_plot_area REAL NOT NULL,
  deadwood_area REAL NOT NULL,
  stumps_accounting_area REAL NOT NULL,
  x1 TEXT,
  y1 TEXT,
  x2 TEXT,
  y2 TEXT,
  x3 TEXT,
  y3 TEXT,
  x4 TEXT,
  y4 TEXT
)
''');
  }

  Future<void> _createTreeInformationTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS tree_information (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  proba_info_id INTEGER NOT NULL,
  tree_number INTEGER NOT NULL,
  wood_quality TEXT,
  species TEXT,
  d1 REAL NOT NULL,
  d2 REAL NOT NULL,
  right_column_number INTEGER,
  tree_age INTEGER,
  tree_height REAL,
  FOREIGN KEY (proba_info_id) REFERENCES proba_info (id) ON DELETE CASCADE
)
''');
  }

  Future<void> _createUndergrowthTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS undergrowth (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  proba_info_id INTEGER NOT NULL,
  plot_number INTEGER NOT NULL,
  species TEXT,
  small_living INTEGER NOT NULL,
  small_damaged INTEGER NOT NULL,
  medium_living INTEGER NOT NULL,
  medium_damaged INTEGER NOT NULL,
  model_age INTEGER NOT NULL,
  model_height REAL NOT NULL,
  model_diameter REAL NOT NULL,
  large_151_25_living INTEGER NOT NULL,
  large_151_25_damaged INTEGER NOT NULL,
  large_251_35_living INTEGER NOT NULL,
  large_251_35_damaged INTEGER NOT NULL,
  large_351_45_living INTEGER NOT NULL,
  large_351_45_damaged INTEGER NOT NULL,
  large_451_55_living INTEGER NOT NULL,
  large_451_55_damaged INTEGER NOT NULL,
  large_551_plus_living INTEGER NOT NULL,
  large_551_plus_damaged INTEGER NOT NULL,
  large_model_age INTEGER NOT NULL,
  large_model_height REAL NOT NULL,
  large_model_diameter REAL NOT NULL,
  FOREIGN KEY (proba_info_id) REFERENCES proba_info (id) ON DELETE CASCADE
)
''');
  }

  Future<void> _createUnderstoryTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS understory (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  proba_info_id INTEGER NOT NULL,
  plot_number INTEGER NOT NULL,
  species TEXT,
  origin TEXT,
  small_living INTEGER NOT NULL,
  small_damaged INTEGER NOT NULL,
  medium_living INTEGER NOT NULL,
  medium_damaged INTEGER NOT NULL,
  model_age INTEGER NOT NULL,
  model_height REAL NOT NULL,
  model_diameter REAL NOT NULL,
  large_151_25_living INTEGER NOT NULL,
  large_151_25_damaged INTEGER NOT NULL,
  large_251_35_living INTEGER NOT NULL,
  large_251_35_damaged INTEGER NOT NULL,
  large_351_45_living INTEGER NOT NULL,
  large_351_45_damaged INTEGER NOT NULL,
  large_451_55_living INTEGER NOT NULL,
  large_451_55_damaged INTEGER NOT NULL,
  large_551_plus_living INTEGER NOT NULL,
  large_551_plus_damaged INTEGER NOT NULL,
  large_model_age INTEGER NOT NULL,
  large_model_height REAL NOT NULL,
  large_model_diameter REAL NOT NULL,
  FOREIGN KEY (proba_info_id) REFERENCES proba_info (id) ON DELETE CASCADE
)
''');
  }

  Future<void> _createDeadwoodTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS deadwood (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  proba_info_id INTEGER NOT NULL,
  species TEXT NOT NULL,
  length REAL NOT NULL,
  diameter INTEGER NOT NULL,
  millimeter INTEGER,
  rot_size REAL,
  rot_length REAL,
  decay_stage TEXT NOT NULL,
  FOREIGN KEY (proba_info_id) REFERENCES proba_info (id) ON DELETE CASCADE
)
''');
  }

  Future<void> _createStumpsTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS stumps (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  proba_info_id INTEGER NOT NULL,
  species TEXT NOT NULL,
  stump_height REAL NOT NULL,
  stump_height_diameter INTEGER NOT NULL,
  stump_height_millimeter INTEGER,
  root_collar_diameter INTEGER NOT NULL,
  root_collar_millimeter INTEGER,
  rot_size REAL,
  rot_length REAL,
  decay_stage TEXT NOT NULL,
  FOREIGN KEY (proba_info_id) REFERENCES proba_info (id) ON DELETE CASCADE
)
''');
  }

  Future<void> _createSoilsTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS soils (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  proba_info_id INTEGER NOT NULL,
  soil_type TEXT NOT NULL,
  soil_moisture TEXT NOT NULL,
  soil_depth TEXT NOT NULL,
  upper_soil_horizon TEXT NOT NULL,
  lower_soil_horizon TEXT NOT NULL,
  ground_water_level REAL NOT NULL,
  litter_subhorizon REAL NOT NULL,
  fermentative_litter REAL NOT NULL,
  humified_litter REAL NOT NULL,
  peaty_humus REAL NOT NULL,
  coarse_humus REAL NOT NULL,
  humus REAL NOT NULL,
  humus_to_eluvial_transition REAL NOT NULL,
  podzolic_horizon REAL NOT NULL,
  second_humus REAL NOT NULL,
  classification_1977 TEXT NOT NULL,
  classification_2004 TEXT NOT NULL,
  wrb_2015 TEXT NOT NULL,
  note TEXT NOT NULL,
  FOREIGN KEY (proba_info_id) REFERENCES proba_info (id) ON DELETE CASCADE
)
''');
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
