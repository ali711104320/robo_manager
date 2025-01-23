import 'package:flutter/material.dart';
import 'package:robo_manager_for_clients/services/database_helper.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class TablesScreen extends StatefulWidget {
  @override
  _TablesScreenState createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  late Future<List<Map<String, dynamic>>> _transactions;
  bool _isGeneratingPDF = false; // متغير لتتبع حالة إنشاء PDF

  @override
  void initState() {
    super.initState();
    _transactions = _loadTransactions();
  }

  Future<List<Map<String, dynamic>>> _loadTransactions() async {
    return await DatabaseHelper.instance.queryAllRows();
  }

  String _cleanCurrency(String currency) {
    final match = RegExp(r'Data\((.*?),').firstMatch(currency);
    if (match != null && match.groupCount > 0) {
      return match.group(1)!.trim();
    }
    return currency.isEmpty ? 'غير محدد' : currency;
  }

  String _cleanAccount(String account) {
    if (account.isEmpty) return 'غير معروف';
    final match = RegExp(r'Data\((.*?),').firstMatch(account);
    if (match != null && match.groupCount > 0) {
      return match.group(1)!.trim();
    }
    return account;
  }

  String _cleanDate(String rawDate) {
    if (rawDate.isEmpty) return 'غير معروف';
    return rawDate.replaceAll(RegExp(r'Data\(|\)'), '');
  }

  String _cleanNumeric(String numeric) {
    if (numeric.isEmpty) return '0.00';
    final match = RegExp(r'Data\((\d+)[,)]').firstMatch(numeric);
    if (match != null && match.groupCount > 0) {
      return match.group(1)!.trim();
    }
    return numeric;
  }

  String _cleanDescription(String description) {
    if (description.isEmpty) return 'لا يوجد بيان';
    final match = RegExp(r'Data\((.*?),').firstMatch(description);
    if (match != null && match.groupCount > 0) {
      return match.group(1)!.trim();
    }
    return description;
  }

  void _printPDF(List<Map<String, dynamic>> accountTransactions) async {
    setState(() {
      _isGeneratingPDF = true; // تمكين مؤشر التحميل
    });

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 20),
                child: pw.Center(
                  child: pw.Text(
                    'تقارير المعاملات المالية',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                ),
              ),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: pw.FlexColumnWidth(2), // التاريخ
                  1: pw.FlexColumnWidth(1.5), // العملة
                  2: pw.FlexColumnWidth(2), // الحساب
                  3: pw.FlexColumnWidth(1.5), // مدين
                  4: pw.FlexColumnWidth(1.5), // دائن
                  5: pw.FlexColumnWidth(3), // البيان
                },
                children: [
                  // عناوين الأعمدة
                  pw.TableRow(
                    children: [
                      pw.Text('التاريخ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('العملة',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('الحساب',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('مدين',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('دائن',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('البيان',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  // البيانات
                  ...accountTransactions.map((transaction) {
                    return pw.TableRow(
                      children: [
                        pw.Text(_cleanDate(transaction['date'].toString()),
                            style: pw.TextStyle(fontSize: 12)),
                        pw.Text(
                            _cleanCurrency(transaction['currency'].toString()),
                            style: pw.TextStyle(fontSize: 12)),
                        pw.Text(
                            _cleanAccount(transaction['account'].toString()),
                            style: pw.TextStyle(fontSize: 12)),
                        pw.Text(_cleanNumeric(transaction['debit'].toString()),
                            style: pw.TextStyle(fontSize: 12)),
                        pw.Text(_cleanNumeric(transaction['credit'].toString()),
                            style: pw.TextStyle(fontSize: 12)),
                        pw.Text(
                            _cleanDescription(
                                transaction['description'].toString()),
                            style: pw.TextStyle(fontSize: 12)),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());

    setState(() {
      _isGeneratingPDF = false; // تعطيل مؤشر التحميل بعد الانتهاء
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'جداول التقارير المالية',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _transactions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ أثناء تحميل البيانات.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('لا توجد بيانات متاحة.'));
          } else {
            Map<String, List<Map<String, dynamic>>> groupedData = {};
            for (var transaction in snapshot.data!) {
              String account =
                  _cleanAccount(transaction['account']?.toString() ?? '');
              groupedData.putIfAbsent(account, () => []).add(transaction);
            }

            return ListView.builder(
              itemCount: groupedData.keys.length,
              itemBuilder: (context, index) {
                String accountName = groupedData.keys.elementAt(index);
                List<Map<String, dynamic>> accountTransactions =
                    groupedData[accountName]!;

                double totalDebit = 0.0;
                double totalCredit = 0.0;

                for (var transaction in accountTransactions) {
                  totalDebit +=
                      double.tryParse(transaction['debit'].toString()) ?? 0.0;
                  totalCredit +=
                      double.tryParse(transaction['credit'].toString()) ?? 0.0;
                }

                double balanceDifference = totalCredit - totalDebit;

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 4,
                  child: ExpansionTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SelectableText(
                          accountName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: _isGeneratingPDF
                              ? CircularProgressIndicator(
                                  color: Colors.blue) // مؤشر تحميل
                              : Icon(Icons.print, color: Colors.blue),
                          onPressed: _isGeneratingPDF
                              ? null // تعطيل الزر أثناء التحميل
                              : () {
                                  _printPDF(accountTransactions);
                                },
                        ),
                      ],
                    ),
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          border: TableBorder.all(color: Colors.grey.shade300),
                          columnSpacing: 20,
                          headingRowColor: MaterialStateColor.resolveWith(
                              (states) => Colors.grey.shade200),
                          columns: [
                            DataColumn(label: Text('التاريخ')),
                            DataColumn(label: Text('العملة')),
                            DataColumn(label: Text('الحساب')),
                            DataColumn(label: Text('مدين')),
                            DataColumn(label: Text('دائن')),
                            DataColumn(label: Text('البيان')),
                          ],
                          rows: [
                            ...accountTransactions.map((transaction) {
                              return DataRow(cells: [
                                DataCell(SelectableText(
                                    _cleanDate(transaction['date'].toString()),
                                    style: TextStyle(fontSize: 14))),
                                DataCell(SelectableText(
                                    _cleanCurrency(
                                        transaction['currency'].toString()),
                                    style: TextStyle(fontSize: 14))),
                                DataCell(SelectableText(
                                    _cleanAccount(
                                        transaction['account'].toString()),
                                    style: TextStyle(fontSize: 14))),
                                DataCell(SelectableText(
                                    _cleanNumeric(
                                        transaction['debit'].toString()),
                                    style: TextStyle(fontSize: 14))),
                                DataCell(SelectableText(
                                    _cleanNumeric(
                                        transaction['credit'].toString()),
                                    style: TextStyle(fontSize: 14))),
                                DataCell(SelectableText(
                                    _cleanDescription(
                                        transaction['description'].toString()),
                                    style: TextStyle(fontSize: 14))),
                              ]);
                            }).toList(),
                            DataRow(cells: [
                              DataCell(Text('')),
                              DataCell(Text('')),
                              DataCell(Text('الإجمالي',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(SelectableText(
                                  totalDebit.toStringAsFixed(2))),
                              DataCell(SelectableText(
                                  totalCredit.toStringAsFixed(2))),
                              DataCell(Text('')),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
