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
      version: 1,
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

  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
