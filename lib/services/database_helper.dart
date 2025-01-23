import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('client_data.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // إنشاء الجدول الرئيسي للتعاملات
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        currency TEXT NOT NULL,
        account TEXT NOT NULL,
        debit TEXT NOT NULL,
        credit TEXT NOT NULL,
        description TEXT NOT NULL,
        balance TEXT NOT NULL
      )
    ''');
  }

  Future<int> create(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('transactions', row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    final db = await instance.database;
    return await db.query('transactions');
  }

  Future<int> deleteAllRows() async {
    final db = await instance.database;
    return await db.delete('transactions');
  }

  // دالة لإنشاء جدول جديد لحساب معين
  Future<void> createTableForAccount(String accountName) async {
    final db = await instance.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $accountName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        currency TEXT NOT NULL,
        debit TEXT NOT NULL,
        credit TEXT NOT NULL,
        description TEXT NOT NULL,
        balance TEXT NOT NULL
      )
    ''');
  }

  // دالة لإدراج بيانات في جدول حساب معين
  Future<int> insertIntoAccountTable(
      String accountName, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert(accountName, row);
  }

  // دالة لتصدير البيانات وإنشاء جداول منفصلة لكل حساب
  Future<void> exportData() async {
    // جلب جميع البيانات من الجدول الرئيسي
    List<Map<String, dynamic>> transactions = await queryAllRows();

    // إنشاء مجموعة من الحسابات الفريدة
    Set<String> uniqueAccounts = transactions.map((transaction) {
      return transaction['account'].toString();
    }).toSet();

    // إنشاء جدول جديد لكل حساب وإدراج البيانات
    for (String account in uniqueAccounts) {
      // إنشاء جدول جديد للحساب
      await createTableForAccount(account);

      // تصفية البيانات للحساب الحالي
      List<Map<String, dynamic>> accountTransactions =
          transactions.where((transaction) {
        return transaction['account'].toString() == account;
      }).toList();

      // إدراج البيانات في الجدول الجديد
      for (Map<String, dynamic> transaction in accountTransactions) {
        await insertIntoAccountTable(account, transaction);
      }
    }
  }
}
