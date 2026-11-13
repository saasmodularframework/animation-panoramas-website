import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Db {
  static Database? _d;
  static Future<Database> get db async => _d ??= await _open();

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'panoramas.db');
    return openDatabase(path, version: 1, onCreate: (d, v) async {
      await d.execute('CREATE TABLE admins(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE NOT NULL, salt TEXT NOT NULL, hash TEXT NOT NULL)');
      await d.execute('CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, body TEXT NOT NULL, created INTEGER NOT NULL)');
      await d.execute('CREATE TABLE bookings(id INTEGER PRIMARY KEY AUTOINCREMENT, service TEXT NOT NULL, whenMs INTEGER NOT NULL, note TEXT NOT NULL, created INTEGER NOT NULL)');
    });
  }

  static Future<List<Map<String, Object?>>> notes() async =>
      (await db).query('notes', orderBy: 'created DESC');
  static Future<void> addNote(String title, String body) async =>
      (await db).insert('notes', {'title': title, 'body': body, 'created': DateTime.now().millisecondsSinceEpoch});
  static Future<void> deleteNote(int id) async => (await db).delete('notes', where: 'id = ?', whereArgs: [id]);

  static Future<List<Map<String, Object?>>> bookings() async =>
      (await db).query('bookings', orderBy: 'whenMs ASC');
  static Future<void> addBooking(String service, DateTime when, String note) async =>
      (await db).insert('bookings', {
        'service': service,
        'whenMs': when.millisecondsSinceEpoch,
        'note': note,
        'created': DateTime.now().millisecondsSinceEpoch,
      });
  static Future<void> deleteBooking(int id) async => (await db).delete('bookings', where: 'id = ?', whereArgs: [id]);
)
  static String _hash(String salt, String pass) => sha256.convert(utf8.encode('$salt:$pass')).toString();
  static Future<bool> hasAdmin() async =>
      Sqflite.firstIntValue(await (await db).rawQuery('SELECT COUNT(*) FROM admins')) != 0;
  static Future<List<Map<String, Object?>>> admins() async => (await db).query('admins', columns: ['id', 'name']);

  static Future<void> createAdmin(String name, String pass) async {
    final salt = base64Url.encode(List<int>.generate(16, (_) => Random.secure().nextInt(256)));
    await (await db).insert('admins', {'name': name, 'salt': salt, 'hash': _hash(salt, pass)});
  }

  static Future<bool> verifyAdmin(String name, String pass) async {
    final r = await (await db).query('admins', where: 'name = ?', whereArgs: [name]);
    if (r.isEmpty) return false;
    return r.first['hash'] == _hash(r.first['salt'] as String, pass);
  }
}
