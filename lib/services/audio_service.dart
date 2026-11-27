import 'dart:ui' show AppLifecycleState;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service managing background music and game sound effects
class AudioService {
  static final AudioService instance = AudioService._internal();
  AudioService._internal();

  static const int _swooshPoolSize = 8;

  final AudioPlayer _musicPlayer = AudioPlayer(playerId: 'bg_music');
  final List<AudioPlayer> _swooshPool = List.generate(
    _swooshPoolSize,
    (index) => AudioPlayer(playerId: 'sfx_swoosh_$index'),
  );
  int _swooshCursor = 0;
  final AudioPlayer _mistakePlayer = AudioPlayer(playerId: 'sfx_mistake');
  final AudioPlayer _gameOverPlayer = AudioPlayer(playerId: 'sfx_game_over');
  final AudioPlayer _winPlayer = AudioPlayer(playerId: 'sfx_win');

  bool _isInitialized = false;
  bool _isMusicPlaying = false;
  bool _isMusicOn = false;
  bool _isSoundOn = true;
  bool _pausedByLifecycle = false;

  bool get isMusicPlaying => _isMusicPlaying;
  bool get isMusicOn => _isMusicOn;
  bool get isSoundOn => _isSoundOn;

  /// Universal non-exclusive AudioContext for both background music and sound effects.
  /// Using AndroidAudioFocus.none guarantees that neither the background music nor
  /// sound effects will ever steal audio focus or interrupt each other, allowing
  /// them to play concurrently in the background seamlessly!
  static final AudioContext nonInterruptingAudioContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none, // CRITICAL: Never request exclusive focus, never pause background music!
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
    ),
  );

  /// Initialize audio player settings for background music and game effects
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      // Set global audio context so all players mix without stealing focus
      await AudioPlayer.global.setAudioContext(nonInterruptingAudioContext);

      await _musicPlayer.setAudioContext(nonInterruptingAudioContext);
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(1.0);

      // Configure SFX players with low latency & non-interrupting context
      for (final player in _swooshPool) {
        await player.setAudioContext(nonInterruptingAudioContext);
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setVolume(1.0);
      }

      await _mistakePlayer.setAudioContext(nonInterruptingAudioContext);
      await _mistakePlayer.setPlayerMode(PlayerMode.lowLatency);
      await _mistakePlayer.setVolume(1.0);

      await _gameOverPlayer.setAudioContext(nonInterruptingAudioContext);
      await _gameOverPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _gameOverPlayer.setVolume(1.0);

      await _winPlayer.setAudioContext(nonInterruptingAudioContext);
      await _winPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _winPlayer.setVolume(1.0);

      // Auto-resume safeguard: if OS ever interrupts background music while it should be on, resume it immediately
      _musicPlayer.onPlayerStateChanged.listen((state) {
        if (_isMusicOn &&
            !_pausedByLifecycle &&
            state != PlayerState.playing &&
            state != PlayerState.completed) {
          Future.microtask(() {
            if (_isMusicOn &&
                !_pausedByLifecycle &&
                _musicPlayer.state != PlayerState.playing) {
              _musicPlayer.resume();
            }
          });
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
      for (final player in _swooshPool) {
        player.stop();
      }
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
      await _musicPlayer.setAudioContext(nonInterruptingAudioContext);
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(1.0);
      await _musicPlayer.play(
        AssetSource('audio/background_music.mp3'),
        ctx: nonInterruptingAudioContext,
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

  /// Pause all audio when the app is minimized/backgrounded and resume music on return.
  Future<void> handleAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (_pausedByLifecycle) return;
        _pausedByLifecycle = true;
        try {
          for (final player in _swooshPool) {
            await player.stop();
          }
          await _mistakePlayer.stop();
          await _gameOverPlayer.stop();
          await _winPlayer.stop();
          if (_isMusicOn || _isMusicPlaying) {
            await _musicPlayer.pause();
            _isMusicPlaying = false;
          }
        } catch (e) {
          debugPrint('AudioService pause note: $e');
        }
        break;
      case AppLifecycleState.resumed:
        if (!_pausedByLifecycle) return;
        _pausedByLifecycle = false;
        if (_isMusicOn) {
          try {
            await _musicPlayer.resume();
            _isMusicPlaying = true;
          } catch (_) {
            await playBackgroundMusic();
          }
        }
        break;
    }
  }

  /// Play swoosh sound effect in parallel without cutting off active swooshes
  /// or interrupting background music.
  Future<void> playSwooshSound() async {
    if (!_isSoundOn || _pausedByLifecycle) return;
    try {
      AudioPlayer? selected;
      for (var offset = 0; offset < _swooshPool.length; offset++) {
        final idx = (_swooshCursor + offset) % _swooshPool.length;
        final candidate = _swooshPool[idx];
        if (candidate.state != PlayerState.playing) {
          selected = candidate;
          _swooshCursor = (idx + 1) % _swooshPool.length;
          break;
        }
      }
      if (selected == null) {
        selected = _swooshPool[_swooshCursor];
        _swooshCursor = (_swooshCursor + 1) % _swooshPool.length;
        await selected.stop();
      }

      await selected.setVolume(1.0);
      await selected.play(
        AssetSource('audio/swoosh_sound_effects.mp3'),
        mode: PlayerMode.lowLatency,
        ctx: nonInterruptingAudioContext,
      );
    } catch (e) {
      debugPrint('Error playing swoosh sound: $e');
    }
  }

  /// Play mistake sound effect without interrupting background music
  Future<void> playMistakeSound() async {
    if (!_isSoundOn || _pausedByLifecycle) return;
    try {
      await _mistakePlayer.stop();
      await _mistakePlayer.setVolume(1.0);
      await _mistakePlayer.play(
        AssetSource('audio/mistake_sound.mp3'),
        mode: PlayerMode.lowLatency,
        ctx: nonInterruptingAudioContext,
      );
    } catch (e) {
      debugPrint('Error playing mistake sound: $e');
    }
  }

  /// Play game over sound effect without interrupting background music
  Future<void> playGameOverSound() async {
    if (!_isSoundOn || _pausedByLifecycle) return;
    try {
      await _gameOverPlayer.stop();
      await _gameOverPlayer.setVolume(1.0);
      await _gameOverPlayer.play(
        AssetSource('audio/game_over_sound.mp3'),
        mode: PlayerMode.lowLatency,
        ctx: nonInterruptingAudioContext,
      );
    } catch (e) {
      debugPrint('Error playing game over sound: $e');
    }
  }

  /// Play win sound effect on stage completion without interrupting background music
  Future<void> playWinSound() async {
    if (!_isSoundOn || _pausedByLifecycle) return;
    try {
      await _winPlayer.stop();
      await _winPlayer.setVolume(1.0);
      await _winPlayer.play(
        AssetSource('audio/win_sound.mp3'),
        mode: PlayerMode.lowLatency,
        ctx: nonInterruptingAudioContext,
      );
    } catch (e) {
      debugPrint('Error playing win sound: $e');
    }
  }
}
