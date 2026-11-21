import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service managing background music and game sound effects
class AudioService {
  static final AudioService instance = AudioService._internal();
  AudioService._internal();

  final AudioPlayer _musicPlayer = AudioPlayer(playerId: 'bg_music');
  final AudioPlayer _mistakePlayer = AudioPlayer(playerId: 'sfx_mistake');
  final AudioPlayer _gameOverPlayer = AudioPlayer(playerId: 'sfx_game_over');
  final AudioPlayer _winPlayer = AudioPlayer(playerId: 'sfx_win');

  bool _isInitialized = false;
  bool _isMusicPlaying = false;
  bool _isMusicOn = false;
  bool _isSoundOn = true;

  bool get isMusicPlaying => _isMusicPlaying;
  bool get isMusicOn => _isMusicOn;
  bool get isSoundOn => _isSoundOn;

  /// Dedicated AudioContext for sound effects:
  /// Uses AndroidAudioFocus.none so sound effects NEVER request or steal audio focus,
  /// allowing background music to continue playing seamlessly!
  static final AudioContext sfxAudioContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none, // CRITICAL: Never interrupts or stops background music!
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
    ),
  );

  /// Dedicated AudioContext for background music
  static final AudioContext musicAudioContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.gain,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
    ),
  );

  /// Initialize audio player settings for background music and game effects
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      // Set global audio context so all auxiliary sound effects mix without stealing focus
      await AudioPlayer.global.setAudioContext(sfxAudioContext);

      await _musicPlayer.setAudioContext(musicAudioContext);
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(1.0);

      // Configure SFX players with low latency & non-interrupting context
      await _mistakePlayer.setAudioContext(sfxAudioContext);
      await _mistakePlayer.setPlayerMode(PlayerMode.lowLatency);
      await _mistakePlayer.setVolume(1.0);

      await _gameOverPlayer.setAudioContext(sfxAudioContext);
      await _gameOverPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _gameOverPlayer.setVolume(1.0);

      await _winPlayer.setAudioContext(sfxAudioContext);
      await _winPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _winPlayer.setVolume(1.0);

      // Auto-resume safeguard: if OS ever pauses background music while it should be on, resume it immediately
      _musicPlayer.onPlayerStateChanged.listen((state) {
        if (_isMusicOn && state == PlayerState.paused) {
          _musicPlayer.resume();
        }
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('AudioService init note: $e');
    }
  }

  /// Update sound effects enabled state
  void setSoundOn(bool enable) {
    _isSoundOn = enable;
    if (!enable) {
      _mistakePlayer.stop();
      _gameOverPlayer.stop();
      _winPlayer.stop();
    }
  }

  /// Turn background music on or off
  Future<void> setMusicOn(bool enable) async {
    _isMusicOn = enable;
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
      await _musicPlayer.stop();
      await _musicPlayer.setAudioContext(musicAudioContext);
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(1.0);
      await _musicPlayer.play(
        AssetSource('audio/background_music.mp3'),
        ctx: musicAudioContext,
      );
      _isMusicPlaying = true;
    } catch (e) {
      debugPrint('Error playing background music: $e');
    }
  }

  /// Stop the background music
  Future<void> stopBackgroundMusic() async {
    try {
      await _musicPlayer.stop();
      _isMusicPlaying = false;
    } catch (e) {
      debugPrint('Error stopping background music: $e');
    }
  }

  /// Play mistake sound effect without interrupting background music
  Future<void> playMistakeSound() async {
    if (!_isSoundOn) return;
    try {
      await _mistakePlayer.stop();
      await _mistakePlayer.setVolume(1.0);
      await _mistakePlayer.play(
        AssetSource('audio/mistake_sound.mp3'),
        mode: PlayerMode.lowLatency,
        ctx: sfxAudioContext,
      );
    } catch (e) {
      debugPrint('Error playing mistake sound: $e');
    }
  }

  /// Play game over sound effect without interrupting background music
  Future<void> playGameOverSound() async {
    if (!_isSoundOn) return;
    try {
      await _gameOverPlayer.stop();
      await _gameOverPlayer.setVolume(1.0);
      await _gameOverPlayer.play(
        AssetSource('audio/game_over_sound.mp3'),
        mode: PlayerMode.lowLatency,
        ctx: sfxAudioContext,
      );
    } catch (e) {
      debugPrint('Error playing game over sound: $e');
    }
  }

  /// Play win sound effect on stage completion without interrupting background music
  Future<void> playWinSound() async {
    if (!_isSoundOn) return;
    try {
      await _winPlayer.stop();
      await _winPlayer.setVolume(1.0);
      await _winPlayer.play(
        AssetSource('audio/win_sound.mp3'),
        mode: PlayerMode.lowLatency,
        ctx: sfxAudioContext,
      );
    } catch (e) {
      debugPrint('Error playing win sound: $e');
    }
  }
}
