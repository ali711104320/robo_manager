import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:excel/excel.dart';

class UploadExcelScreen extends StatefulWidget {
  @override
  _UploadExcelScreenState createState() => _UploadExcelScreenState();
}

class _UploadExcelScreenState extends State<UploadExcelScreen> {
  File? _selectedFile;
  String? _fileName;
  List<List<dynamic>>? _excelData;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('صفحة تحميل ملف إكسل'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.upload_file,
                    size: 100,
                    color: Colors.black,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'قم بتحميل ملفات إكسل هنا',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        _isLoading = true;
                      });

                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['xls', 'xlsx'],
                      );

                      if (result != null) {
                        _selectedFile = File(result.files.single.path!);
                        _fileName = result.files.single.name;

                        try {
                          var bytes = _selectedFile!.readAsBytesSync();
                          var excel = Excel.decodeBytes(bytes);

                          List<List<dynamic>> rows = [];
                          for (var table in excel.tables.keys) {
                            List<List<dynamic>> tableRows =
                                excel.tables[table]!.rows;
                            for (var row in tableRows) {
                              if (row.length >= 6 &&
                                  row.sublist(0, 6).any((cell) =>
                                      cell != null &&
                                      cell.toString().trim().isNotEmpty)) {
                                rows.add(row);
                              }
                            }
                          }

                          setState(() {
                            _excelData = rows;
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('حدث خطأ أثناء قراءة الملف: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تم إلغاء اختيار الملف.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }

                      setState(() {
                        _isLoading = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Text('تحميل ملف إكسل'),
                  ),
                  if (_fileName != null) ...[
                    SizedBox(height: 20),
                    Text(
                      'الملف المختار: $_fileName',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.deepPurple,
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                  if (_excelData != null && _excelData!.isNotEmpty) ...[
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              DataColumn(label: Text('1')),
                              DataColumn(label: Text('2')),
                              DataColumn(label: Text('3')),
                              DataColumn(label: Text('4')),
                              DataColumn(label: Text('5')),
                              DataColumn(label: Text('6')),
                            ],
                            rows: _excelData!
                                .sublist(1)
                                .where((row) =>
                                    !(row[0].toString().trim().isEmpty &&
                                        row[1].toString().trim().isEmpty &&
                                        row[2].toString().trim().isEmpty &&
                                        row[3].toString().trim().isEmpty &&
                                        row[4].toString().trim().isEmpty &&
                                        row[5].toString().trim().isEmpty))
                                .map(
                                  (row) => DataRow(
                                    cells: [
                                      DataCell(SelectableText(row.length > 0 &&
                                              row[0] != null &&
                                              row[0]
                                                  .runtimeType
                                                  .toString()
                                                  .contains('Data')
                                          ? row[0]
                                              .value
                                              .toString()
                                              .split('T')[0]
                                          : row[0]?.toString().split('T')[0] ??
                                              '')),
                                      DataCell(SelectableText(row.length > 1 &&
                                              row[1] != null &&
                                              row[1]
                                                  .runtimeType
                                                  .toString()
                                                  .contains('Data')
                                          ? row[1].value.toString()
                                          : row[1]?.toString() ?? '')),
                                      DataCell(SelectableText(row.length > 2 &&
                                              row[2] != null &&
                                              row[2]
                                                  .runtimeType
                                                  .toString()
                                                  .contains('Data')
                                          ? row[2].value.toString()
                                          : row[2]?.toString() ?? '')),
                                      DataCell(SelectableText(row.length > 3 &&
                                              row[3] != null &&
                                              row[3]
                                                  .runtimeType
                                                  .toString()
                                                  .contains('Data')
                                          ? row[3].value.toString()
                                          : row[3]?.toString() ?? '')),
                                      DataCell(SelectableText(row.length > 4 &&
                                              row[4] != null &&
                                              row[4]
                                                  .runtimeType
                                                  .toString()
                                                  .contains('Data')
                                          ? row[4].value.toString()
                                          : row[4]?.toString() ?? '')),
                                      DataCell(SelectableText(row.length > 5 &&
                                              row[5] != null &&
                                              row[5]
                                                  .runtimeType
                                                  .toString()
                                                  .contains('Data')
                                          ? row[5].value.toString()
                                          : row[5]?.toString() ?? '')),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ] else if (_excelData == null)
                    Expanded(
                      child: Center(
                        child: Text(
                          'لم يتم تحميل أي بيانات بعد.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
