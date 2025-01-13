import 'package:flutter/material.dart';
import 'package:robo_manager_for_clients/services/database_helper.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<List<Map<String, dynamic>>> _transactions;

  @override
  void initState() {
    super.initState();
    _transactions = DatabaseHelper.instance.queryAllRows();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('التقارير'),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _transactions,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.data!.isEmpty) {
            return Center(child: Text('لا توجد بيانات.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final transaction = snapshot.data![index];
                return ListTile(
                  title: Text('التاريخ: ${transaction['date']}'),
                  subtitle: Text(
                    'العملة: ${transaction['currency']}\n'
                    'الحساب: ${transaction['account']}\n'
                    'مدين: ${transaction['debit']}\n'
                    'دائن: ${transaction['credit']}\n'
                    'البيان: ${transaction['description']}\n'
                    'الرصيد: ${transaction['balance']}',
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
