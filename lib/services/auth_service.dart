import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/database/database_helper.dart';

class AuthService {
  AuthService._();

  static final instance = AuthService._();
  static const _storage = FlutterSecureStorage();
  static const _sessionKey = 'sikunjung_user_id';
  final _algorithm = Argon2id(
    memory: 19456,
    iterations: 2,
    parallelism: 1,
    hashLength: 32,
  );

  Future<String> _hash(String password, List<int> salt) async {
    final key = await _algorithm.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    return base64Encode(await key.extractBytes());
  }

  Future<void> createDemoAccount() async {
    if (!kDebugMode) return;
    final db = await DatabaseHelper.instance.database;
    final found = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: ['petugas'],
    );
    if (found.isNotEmpty) return;
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    await db.insert('users', {
      'username': 'petugas',
      'nama': 'Petugas Lapangan',
      'password_hash': await _hash('Demo@12345', salt),
      'password_salt': base64Encode(salt),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, Object?>?> login(String username, String password) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username.trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final user = rows.first;
    final expected = user['password_hash'] as String;
    final actual = await _hash(
      password,
      base64Decode(user['password_salt'] as String),
    );
    // Bandingkan menggunakan pembandingan konstan-waktu
    // dalam implementasi final (lihat catatan keamanan).
    if (!_sameBytes(base64Decode(expected), base64Decode(actual))) return null;
    await _storage.write(key: _sessionKey, value: '${user['id']}');
    return user;
  }

  bool _sameBytes(List<int> a, List<int> b) {
    int diff = a.length ^ b.length;
    for (var i = 0; i < max(a.length, b.length); i++) {
      diff |= (i < a.length ? a[i] : 0) ^ (i < b.length ? b[i] : 0);
    }
    return diff == 0;
  }

  Future<Map<String, Object?>?> currentUser() async {
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
