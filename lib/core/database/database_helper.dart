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

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
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

    await _createEyesTaxationTable(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createEyesTaxationTable(db);
    }
  }

  Future<void> _createEyesTaxationTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS eyes_taxation (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tier INTEGER NOT NULL,
  dominant_species TEXT NOT NULL,
  composition_coefficient REAL NOT NULL,
  age INTEGER NOT NULL,
  average_height REAL NOT NULL,
  diameter REAL NOT NULL,
  density REAL NOT NULL,
  stock REAL NOT NULL,
  forest_type TEXT NOT NULL,
  site_class TEXT NOT NULL,
  tlu TEXT NOT NULL,
  plantations_total INTEGER NOT NULL,
  coniferous_total INTEGER NOT NULL,
  canopy_closure REAL NOT NULL,
  sparseness REAL NOT NULL,
  commercial_wood_output REAL NOT NULL,
  merchantability_class TEXT NOT NULL
)
''');
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
