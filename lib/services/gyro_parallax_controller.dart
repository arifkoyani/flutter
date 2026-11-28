import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Combines gyroscope rotation rate and accelerometer gravity tilt into a
/// smoothed normalized `[-1, 1]` 2D offset for 3D foreground/background parallax.
class GyroParallaxController extends ValueNotifier<Offset> {
  GyroParallaxController() : super(Offset.zero);

  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  bool _isActive = false;

  bool _hasAccelBaseline = false;
  double _baseAx = 0.0;
  double _baseAy = 0.0;
  double _accelX = 0.0;
  double _accelY = 0.0;
  double _gyroTiltX = 0.0;
  double _gyroTiltY = 0.0;
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
    _gyroTiltX = (_gyroTiltX * 0.96 + y * dt * 1.45).clamp(-1.0, 1.0);
    _gyroTiltY = (_gyroTiltY * 0.96 + x * dt * 1.45).clamp(-1.0, 1.0);
    _updateFilteredOutput();
  }

  /// Processes an accelerometer sample (m/s^2) relative to resting posture.
  void addAccelerometerSample(double x, double y, double z) {
    if (!_hasAccelBaseline) {
      _hasAccelBaseline = true;
      _baseAx = x;
      _baseAy = y;
    } else {
      // Adapt slowly so any comfortable phone holding angle re-centers naturally.
      _baseAx += (x - _baseAx) * 0.012;
      _baseAy += (y - _baseAy) * 0.012;
    }

    _accelX = (-(x - _baseAx) / 4.0).clamp(-1.0, 1.0);
    _accelY = ((y - _baseAy) / 4.0).clamp(-1.0, 1.0);
    _updateFilteredOutput();
  }

  void _updateFilteredOutput() {
    final targetX = (_gyroTiltX * 0.62 + _accelX * 0.38).clamp(-1.0, 1.0);
    final targetY = (_gyroTiltY * 0.62 + _accelY * 0.38).clamp(-1.0, 1.0);
    final nextX = value.dx + (targetX - value.dx) * 0.25;
    final nextY = value.dy + (targetY - value.dy) * 0.25;
    final next = Offset(nextX, nextY);
    if ((next - value).distance > 0.0015) {
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
