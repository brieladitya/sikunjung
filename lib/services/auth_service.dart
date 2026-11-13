import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/database/database_helper.dart';

class AuthService {
  AuthService._();

  static final instance = AuthService._();
  static const _storage = FlutterSecureStorage();
  static const _sessionKey = 'sikunjung_user_id';

  String _hash(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> createDemoAccount() async {
    final db = await DatabaseHelper.instance.database;
    final found = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: ['petugas'],
    );
    if (found.isNotEmpty) return;

    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    final saltString = base64Encode(saltBytes);

    await db.insert('users', {
      'username': 'petugas',
      'nama': 'Petugas Lapangan',
      'password_hash': _hash('Demo@12345', saltString),
      'password_salt': saltString,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<dynamic> login(String username, String password) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username.trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final user = rows.first;
    final expectedHash = user['password_hash'] as String;
    final salt = user['password_salt'] as String;

    final actualHash = _hash(password, salt);

    if (expectedHash != actualHash) return null;

    await _storage.write(key: _sessionKey, value: '${user['id']}');
    return user;
  }

  Future<dynamic> currentUser() async {
    final raw = await _storage.read(key: _sessionKey);
    final id = int.tryParse(raw ?? '');
    if (id == null) return null;

    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'users',
      columns: ['id', 'username', 'nama'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      await logout();
      return null;
    }
    return rows.first;
  }

  Future<void> logout() => _storage.delete(key: _sessionKey);
}