import 'package:sqflite/sqflite.dart';

class SubjectsRepository {

  SubjectsRepository({required this.database});
  final Database database;

  // В будущем сюда можно добавить методы для работы с БД
  // Например, getAllSubjects(), getDistrictsBySubjectId() и т.д.
}
