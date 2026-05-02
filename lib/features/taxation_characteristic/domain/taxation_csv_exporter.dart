import 'dart:convert';

import 'package:file_picker/file_picker.dart';

final class TaxationCsvExporter {
  const TaxationCsvExporter();

  Future<String?> export(String csvContent) {
    final fileName =
        'eyes_taxation_${DateTime.now().millisecondsSinceEpoch}.csv';

    return _exportToSelectedDirectory(fileName, csvContent);
  }

  Future<String?> _exportToSelectedDirectory(
    String fileName,
    String csvContent,
  ) async {
    return FilePicker.saveFile(
      dialogTitle: 'Выберите директорию для выгрузки CSV',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      bytes: utf8.encode(csvContent),
    );
  }
}
