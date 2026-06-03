import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';

final class HomeCsvExporter {
  const HomeCsvExporter({required Database database}) : _database = database;

  final Database _database;

  Future<int?> exportProbaInfoData(int probaInfoId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    var exportedFilesCount = 0;

    for (final table in _tables) {
      final rows = await _database.query(
        table.name,
        columns: table.columns,
        where: table.where,
        whereArgs: [probaInfoId],
        orderBy: 'id ASC',
      );
      final csv = _buildCsv(headers: table.headers, rows: rows);
      final fileName = '${table.name}_${probaInfoId}_$timestamp.csv';
      final savedPath = await FilePicker.saveFile(
        dialogTitle: 'Сохраните $fileName',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        bytes: Uint8List.fromList(utf8.encode(csv)),
      );
      if (savedPath != null) {
        exportedFilesCount++;
      }
    }

    return exportedFilesCount;
  }

  String _buildCsv({
    required List<String> headers,
    required List<Map<String, Object?>> rows,
  }) {
    final buffer = StringBuffer('\uFEFF')
      ..writeln(headers.map(_escapeCsvValue).join(';'));

    for (final row in rows) {
      buffer.writeln(
        row.values
            .map((value) => _escapeCsvValue(value?.toString() ?? ''))
            .join(';'),
      );
    }

    return buffer.toString();
  }

  String _escapeCsvValue(String value) {
    if (value.contains(';') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }

    return value;
  }

  static const _tables = [
    _CsvTable(
      name: 'proba_info',
      columns: [
        'id',
        'region',
        'district',
        'forestry',
        'sub_forestry',
        'dominant_species',
        'site_class',
        'forest_type',
        'tlu',
        'soil',
        'living_ground_cover',
        'undergrowth',
        'understory',
        'quarter',
        'allotment',
        'sample_plot_number',
        'sample_plot_area',
        'deadwood_area',
        'stumps_accounting_area',
        'undergrowth_plot_count',
        'undergrowth_plot_area',
        'understory_plot_count',
        'understory_plot_area',
      ],
      headers: [
        'id',
        'Регион',
        'Район',
        'Лесничество',
        'Участковое лесничество',
        'Преобладающая порода',
        'Класс бонитета',
        'Тип леса',
        'ТЛУ',
        'Почва',
        'Живой почвенный покров',
        'Подрост',
        'Подлесок',
        'Квартал',
        'Выдел',
        'Номер пробной площади',
        'Площадь пробной площади',
        'Площадь валёжника',
        'Площадь учёта пней',
        'Количество учетных площадок подроста',
        'Площадь учетных площадок подроста',
        'Количество учетных площадок подлеска',
        'Площадь учетных площадок подлеска',
      ],
      where: 'id = ?',
    ),
    _CsvTable(
      name: 'eyes_taxation',
      columns: [
        'id',
        'proba_info_id',
        'tier',
        'composition_coefficient',
        'species',
        'average_height',
        'diameter',
        'age',
        'origin',
        'merchantability_class',
      ],
      headers: [
        'id',
        'proba_info_id',
        'Номер яруса',
        'Состав яруса',
        'Порода',
        'Высота, м',
        'Диаметр, см',
        'Возраст, лет',
        'Происхождение',
        'Класс товарности',
      ],
    ),
    _CsvTable(
      name: 'tree_information',
      columns: [
        'id',
        'proba_info_id',
        'tree_number',
        'wood_quality',
        'species',
        'd1',
        'd2',
        'right_column_number',
        'tree_age',
        'tree_height',
      ],
      headers: [
        'id',
        'proba_info_id',
        'Номер дерева',
        'Качество древесины',
        'Порода',
        'd1',
        'd2',
        'Номер правой колонки',
        'Возраст дерева',
        'Высота дерева',
      ],
    ),
    _CsvTable(
      name: 'undergrowth',
      columns: _undergrowthColumns,
      headers: _undergrowthHeaders,
    ),
    _CsvTable(
      name: 'understory',
      columns: _growthColumns,
      headers: _growthHeaders,
    ),
    _CsvTable(
      name: 'deadwood',
      columns: [
        'id',
        'proba_info_id',
        'species',
        'length',
        'diameter',
        'millimeter',
        'rot_size',
        'rot_length',
        'decay_stage',
      ],
      headers: [
        'id',
        'proba_info_id',
        'Порода',
        'Длина',
        'Диаметр',
        'Миллиметр',
        'Размер гнили',
        'Длина гнили',
        'Стадия разложения',
      ],
    ),
    _CsvTable(
      name: 'stumps',
      columns: [
        'id',
        'proba_info_id',
        'species',
        'stump_height',
        'stump_height_diameter',
        'stump_height_millimeter',
        'root_collar_diameter',
        'root_collar_millimeter',
        'rot_size',
        'rot_length',
        'decay_stage',
      ],
      headers: [
        'id',
        'proba_info_id',
        'Порода',
        'Высота пня',
        'Диаметр на высоте пня',
        'Миллиметр на высоте пня',
        'Диаметр у корневой шейки',
        'Миллиметр у корневой шейки',
        'Размер гнили',
        'Длина гнили',
        'Стадия разложения',
      ],
    ),
    _CsvTable(
      name: 'soils',
      columns: [
        'id',
        'proba_info_id',
        'soil_type',
        'soil_moisture',
        'soil_depth',
        'upper_soil_horizon',
        'lower_soil_horizon',
        'ground_water_level',
        'litter_subhorizon',
        'fermentative_litter',
        'humified_litter',
        'peaty_humus',
        'coarse_humus',
        'humus',
        'humus_to_eluvial_transition',
        'podzolic_horizon',
        'second_humus',
        'classification_1977',
        'classification_2004',
        'wrb_2015',
        'note',
      ],
      headers: [
        'id',
        'proba_info_id',
        'Тип почв',
        'Влажность почвы',
        'Мощность почвы',
        'Верхние почвенные горизонты',
        'Нижние почвенные горизонты',
        'Уровень грунтовых вод (верховодки), см',
        'Подгоризонт опада, см',
        'Ферментативный горизонт подстилки, см',
        'Гумифицированный слой подстилки, см',
        'Перегнойный и торфяный, см',
        'Грубогумусовый, см',
        'Гумусовый, см',
        'Переходный от гумусового к элювиальному, см',
        'Подзолистый горизонт, см',
        'Второй гумусовый, см',
        'По классификации 1977 года',
        'По классификации 2004 года',
        'По международной классификации WRB 2015',
        'Примечание',
      ],
    ),
  ];

