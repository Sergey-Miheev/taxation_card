import 'package:sqflite/sqflite.dart';

class SubjectsRepository {
  final Database database;

  SubjectsRepository({required this.database});

  // В будущем сюда можно добавить методы для работы с БД
  // Например, getAllSubjects(), getDistrictsBySubjectId() и т.д.
}
