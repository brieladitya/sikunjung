import '../core/database/database_helper.dart';
import 'auth_service.dart';

class KunjunganService {
  KunjunganService._();

  static final instance = KunjunganService._();

  Future<int> _uid() async {
    final user = await AuthService.instance.currentUser();
    if (user == null) throw StateError('Silakan login ulang');
    return user['id'] as int;
  }

  Future<List<Map<String, Object?>>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    return db.query(
      'kunjungan',
      where: 'user_id = ?',
      whereArgs: [await _uid()],
      orderBy: 'tanggal_kunjungan DESC, id DESC',
    );
  }

  Future<int> tambah({
    required String nama,
    required String alamat,
    required String telepon,
    required String catatan,
    required String status,
    double? latitude,
    double? longitude,
    double? akurasi,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();
    return db.insert('kunjungan', {
      'user_id': await _uid(),
      'nama_pelanggan': nama.trim(),
      'alamat': alamat.trim(),
      'nomor_telepon': telepon.trim(),
      'catatan': catatan.trim(),
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'akurasi_gps': akurasi,
      'tanggal_kunjungan': now,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<int> ubah(int id, Map<String, Object?> perubahan) async {
    final db = await DatabaseHelper.instance.database;
    return db.update(
      'kunjungan',
      {...perubahan, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, await _uid()],
    );
  }

  Future<int> hapus(int id) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete(
      'kunjungan',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, await _uid()],
    );
  }
}
