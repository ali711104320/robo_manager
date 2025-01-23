import 'package:flutter/material.dart';
import 'package:robo_manager_for_clients/Screen/tables_screen.dart';
import 'package:robo_manager_for_clients/services/database_helper.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<List<Map<String, dynamic>>> _transactions;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool ascending = true;
  bool isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    setState(() {
      _transactions = DatabaseHelper.instance.queryAllRows();
    });
  }

  void _deleteAllData() async {
    await DatabaseHelper.instance.deleteAllRows();
    _loadTransactions();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حذف جميع البيانات بنجاح!')),
    );
  }

  String _cleanCurrency(String currency) {
    final match = RegExp(r'Data\((.*?),').firstMatch(currency);
    if (match != null && match.groupCount > 0) {
      return match.group(1)!.trim();
    }
    return currency;
  }

  String _cleanAccount(String account) {
    final match = RegExp(r'Data\((.*?),').firstMatch(account);
    if (match != null && match.groupCount > 0) {
      return match.group(1)!.trim();
    }
    return account;
  }

  String _cleanNumeric(String numeric) {
    final match = RegExp(r'Data\((\d+)[,)]').firstMatch(numeric);
    if (match != null && match.groupCount > 0) {
      return match.group(1)!.trim();
    }
    return numeric;
  }

  String _cleanDescription(String description) {
    final match = RegExp(r'Data\((.*?),').firstMatch(description);
    if (match != null && match.groupCount > 0) {
      return match.group(1)!.trim();
    }
    return description;
  }

  double _calculateBalance(String credit, String debit) {
    final creditValue = double.tryParse(_cleanNumeric(credit)) ?? 0.0;
    final debitValue = double.tryParse(_cleanNumeric(debit)) ?? 0.0;
    return creditValue - debitValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearchActive
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'بحث حسب الحساب',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.trim();
                  });
                },
              )
            : Text('التقارير المالية'),
        actions: [
          IconButton(
            icon: Icon(isSearchActive ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (isSearchActive) {
                  searchController.clear();
                  searchQuery = '';
                }
                isSearchActive = !isSearchActive;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _deleteAllData,
          ),
          IconButton(
            icon: Icon(Icons.table_chart), // الأيقونة المطلوبة
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TablesScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _transactions,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.data!.isEmpty) {
                  return Center(child: Text('لا توجد بيانات متاحة.'));
                } else {
                  var filteredData = snapshot.data!.where((transaction) {
                    final account =
                        _cleanAccount(transaction['account']?.toString() ?? '');
                    return account.contains(
                        searchQuery); // التصفية بناءً على البحث في الحساب
                  }).toList();

                  double totalDebit =
                      filteredData.fold(0.0, (sum, transaction) {
                    return sum +
                        (double.tryParse(_cleanNumeric(
                                transaction['debit'].toString())) ??
                            0.0);
                  });
                  double totalCredit =
                      filteredData.fold(0.0, (sum, transaction) {
                    return sum +
                        (double.tryParse(_cleanNumeric(
                                transaction['credit'].toString())) ??
                            0.0);
                  });

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        border: TableBorder.all(color: Colors.grey),
                        columnSpacing: 20,
                        columns: [
                          DataColumn(label: Text('التاريخ'), numeric: true),
                          DataColumn(label: Text('العملة')),
                          DataColumn(label: Text('الحساب')),
                          DataColumn(label: Text('مدين')),
                          DataColumn(label: Text('دائن')),
                          DataColumn(label: Text('البيان')),
                          DataColumn(label: Text('الرصيد')),
                        ],
                        rows: [
                          ...filteredData.map((transaction) {
                            return DataRow(cells: [
                              DataCell(SelectableText(
                                transaction['date']
                                    .toString()
                                    .replaceAll('Data(', '')
                                    .replaceAll(')', ''),
                                style: TextStyle(fontSize: 14),
                              )),
                              DataCell(SelectableText(
                                _cleanCurrency(
                                    transaction['currency'].toString()),
                                style: TextStyle(fontSize: 14),
                              )),
                              DataCell(SelectableText(
                                _cleanAccount(
                                    transaction['account'].toString()),
                                style: TextStyle(fontSize: 14),
                              )),
                              DataCell(SelectableText(
                                _cleanNumeric(transaction['debit'].toString()),
                                style: TextStyle(fontSize: 14),
                              )),
                              DataCell(SelectableText(
                                _cleanNumeric(transaction['credit'].toString()),
                                style: TextStyle(fontSize: 14),
                              )),
                              DataCell(SelectableText(
                                _cleanDescription(
                                    transaction['description'].toString()),
                                style: TextStyle(fontSize: 14),
                              )),
                              DataCell(SelectableText(
                                _calculateBalance(
                                        transaction['credit'].toString(),
                                        transaction['debit'].toString())
                                    .toStringAsFixed(2),
                                style: TextStyle(fontSize: 14),
                              )),
                            ]);
                          }).toList(),
                          DataRow(cells: [
                            DataCell(Text('')),
                            DataCell(Text('')),
                            DataCell(Text('')),
                            DataCell(Text(totalDebit.toStringAsFixed(2),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red))),
                            DataCell(Text(totalCredit.toStringAsFixed(2),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green))),
                            DataCell(Text('')),
                            DataCell(Text(
                                (totalCredit - totalDebit).toStringAsFixed(2),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue))),
                          ]),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
