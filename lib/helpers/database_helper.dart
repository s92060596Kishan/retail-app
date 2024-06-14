// import 'dart:async';
// import 'dart:io';

// import 'package:flutter/services.dart';
// import 'package:path/path.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:skilltest/models/user_model.dart';
// import 'package:sqflite/sqflite.dart';

// class DatabaseHelper {
//   static final DatabaseHelper _instance = DatabaseHelper._internal();

//   factory DatabaseHelper() => _instance;

//   DatabaseHelper._internal();

//   static Database? _database;

//   Future<Database> get database async {
//     if (_database != null) return _database!;

//     _database = await _initDatabase();
//     return _database!;
//   }

//   Future<Database> _initDatabase() async {
//     final documentsDirectory = await getApplicationDocumentsDirectory();
//     final path = join(documentsDirectory.path, 'my.db');

//     // Check if the database already exists
//     if (FileSystemEntity.typeSync(path) == FileSystemEntityType.notFound) {
//       // Copy pre-populated database from assets if needed
//       ByteData data = await rootBundle.load('assets/my.db');
//       List<int> bytes =
//           data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
//       await File(path).writeAsBytes(bytes);
//     }

//     return await openDatabase(
//       path,
//       version: 1,
//       onCreate: _createDb,
//     );
//   }

//   void _createDb(Database db, int newVersion) async {
//     await db.execute('''
//       CREATE TABLE User (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         userName TEXT,
//         email TEXT,
//         phoneNumber TEXT,
//         password TEXT
//       )
//     ''');
//   }

//   // Future<int> insertUser(User user) async {
//   //   final db = await database;
//   //   return await db.insert('User', user.toMap());
//   // }

//   // Future<int> updateUser(User user) async {
//   //   final db = await database;
//   //   return await db.update(
//   //     'User',
//   //     user.toJsom(),
//   //     where: 'id = ?',
//   //     whereArgs: [user.id],
//   //   );
//   // }
//   // Future<User?> getUser(String email) async {
//   //   final db = await database;
//   //   final List<Map<String, dynamic>> maps = await db.query(
//   //     'User',
//   //     where: 'email = ?',
//   //     whereArgs: [email],
//   //   );

//   //   if (maps.isEmpty) return null;

//   //   return User.fromMap(maps.first);
//   // }

//   Future<User?> getUserByEmail(String email) async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db.query(
//       'User',
//       where: 'email = ?',
//       whereArgs: [email],
//     );

//     if (maps.isEmpty) return null;

//     return User.fromJson(maps.first);
//   }
//   // Add other CRUD operations as needed
// }
