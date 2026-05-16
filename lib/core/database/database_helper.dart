import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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

    await _createProbaInfoTable(db);
    await _createEyesTaxationTable(db);
    await _createTreeInformationTable(db);
    await _createUndergrowthTable(db);
    await _createUnderstoryTable(db);
    await _createDeadwoodTable(db);
    await _createStumpsTable(db);
    await _createSoilsTable(db);
  }

  Future<void> _createEyesTaxationTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS eyes_taxation (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  proba_info_id INTEGER NOT NULL,
  tier INTEGER NOT NULL,
  dominant_species TEXT NOT NULL,
  composition_coefficient REAL NOT NULL,
  age INTEGER NOT NULL,
  average_height REAL NOT NULL,
  diameter REAL NOT NULL,
  density REAL NOT NULL,
  forest_type TEXT NOT NULL,
  site_class TEXT NOT NULL,
  tlu TEXT NOT NULL,
  plantations_total INTEGER NOT NULL,
  coniferous_total INTEGER NOT NULL,
  dry_standing REAL NOT NULL,
  non_liquid_wood REAL NOT NULL,
  canopy_closure REAL NOT NULL,
  sparseness REAL NOT NULL,
  commercial_wood_output REAL NOT NULL,
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
  quarter INTEGER NOT NULL,
  allotment INTEGER NOT NULL,
  sample_plot_number INTEGER NOT NULL,
  sample_plot_area REAL NOT NULL
)
''');
  }

  Future<void> _createTreeInformationTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS tree_information (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  proba_info_id INTEGER NOT NULL,
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
