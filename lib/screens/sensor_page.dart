import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorPage extends StatefulWidget {
  const SensorPage({super.key});

  @override
  State<SensorPage> createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<UserAccelerometerEvent>? _userAccelSub;

  AccelerometerEvent? _accel;
  GyroscopeEvent? _gyro;
  UserAccelerometerEvent? _userAccel;
  bool _aktif = true;
  String? _pesanError;

  @override
  void initState() {
    super.initState();
    _mulaiSensor();
  }

  void _mulaiSensor() {
    _hentikanSensor();
    setState(() {
      _aktif = true;
      _pesanError = null;
    });

    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen(
          (event) {
        if (mounted) setState(() => _accel = event);
      },
      onError: (_) {
        if (mounted) {
          setState(() => _pesanError = 'Sensor Accelerometer tidak tersedia');
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
          setState(() => _pesanError = 'Sensor Gyroscope tidak tersedia');
        }
      },
    );

    _userAccelSub = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen(
          (event) {
        if (mounted) setState(() => _userAccel = event);
      },
      onError: (_) {},
    );
  }

  void _hentikanSensor() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _userAccelSub?.cancel();
    _accelSub = null;
    _gyroSub = null;
    _userAccelSub = null;
  }

  @override
  void dispose() {
    _hentikanSensor();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Monitoring Sensor',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pantau pergerakan dan rotasi perangkat Android secara real-time.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.sensors,
                size: 18,
                color: _aktif ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                _aktif
                    ? 'Pembacaan sensor aktif'
                    : 'Pembacaan sensor dijeda',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _aktif ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
          if (_pesanError != null) ...[
            const SizedBox(height: 12),
            Text(
              _pesanError!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
          const SizedBox(height: 16),
          _KartuSensor(
            icon: Icons.screen_rotation_alt,
            judul: 'Accelerometer',
            deskripsi: 'Percepatan perangkat termasuk gravitasi',
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
            x: _gyro?.x,
            y: _gyro?.y,
            z: _gyro?.z,
            satuan: 'rad/s',
          ),
          const SizedBox(height: 14),
          _KartuSensor(
            icon: Icons.speed,
            judul: 'User Accelerometer',
            deskripsi: 'Percepatan dengan gravitasi dikurangi',
            x: _userAccel?.x,
            y: _userAccel?.y,
            z: _userAccel?.z,
            satuan: 'm/s²',
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
  final double? x;
  final double? y;
  final double? z;
  final String satuan;

  const _KartuSensor({
    required this.icon,
    required this.judul,
    required this.deskripsi,
    required this.x,
    required this.y,
    required this.z,
    required this.satuan,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1765D1)),
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
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _KotakSumbu(
                    label: 'X',
                    nilai: x,
                    satuan: satuan,
                    warna: const Color(0xFFFDECEC),
                    warnaTeks: Colors.red.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KotakSumbu(
                    label: 'Y',
                    nilai: y,
                    satuan: satuan,
                    warna: const Color(0xFFECF8F0),
                    warnaTeks: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KotakSumbu(
                    label: 'Z',
                    nilai: z,
                    satuan: satuan,
                    warna: const Color(0xFFECF3FD),
                    warnaTeks: const Color(0xFF1765D1),
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: warnaTeks,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nilai?.toStringAsFixed(2) ?? '-',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            satuan,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}