import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:taxation_card/core/database/database_helper.dart';

final class DatabaseExporter {
  const DatabaseExporter({required Database database}) : _database = database;

  final Database _database;

  Future<String?> exportToSelectedDirectory() async {
    await _database.rawQuery('PRAGMA wal_checkpoint(FULL)');

    final sourceFile = File(_database.path);
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final fileName =
        '${p.basenameWithoutExtension(sourceFile.path)}_$timestamp${p.extension(sourceFile.path)}';
    final savedPath = await FilePicker.saveFile(
      dialogTitle: 'Выберите папку для экспорта базы данных',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['db'],
      bytes: Uint8List.fromList(await sourceFile.readAsBytes()),
    );

    return savedPath;
  }

  Future<bool> importFromSelectedFile() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Выберите базу данных для импорта',
      type: FileType.custom,
      allowedExtensions: const ['db', 'sqlite', 'sqlite3'],
      withData: true,
    );
    final selectedFile = result?.files.singleOrNull;
    if (selectedFile == null) {
      return false;
    }

    final bytes = await _readSelectedFileBytes(selectedFile);
    final temporaryFile = File(
      p.join(p.dirname(_database.path), '_selected_database_import.db'),
    );
    await temporaryFile.writeAsBytes(bytes, flush: true);

    await _validateDatabaseFile(temporaryFile.path);
    await DatabaseHelper.instance.close();
    await _deleteDatabaseFiles(_database.path);
    await File(_database.path).writeAsBytes(bytes, flush: true);
    await temporaryFile.delete().catchError((Object _) => temporaryFile);

    return true;
  }

  Future<Uint8List> _readSelectedFileBytes(PlatformFile selectedFile) async {
    final bytes = selectedFile.bytes;
    if (bytes != null) {
      return bytes;
    }

    final path = selectedFile.path;
    if (path != null) {
      return File(path).readAsBytes();
    }

    throw const FileSystemException('Selected database is unavailable');
  }

  Future<void> _validateDatabaseFile(String path) async {
    final importedDatabase = await openReadOnlyDatabase(path);
    try {
      for (final table in _tables) {
        final currentColumns = await _columnsForTable(_database, table);
        final importedColumns = await _columnsForTable(importedDatabase, table);

        if (currentColumns.isEmpty ||
            importedColumns.length != currentColumns.length ||
            !currentColumns.every(importedColumns.contains)) {
          throw FileSystemException(
            'Imported database has incompatible table: $table',
          );
        }
      }
    } finally {
      await importedDatabase.close();
    }
  }

  Future<List<String>> _columnsForTable(
    DatabaseExecutor database,
    String table, {
    String? schema,
  }) async {
    final pragma = schema == null
        ? 'PRAGMA table_info(${_quoteIdentifier(table)})'
        : 'PRAGMA ${_quoteIdentifier(schema)}.table_info(${_quoteIdentifier(table)})';
    final rows = await database.rawQuery(pragma);

    return [
      for (final row in rows)
        if (row['name'] case final String name) name,
    ];
  }

  String _quoteIdentifier(String value) {
    return '"${value.replaceAll('"', '""')}"';
  }

  Future<void> _deleteDatabaseFiles(String databasePath) async {
    for (final path in [
      databasePath,
      '$databasePath-wal',
      '$databasePath-shm',
    ]) {
      await File(path).delete().catchError((Object _) => File(path));
    }
  }

  static const _tables = [
    'federation_subjects',
    'subject_districts',
    'district_forestries',
    'sub_forestries',
    'proba_info',
    'eyes_taxation',
    'tree_information',
    'undergrowth',
    'understory',
    'deadwood',
    'stumps',
    'soils',
  ];
}
