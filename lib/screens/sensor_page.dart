import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../widgets/app_navbar.dart';

class SensorPage extends StatefulWidget {
  const SensorPage({super.key});

  @override
  State<SensorPage> createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  AccelerometerEvent? _accel;
  GyroscopeEvent? _gyro;
  MagnetometerEvent? _mag;

  bool _aktif = true;
  String? _errAccel;
  String? _errGyro;
  String? _errMag;

  @override
  void initState() {
    super.initState();
    _mulaiSensor();
  }

  void _mulaiSensor() {
    _hentikanSensor();
    setState(() {
      _aktif = true;
      _errAccel = null;
      _errGyro = null;
      _errMag = null;
    });

    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen(
          (event) {
        if (mounted) setState(() => _accel = event);
      },
      onError: (_) {
        if (mounted) {
          setState(() => _errAccel = 'Sensor Accelerometer tidak tersedia');
        }
      },
    );

    _gyroSub = gyroscopeEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen(
          (event) {
        if (mounted) setState(() => _gyro = event);
      },
      onError: (_) {
        if (mounted) {
          setState(() => _errGyro = 'Sensor Gyroscope tidak tersedia');
        }
      },
    );

    _magSub = magnetometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen(
          (event) {
        if (mounted) setState(() => _mag = event);
      },
      onError: (_) {
        if (mounted) {
          setState(() => _errMag = 'Sensor Magnetometer tidak tersedia');
        }
      },
    );
  }

  void _hentikanSensor() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    _accelSub = null;
    _gyroSub = null;
    _magSub = null;
  }

  @override
  void dispose() {
    _hentikanSensor();
    super.dispose();
  }

  double _derajatKompas(MagnetometerEvent m) {
    double deg = atan2(m.y, m.x) * (180 / pi);
    if (deg < 0) deg += 360;
    return deg;
  }

  String _arahMataAngin(double deg) {
    const arah = [
      'Utara (U)',
      'Timur Laut (TL)',
      'Timur (T)',
      'Tenggara (TG)',
      'Selatan (S)',
      'Barat Daya (BD)',
      'Barat (B)',
      'Barat Laut (BL)',
    ];
    return arah[((deg + 22.5) % 360) ~/ 45];
  }

  @override
  Widget build(BuildContext context) {
    final double? derajat = _mag != null ? _derajatKompas(_mag!) : null;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color warnaAksen =
    isDark ? const Color(0xFF7CB2FF) : const Color(0xFF1765D1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Perangkat'),
        backgroundColor: const Color(0xFF1765D1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: _aktif ? 'Hentikan sensor' : 'Mulai sensor',
            icon: Icon(
              _aktif ? Icons.pause_circle_outline : Icons.play_circle_outline,
            ),
            onPressed: () {
              if (_aktif) {
                _hentikanSensor();
                setState(() => _aktif = false);
              } else {
                _mulaiSensor();
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: const AppNavbar(currentIndex: -1),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Monitoring Sensor',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Pantau pergerakan, rotasi, dan arah kompas perangkat secara real-time.',
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: isDark
                ? const Color(0xFF1A2A42)
                : const Color(0xFFECF3FD),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.explore, color: warnaAksen, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Kompas Digital (Magnetometer)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_errMag != null)
                    Text(
                      _errMag!,
                      style: TextStyle(
                        color: isDark ? Colors.red.shade300 : Colors.red,
                      ),
                    )
                  else ...[
                    Text(
                      derajat != null ? '${derajat.toStringAsFixed(1)}°' : '-',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: warnaAksen,
                      ),
                    ),
                    Text(
                      derajat != null
                          ? _arahMataAngin(derajat)
                          : 'Membaca sensor...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _KartuSensor(
            icon: Icons.screen_rotation_alt,
            judul: 'Accelerometer',
            deskripsi: 'Percepatan perangkat termasuk gravitasi',
            error: _errAccel,
            x: _accel?.x,
            y: _accel?.y,
            z: _accel?.z,
            satuan: 'm/s²',
          ),
          const SizedBox(height: 14),
          _KartuSensor(
            icon: Icons.threesixty,
            judul: 'Gyroscope',
            deskripsi: 'Kecepatan rotasi pada sumbu X, Y, dan Z',
            error: _errGyro,
            x: _gyro?.x,
            y: _gyro?.y,
            z: _gyro?.z,
            satuan: 'rad/s',
          ),
          const SizedBox(height: 14),
          _KartuSensor(
            icon: Icons.explore_outlined,
            judul: 'Magnetometer',
            deskripsi: 'Kekuatan medan magnet di sekitar perangkat',
            error: _errMag,
            x: _mag?.x,
            y: _mag?.y,
            z: _mag?.z,
            satuan: 'µT',
          ),
        ],
      ),
    );
  }
}

class _KartuSensor extends StatelessWidget {
  final IconData icon;
  final String judul;
  final String deskripsi;
  final String? error;
  final double? x;
  final double? y;
  final double? z;
  final String satuan;

  const _KartuSensor({
    required this.icon,
    required this.judul,
    required this.deskripsi,
    this.error,
    required this.x,
    required this.y,
    required this.z,
    required this.satuan,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color warnaAksen =
    isDark ? const Color(0xFF7CB2FF) : const Color(0xFF1765D1);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: warnaAksen),
                const SizedBox(width: 8),
                Text(
                  judul,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              deskripsi,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            if (error != null)
              Text(
                error!,
                style: TextStyle(
                  color: isDark ? Colors.red.shade300 : Colors.red,
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _KotakSumbu(
                      label: 'X',
                      nilai: x,
                      satuan: satuan,
                      warna: isDark
                          ? const Color(0xFF3B1E22)
                          : const Color(0xFFFDECEC),
                      warnaTeks: isDark
                          ? Colors.red.shade300
                          : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KotakSumbu(
                      label: 'Y',
                      nilai: y,
                      satuan: satuan,
                      warna: isDark
                          ? const Color(0xFF1B3626)
                          : const Color(0xFFECF8F0),
                      warnaTeks: isDark
                          ? Colors.green.shade300
                          : Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KotakSumbu(
                      label: 'Z',
                      nilai: z,
                      satuan: satuan,
                      warna: isDark
                          ? const Color(0xFF1A2A42)
                          : const Color(0xFFECF3FD),
                      warnaTeks: warnaAksen,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _KotakSumbu extends StatelessWidget {
  final String label;
  final double? nilai;
  final String satuan;
  final Color warna;
  final Color warnaTeks;

  const _KotakSumbu({
    required this.label,
    required this.nilai,
    required this.satuan,
    required this.warna,
    required this.warnaTeks,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: warna,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: warnaTeks),
          ),
          const SizedBox(height: 4),
          Text(
            nilai?.toStringAsFixed(2) ?? '-',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            satuan,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}