import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:print_helper/admin/chat/components/audio_cache.dart';

class VoiceAudioManager {
  // Singleton Pattern
  static final VoiceAudioManager instance = VoiceAudioManager._();
  VoiceAudioManager._();
  // THE ONE AND ONLY PLAYER
  final AudioPlayer _player = AudioPlayer();
  // Track what is currently playing
  String? _currentPath;
  String? get currentPath => _currentPath;
  bool get isPlaying => _player.playing;
  // Stream for UI to update itself
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;

  /// Initialize (Call this in main or high level)
  Future<void> init() async {
    // Listen for completion to reset state
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _player.stop();
        _player.seek(Duration.zero);
        _currentPath = null;
      }
    });
  }

  Future<void> play(String path) async {
    try {
      // 1. If playing the SAME file, just resume
      if (_currentPath == path) {
        await _player.play();
        return;
      }
      // 2. If playing a DIFFERENT file, stop the old one
      await stop();
      // 3. Load and play the new file
      _currentPath = path;
      final file = await AudioCacheService.getCachedAudio(path);
      await _player.setFilePath(file.path);
      await _player.play();
    } catch (e) {
      debugPrint("Audio Play Error: $e");
      _currentPath = null;
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    try {
      if (_player.playing || _player.processingState != ProcessingState.idle) {
        await _player.stop();
      }
    } catch (e) {
      // Suppress errors like "codec is released already"
      debugPrint("Stop error (suppressed): $e");
    }
    _currentPath = null;
  }

  void dispose() {
    try {
      _player.dispose();
    } catch (e) {
      // Suppress codec release errors
      debugPrint("Dispose error (suppressed): $e");
    }
  }
}
