import 'package:audioplayers/audioplayers.dart';

/// Service managing background music and game sound effects
class AudioService {
  static final AudioService instance = AudioService._internal();
  AudioService._internal();

  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isInitialized = false;
  bool _isMusicPlaying = false;
  bool _isSoundOn = true;

  bool get isMusicPlaying => _isMusicPlaying;
  bool get isSoundOn => _isSoundOn;

  /// Update sound effects enabled state
  void setSoundOn(bool enable) {
    _isSoundOn = enable;
    if (!enable) {
      _sfxPlayer.stop();
    }
  }

  /// Initialize audio player settings for background music and game effects
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      
      // Configure audio stream for game music so hardware volume buttons control media volume
      final AudioContext audioContext = AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
        ),
      );
      await _musicPlayer.setAudioContext(audioContext);
      _isInitialized = true;
    } catch (_) {
      // In headless test environments native platform channels are ignored
    }
  }

  /// Turn background music on or off
  Future<void> setMusicOn(bool enable) async {
    if (enable) {
      await playBackgroundMusic();
    } else {
      await stopBackgroundMusic();
    }
  }

  /// Play the background music on loop
  Future<void> playBackgroundMusic() async {
    try {
      if (!_isInitialized) {
        await init();
      }
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(AssetSource('audio/background_music.mp3'));
      _isMusicPlaying = true;
    } catch (_) {
      // Safe fallback
    }
  }

  /// Stop the background music
  Future<void> stopBackgroundMusic() async {
    try {
      await _musicPlayer.stop();
      _isMusicPlaying = false;
    } catch (_) {
      // Safe fallback
    }
  }

  /// Play mistake sound effect
  Future<void> playMistakeSound() async {
    if (!_isSoundOn) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/mistake_sound.mp3'));
    } catch (_) {}
  }

  /// Play game over sound effect
  Future<void> playGameOverSound() async {
    if (!_isSoundOn) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/game_over_sound.mp3'));
    } catch (_) {}
  }

  /// Play win sound effect on stage completion
  Future<void> playWinSound() async {
    if (!_isSoundOn) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/win_sound.mp3'));
    } catch (_) {}
  }
}
