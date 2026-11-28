import 'dart:async';
import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Combines gyroscope rotation rate and accelerometer gravity tilt via a
/// complementary filter into a smoothed normalized `[-1, 1]` 2D parallax offset.
class GyroParallaxController extends ValueNotifier<Offset> {
  GyroParallaxController() : super(Offset.zero);

  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  bool _isActive = false;

  bool _hasAccelBaseline = false;
  bool _hasGyroSignal = false;
  double _neutralRoll = 0.0;
  double _neutralPitch = 0.0;
  double _accelTiltX = 0.0;
  double _accelTiltY = 0.0;
  double _fusedX = 0.0;
  double _fusedY = 0.0;
  DateTime? _lastGyroTime;

  /// Starts listening to device gyroscope and accelerometer streams.
  /// Gracefully ignores missing sensor channels on desktop/test runners.
  void start() {
    if (_isActive) return;
    _isActive = true;
    _lastGyroTime = null;
    _subscribeSensors();
  }

  void _subscribeSensors() {
    if (!_isActive) return;
    try {
      _gyroSub ??= gyroscopeEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(
        (event) {
          final now = event.timestamp;
          final prev = _lastGyroTime;
          _lastGyroTime = now;
          final dt = prev == null
              ? 0.016
              : (now.difference(prev).inMicroseconds / 1e6).clamp(0.001, 0.08);
          addGyroSample(event.x, event.y, dt: dt);
        },
        onError: (_) {},
        cancelOnError: true,
      );
    } catch (_) {
      // No gyroscope sensor / plugin registered in this environment.
    }

    try {
      _accelSub ??= accelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(
        (event) {
          addAccelerometerSample(event.x, event.y, event.z);
        },
        onError: (_) {},
        cancelOnError: true,
      );
    } catch (_) {
      // No accelerometer sensor / plugin registered in this environment.
    }
  }

  /// Pauses sensor subscriptions while the app is backgrounded.
  void pause() {
    _gyroSub?.cancel();
    _gyroSub = null;
    _accelSub?.cancel();
    _accelSub = null;
    _lastGyroTime = null;
  }

  /// Resumes sensor subscriptions when returning to the foreground.
  void resume() {
    if (!_isActive) return;
    _subscribeSensors();
  }

  /// Processes a gyroscope angular-velocity sample (rad/s).
  void addGyroSample(double x, double y, {double dt = 0.016}) {
    _hasGyroSignal = true;
    // Complementary blend: integrate gyro instantaneously and anchor to gravity.
    _fusedX = ((_fusedX + y * dt * 2.4) * 0.94 + _accelTiltX * 0.06)
        .clamp(-1.0, 1.0);
    _fusedY = ((_fusedY + x * dt * 2.4) * 0.94 + _accelTiltY * 0.06)
        .clamp(-1.0, 1.0);
    _updateFilteredOutput();
  }

  /// Processes an accelerometer gravity sample (m/s^2) relative to posture.
  void addAccelerometerSample(double x, double y, double z) {
    final roll = math.atan2(-x, math.sqrt(y * y + z * z));
    final pitch = math.atan2(y, math.sqrt(x * x + z * z));

    if (!_hasAccelBaseline) {
      _hasAccelBaseline = true;
      _neutralRoll = roll;
      _neutralPitch = pitch;
    } else {
      // Very slow baseline drift (~15s) so gentle tilts stay clearly visible.
      _neutralRoll += (roll - _neutralRoll) * 0.0015;
      _neutralPitch += (pitch - _neutralPitch) * 0.0015;
    }

    // ~15 deg (0.26 rad) gentle tilt reaches full parallax range.
    _accelTiltX = ((roll - _neutralRoll) / 0.26).clamp(-1.0, 1.0);
    _accelTiltY = ((pitch - _neutralPitch) / 0.26).clamp(-1.0, 1.0);

    if (!_hasGyroSignal) {
      _fusedX = _accelTiltX;
      _fusedY = _accelTiltY;
    } else {
      _fusedX = (_fusedX * 0.94 + _accelTiltX * 0.06).clamp(-1.0, 1.0);
      _fusedY = (_fusedY * 0.94 + _accelTiltY * 0.06).clamp(-1.0, 1.0);
    }
    _updateFilteredOutput();
  }

  void _updateFilteredOutput() {
    final nextX = value.dx + (_fusedX - value.dx) * 0.30;
    final nextY = value.dy + (_fusedY - value.dy) * 0.30;
    final next = Offset(nextX, nextY);
    if ((next - value).distance > 0.001) {
      value = next;
    }
  }

  @visibleForTesting
  void setTiltForTest(Offset tilt) {
    value = Offset(
      tilt.dx.clamp(-1.0, 1.0).toDouble(),
      tilt.dy.clamp(-1.0, 1.0).toDouble(),
    );
  }

  @override
  void dispose() {
    _isActive = false;
    pause();
    super.dispose();
  }
}
