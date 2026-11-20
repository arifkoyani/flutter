import 'package:flutter/foundation.dart';
import 'audio_service.dart';

/// Service managing user settings and audio/haptics toggles
class PreferencesService extends ChangeNotifier {
  static final PreferencesService instance = PreferencesService._internal();
  PreferencesService._internal();

  bool _isSoundOn = true;
  bool _isVibrationOn = true;
  bool _isMusicOn = false;

  bool get isSoundOn => _isSoundOn;
  bool get isVibrationOn => _isVibrationOn;
  bool get isMusicOn => _isMusicOn;

  Future<void> setSoundOn(bool value) async {
    _isSoundOn = value;
    AudioService.instance.setSoundOn(value);
    notifyListeners();
  }

  Future<void> setVibrationOn(bool value) async {
    _isVibrationOn = value;
    notifyListeners();
  }

  Future<void> setMusicOn(bool value) async {
    _isMusicOn = value;
    await AudioService.instance.setMusicOn(value);
    notifyListeners();
  }
}
