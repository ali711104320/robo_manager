import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:robo_manager_for_clients/services/database_helper.dart';

class UploadExcelScreen extends StatefulWidget {
  @override
  _UploadExcelScreenState createState() => _UploadExcelScreenState();
}

class _UploadExcelScreenState extends State<UploadExcelScreen> {
  File? _selectedFile;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx'],
    );

    if (result != null) {
      _selectedFile = File(result.files.single.path!);
      _importExcelData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إلغاء اختيار الملف')),
      );
    }
  }

  Future<void> _importExcelData() async {
    if (_selectedFile == null) return;

    var bytes = _selectedFile!.readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    for (var table in excel.tables.keys) {
      var rows = excel.tables[table]!.rows;

      // نتخطى السطر الأول (العناوين) والسطر الثاني (إن وجد)
      for (int i = 2; i < rows.length - 1; i++) {
        var row = rows[i];

        if (row.length >= 6 &&
            row.sublist(0, 6).any(
                (cell) => cell != null && cell.toString().trim().isNotEmpty)) {
          String date = row[0]?.toString().split('T')[0] ?? '';
          String account = row[2]?.toString() ?? '';

          if (date.isEmpty || account.isEmpty) continue;

          List<Map<String, dynamic>> existingData =
              await DatabaseHelper.instance.queryAllRows();
          bool exists = existingData.any((element) =>
              element['date'] == date && element['account'] == account);

          if (!exists) {
            await DatabaseHelper.instance.create({
              'date': date,
              'currency': row[1]?.toString() ?? '',
              'account': account,
              'debit': row[3]?.toString() ?? '',
              'credit': row[4]?.toString() ?? '',
              'description': row[5]?.toString() ?? '',
              'balance': row[6]?.toString() ?? '',
            });
          }
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تمت إضافة البيانات بنجاح إلى قاعدة البيانات!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تحميل ملف إكسل')),
      body: Center(
        child: ElevatedButton(
          onPressed: _pickFile,
          child: Text('تحميل ملف إكسل'),
        ),
      ),
    );
  }
}
