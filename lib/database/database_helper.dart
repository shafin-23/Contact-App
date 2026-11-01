import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/contact.dart';

class DatabaseHelper {
  static final DatabaseHelper instance =
  DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('contacts.db');

    return _database!;
  }

  // Initialize Database
  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Create Contacts Table
  Future<void> _createDB(
      Database db, int version) async {
    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL,
        address TEXT NOT NULL,
        isFavorite INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // CREATE - Insert Contact
  Future<int> insertContact(Contact contact) async {
    final db = await instance.database;

    return await db.insert(
      'contacts',
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // READ - Get All Contacts
  Future<List<Contact>> getContacts({
    String searchQuery = '',
    bool favoritesOnly = false,
  }) async {
    final db = await instance.database;

    String? where;
    List<dynamic> whereArgs = [];

    List<String> conditions = [];

    if (searchQuery.isNotEmpty) {
      conditions.add('name LIKE ?');
      whereArgs.add('%$searchQuery%');
    }

    if (favoritesOnly) {
      conditions.add('isFavorite = ?');
      whereArgs.add(1);
    }

    if (conditions.isNotEmpty) {
      where = conditions.join(' AND ');
    }

    final result = await db.query(
      'contacts',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return result.map((map) => Contact.fromMap(map)).toList();
  }

  // UPDATE - Update Contact
  Future<int> updateContact(Contact contact) async {
    final db = await instance.database;

    return await db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  // DELETE - Delete Contact
  Future<int> deleteContact(int id) async {
    final db = await instance.database;

    return await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Close Database
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}