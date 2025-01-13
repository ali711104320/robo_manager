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
  String? _fileName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('صفحة تحميل ملف إكسل'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.upload_file,
              size: 100,
              color: const Color.fromARGB(255, 0, 0, 0),
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
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['xls', 'xlsx'],
                );

                if (result != null) {
                  _selectedFile = File(result.files.single.path!);
                  _fileName = result.files.single.name;

                  setState(() {});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم إلغاء اختيار الملف.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 205, 148, 13),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
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
              ElevatedButton(
                onPressed: () async {
                  if (_selectedFile != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('يرجى الانتظار...'),
                        backgroundColor: Colors.red,
                      ),
                    );

                    var bytes = _selectedFile!.readAsBytesSync();
                    var excel = Excel.decodeBytes(bytes);

                    try {
                      for (var table in excel.tables.keys) {
                        for (var row in excel.tables[table]!.rows) {
                          if (row[0] == "التاريخ" || row[0] == null)
                            continue; // تخطي الصفوف الفارغة أو صف الرأس
                          await DatabaseHelper.instance.create({
                            'date': row[0].toString(),
                            'currency': row[1].toString(),
                            'account': row[2].toString(),
                            'debit': row[3].toString(),
                            'credit': row[4].toString(),
                            'description': row[5].toString(),
                            'balance': row[6].toString(),
                          });
                        }
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'تم تخزين البيانات في قاعدة البيانات بنجاح.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('حدثت مشكلة أثناء حفظ البيانات: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text('حفظ البيانات في قاعدة البيانات'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
