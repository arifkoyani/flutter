import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'audio_service.dart';

/// Service managing user settings and audio/haptics toggles
class PreferencesService extends ChangeNotifier {
  static final PreferencesService instance = PreferencesService._internal();
  PreferencesService._internal();

  bool _isSoundOn = true;
  bool _isVibrationOn = true;
  bool _isMusicOn = false;
  Directory? _storageDir;

  bool get isSoundOn => _isSoundOn;
  bool get isVibrationOn => _isVibrationOn;
  bool get isMusicOn => _isMusicOn;

  Future<void> init({Directory? storageDir}) async {
    try {
      _storageDir = storageDir ?? await getApplicationDocumentsDirectory();
      final file = File('${_storageDir!.path}/game_prefs.json');
      if (file.existsSync()) {
        final raw = file.readAsStringSync();
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _isSoundOn = decoded['isSoundOn'] as bool? ?? true;
          _isVibrationOn = decoded['isVibrationOn'] as bool? ?? true;
          _isMusicOn = decoded['isMusicOn'] as bool? ?? false;
          AudioService.instance.setSoundOn(_isSoundOn);
          if (_isMusicOn) {
            await AudioService.instance.setMusicOn(true);
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('PreferencesService init note: $e');
    }
  }

  Future<void> _saveToDisk() async {
    try {
      final dir = _storageDir ?? await getApplicationDocumentsDirectory();
      _storageDir = dir;
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final file = File('${dir.path}/game_prefs.json');
      file.writeAsStringSync(
        jsonEncode({
          'isSoundOn': _isSoundOn,
          'isVibrationOn': _isVibrationOn,
          'isMusicOn': _isMusicOn,
        }),
        flush: true,
      );
    } catch (e) {
      debugPrint('PreferencesService save note: $e');
    }
  }

  Future<void> setSoundOn(bool value) async {
    _isSoundOn = value;
    AudioService.instance.setSoundOn(value);
    notifyListeners();
    await _saveToDisk();
  }

  Future<void> setVibrationOn(bool value) async {
    _isVibrationOn = value;
    notifyListeners();
    await _saveToDisk();
  }

  Future<void> setMusicOn(bool value) async {
    _isMusicOn = value;
    await AudioService.instance.setMusicOn(value);
    notifyListeners();
    await _saveToDisk();
  }
}