  static const _growthColumns = [
    'id',
    'proba_info_id',
    'plot_number',
    'species',
    'origin',
    'small_living',
    'small_damaged',
    'medium_living',
    'medium_damaged',
    'model_age',
    'model_height',
    'model_diameter',
    'large_151_25_living',
    'large_151_25_damaged',
    'large_251_35_living',
    'large_251_35_damaged',
    'large_351_45_living',
    'large_351_45_damaged',
    'large_451_55_living',
    'large_451_55_damaged',
    'large_551_plus_living',
    'large_551_plus_damaged',
    'large_model_age',
    'large_model_height',
    'large_model_diameter',
  ];

  static const _growthHeaders = [
    'id',
    'proba_info_id',
    'Номер площадки',
    'Порода',
    'Происхождение',
    'Мелкий живой',
    'Мелкий повреждённый',
    'Средний живой',
    'Средний повреждённый',
    'Модельный возраст',
    'Модельная высота',
    'Модельный диаметр',
    'Крупный 151-25 живой',
    'Крупный 151-25 повреждённый',
    'Крупный 251-35 живой',
    'Крупный 251-35 повреждённый',
    'Крупный 351-45 живой',
    'Крупный 351-45 повреждённый',
    'Крупный 451-55 живой',
    'Крупный 451-55 повреждённый',
    'Крупный 551+ живой',
    'Крупный 551+ повреждённый',
    'Крупный модельный возраст',
    'Крупная модельная высота',
    'Крупный модельный диаметр',
  ];

  static const _undergrowthColumns = [
    'id',
    'proba_info_id',
    'plot_number',
    'species',
    'small_living',
    'small_damaged',
    'medium_living',
    'medium_damaged',
    'model_age',
    'model_height',
    'model_diameter',
    'large_151_25_living',
    'large_151_25_damaged',
    'large_251_35_living',
    'large_251_35_damaged',
    'large_351_45_living',
    'large_351_45_damaged',
    'large_451_55_living',
    'large_451_55_damaged',
    'large_551_plus_living',
    'large_551_plus_damaged',
    'large_model_age',
    'large_model_height',
    'large_model_diameter',
  ];

  static const _undergrowthHeaders = [
    'id',
    'proba_info_id',
    'Номер площадки',
    'Порода',
    'Мелкий живой',
    'Мелкий повреждённый',
    'Средний живой',
    'Средний повреждённый',
    'Модельный возраст',
    'Модельная высота',
    'Модельный диаметр',
    'Крупный 151-25 живой',
    'Крупный 151-25 повреждённый',
    'Крупный 251-35 живой',
    'Крупный 251-35 повреждённый',
    'Крупный 351-45 живой',
    'Крупный 351-45 повреждённый',
    'Крупный 451-55 живой',
    'Крупный 451-55 повреждённый',
    'Крупный 551+ живой',
    'Крупный 551+ повреждённый',
    'Крупный модельный возраст',
    'Крупная модельная высота',
    'Крупный модельный диаметр',
  ];
}

final class _CsvTable {
  const _CsvTable({
    required this.name,
    required this.columns,
    required this.headers,
    this.where = 'proba_info_id = ?',
  });

  final String name;
  final List<String> columns;
  final List<String> headers;
  final String where;
}
