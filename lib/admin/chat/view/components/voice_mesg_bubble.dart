import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:just_audio/just_audio.dart';
import 'package:print_helper/admin/chat/view/components/audio_cache.dart';
import 'package:print_helper/admin/chat/view/components/audio_manager.dart';
import 'package:print_helper/widgets/toasts.dart';
import 'package:print_helper/widgets/loaders.dart';

import '../../../../widgets/spacers.dart';

class VoiceMessageBubbleUI extends StatefulWidget {
  final String path;
  final int duration;
  final bool isMe;
  final bool isUploading; 

  const VoiceMessageBubbleUI({
    super.key,
    required this.path,
    required this.duration,
    required this.isMe,
    this.isUploading = false,
  });

  @override
  State<VoiceMessageBubbleUI> createState() => _VoiceMessageBubbleUIState();
}

class _VoiceMessageBubbleUIState extends State<VoiceMessageBubbleUI>
    with AutomaticKeepAliveClientMixin {
  late final PlayerController _waveController;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _playerPositionSub;

  bool _isMePlaying = false; // Is THIS specific bubble playing?
  Duration _currentPosition = Duration.zero;
  bool _isReady = false;

  // 2. Override wantKeepAlive
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _waveController = PlayerController();
    _initWaveform();
    _listenToGlobalPlayer();
  }

  /// 1. Only load the visual waveform (no audio loading yet)
  // ... inside _VoiceMessageBubbleUIState

  Future<void> _initWaveform() async {
    try {
      final file = await AudioCacheService.getCachedAudio(widget.path);
      // Safety check before starting heavy async work
      if (!mounted) return;
      await _waveController.preparePlayer(
        path: file.path,
        shouldExtractWaveform: true
        ,
        noOfSamples: 50,
        volume: 1.0,
      );
      if (mounted) {
        setState(() => _isReady = true);
      }
    } catch (e) {
      debugPrint("Waveform error: $e");
      if (mounted) {
        setState(() => _isReady = false);
      }
    }
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _playerPositionSub?.cancel();
    if (_isReady) {
      // Suppress platform exceptions during dispose (codec release)
      runZonedGuarded(
        () {
          _waveController.dispose();
        },
        (e, st) {
          // Swallow codec release errors quietly
        },
      );
    }
    super.dispose();
  }

  void _listenToGlobalPlayer() {
    final manager = VoiceAudioManager.instance;
    _playerStateSub = manager.playerStateStream.listen(
      (state) {
        if (!mounted) return;
        final isMyFile = manager.currentPath == widget.path;
        final isPlaying = state.playing && isMyFile;
        // Handle Completion (Fix for "Codec Released" crash)
        if (state.processingState == ProcessingState.completed && isMyFile) {
          try {
            // Do NOT use stopPlayer(). Use pausePlayer() + seekTo(0)
            // This stops the animation but keeps the codec alive for dispose()
            _waveController.pausePlayer();
            _waveController.seekTo(0);
          } catch (e) {
            debugPrint("Error on completion: $e");
          }
          if (mounted) {
            setState(() => _isMePlaying = false);
          }
          return;
        }
        // Handle Play/Pause
        if (isPlaying && !_isMePlaying) {
          try {
            _waveController.startPlayer(); // Removed finishMode
            if (mounted) {
              setState(() => _isMePlaying = true);
            }
          } catch (e) {
            debugPrint("Error starting player: $e");
          }
        } else if (!isPlaying && _isMePlaying) {
          try {
            _waveController.pausePlayer();
            if (mounted) {
              setState(() => _isMePlaying = false);
            }
          } catch (e) {
            debugPrint("Error pausing player: $e");
          }
        }
      },
      onError: (e) {
        debugPrint("PlayerState stream error: $e");
      },
    );

    _playerPositionSub = manager.positionStream.listen(
      (pos) {
        if (!mounted) return;
        // Only update position if it's MY file
        if (VoiceAudioManager.instance.currentPath == widget.path) {
          try {
            _waveController.seekTo(pos.inMilliseconds);
            if (mounted) {
              setState(() => _currentPosition = pos);
            }
          } catch (e) {
            debugPrint("Error seeking position: $e");
          }
        }
      },
      onError: (e) {
        debugPrint("Position stream error: $e");
      },
    );
  }

  Future<void> _toggle() async {
    if (!_isReady) return;
    final manager = VoiceAudioManager.instance;

    try {
      if (_isMePlaying) {
        await manager.pause();
      } else {
        await manager.play(widget.path);
      }
    } catch (e) {
      debugPrint("Toggle error: $e");
    }
  }

  Future<void> _downloadVoice() async {
    Loaders.show();
    try {
      final file = await AudioCacheService.downloadAudioToDevice(widget.path);
      Loaders.hide();
      if (file != null) {
        debugPrint("Downloaded to: ${file.path}");
        showToast(message: "Saved to: Download/printhelper/voice record");
      } else {
        showToast(message: "Failed to download voice message");
      }
    } catch (e) {
      Loaders.hide();
      debugPrint("Download error: $e");
      showToast(message: "Error: ${e.toString()}");
    }
  }

  String _fmt(int sec) =>
      "${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: widget.isMe ? const Color(0xfff1f1f2) : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isMe ? Colors.grey[300] : Colors.grey[400],
                ),
                child: widget.isUploading
                    ? Center(
                        child: SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black54,
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: _isReady ? _toggle : null,
                        icon: Icon(
                          _isMePlaying ? Icons.pause : Icons.play_arrow,
                          color: _isReady ? Colors.black : Colors.grey,
                        ),
                      ),
              ),
              Spacers.sbw8(),
              SizedBox(
                width: 150.w,
                height: 32, 
                child: AudioFileWaveforms(
                  playerController: _waveController,
                  size: const Size(120, 32),
                  waveformType: WaveformType.fitWidth,
                  playerWaveStyle:  PlayerWaveStyle(
                    fixedWaveColor: Colors.black,
                    liveWaveColor: Colors.blueAccent,
                    spacing: 4,
                  ),
                ),
              ),
              IconButton(
                onPressed: _isReady ? _downloadVoice : null,
                icon: Icon(
                  Icons.file_download_outlined,
                  color: _isReady ? Colors.black : Colors.grey,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: 12.w),
            child: Text(
              widget.isUploading
                  ? "Uploading..."
                  : "${_fmt(_currentPosition.inSeconds)} / ${_fmt(widget.duration)}",
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
