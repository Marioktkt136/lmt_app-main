import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/services/native_media_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/device_file_helper.dart';

/// Interactive Voice Note player widget with Play/Pause, Restart from beginning,
/// -5s / +5s seek buttons, interactive seek slider, and playback speed toggle
/// (`1x` / `1.5x` / `2x`).
class VoiceNotePlayerWidget extends StatefulWidget {
  /// The voice note message model.
  final ChatMessageModel msg;

  /// Whether this voice note is the currently active playing message in the room.
  final bool isPlayingVoice;

  /// Callback notifying the parent room when play/pause is toggled.
  final VoidCallback onToggleVoicePlay;

  /// Creates a [VoiceNotePlayerWidget].
  const VoiceNotePlayerWidget({
    super.key,
    required this.msg,
    required this.isPlayingVoice,
    required this.onToggleVoicePlay,
  });

  @override
  State<VoiceNotePlayerWidget> createState() => _VoiceNotePlayerWidgetState();
}

class _VoiceNotePlayerWidgetState extends State<VoiceNotePlayerWidget> {
  static const List<double> _availableSpeeds = [1.0, 1.5, 2.0];

  Timer? _progressTimer;
  double _currentSeconds = 0.0;
  double _playbackSpeed = 1.0;

  double get _totalSeconds =>
      (widget.msg.voiceDurationSeconds ?? 15).clamp(1, 3600).toDouble();

  @override
  void initState() {
    super.initState();
    if (widget.isPlayingVoice) {
      _startTicker();
    }
  }

  @override
  void didUpdateWidget(covariant VoiceNotePlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlayingVoice && !oldWidget.isPlayingVoice) {
      if (_currentSeconds >= _totalSeconds) {
        _currentSeconds = 0.0;
      }
      _startNativePlayback();
      _startTicker();
    } else if (!widget.isPlayingVoice && oldWidget.isPlayingVoice) {
      _progressTimer?.cancel();
      if (kIsWeb) {
        DeviceFileHelper.pauseAudioOnWeb();
      } else {
        NativeMediaService.pauseVoiceNote();
      }
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _startNativePlayback() async {
    final path = widget.msg.attachmentPath;
    if (path == null || path.trim().isEmpty) return;

    if (kIsWeb) {
      await DeviceFileHelper.playAudioOnWeb(path, speed: _playbackSpeed);
      return;
    }

    final resolved = await DeviceFileHelper.resolvePlayablePath(path);
    if (resolved != null && resolved.trim().isNotEmpty) {
      await NativeMediaService.playVoiceNote(
        resolved,
        speed: _playbackSpeed,
        positionMs: (_currentSeconds * 1000).round(),
      );
    }
  }

  void _startTicker() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted || !widget.isPlayingVoice) return;
      setState(() {
        _currentSeconds += 0.2 * _playbackSpeed;
        if (_currentSeconds >= _totalSeconds) {
          _currentSeconds = 0.0;
          _progressTimer?.cancel();
          if (kIsWeb) {
            DeviceFileHelper.pauseAudioOnWeb();
          } else {
            NativeMediaService.stopVoiceNote();
          }
          widget.onToggleVoicePlay();
        }
      });
    });
  }

  Future<void> _seekToSeconds(double targetSeconds) async {
    final clamped = targetSeconds.clamp(0.0, _totalSeconds);
    setState(() => _currentSeconds = clamped);
    await NativeMediaService.seekVoiceNote((clamped * 1000).round());
  }

  Future<void> _restartFromBeginning() async {
    await _seekToSeconds(0.0);
    if (!widget.isPlayingVoice) {
      widget.onToggleVoicePlay();
    } else {
      await _startNativePlayback();
    }
  }

  Future<void> _cycleSpeed() async {
    final idx = _availableSpeeds.indexOf(_playbackSpeed);
    final nextSpeed = _availableSpeeds[(idx + 1) % _availableSpeeds.length];
    setState(() => _playbackSpeed = nextSpeed);
    await NativeMediaService.setVoicePlaybackSpeed(nextSpeed);
  }

  String _formatDuration(double seconds) {
    final total = seconds.round().clamp(0, 3600);
    final mins = (total ~/ 60).toString().padLeft(2, '0');
    final secs = (total % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  String _speedLabel() {
    if (_playbackSpeed == 1.0) return '1x';
    if (_playbackSpeed == 1.5) return '1.5x';
    return '2x';
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: widget.isPlayingVoice
              ? accentGreen.withValues(alpha: 0.45)
              : AppColors.borderOf(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Play/Pause + Interactive Seek Slider + Speed Pill (1x/1.5x/2x)
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: accentGreen,
                    minimumSize: Size(38.w, 38.w),
                    padding: EdgeInsets.zero,
                  ),
                  tooltip: widget.isPlayingVoice
                      ? (isArabic ? 'إيقاف مؤقت' : 'Pause')
                      : (isArabic ? 'تشغيل' : 'Play'),
                  onPressed: widget.onToggleVoicePlay,
                  icon: Icon(
                    widget.isPlayingVoice
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 22.sp,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4.h,
                      thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: 6.5.r,
                      ),
                      overlayShape: RoundSliderOverlayShape(
                        overlayRadius: 13.r,
                      ),
                      activeTrackColor: accentGreen,
                      inactiveTrackColor: accentGreen.withValues(alpha: 0.22),
                      thumbColor: accentGreen,
                    ),
                    child: Slider(
                      value: _currentSeconds.clamp(0.0, _totalSeconds),
                      min: 0.0,
                      max: _totalSeconds,
                      onChanged: _seekToSeconds,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: _cycleSpeed,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 9.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      _speedLabel(),
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Controls Row: Restart (00:00), -5s, +5s, and Timer Display
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8.r),
                  onTap: _restartFromBeginning,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 3.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.replay_rounded,
                          size: 15.sp,
                          color: primary,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          isArabic ? 'من الأول' : 'Restart',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                InkWell(
                  borderRadius: BorderRadius.circular(8.r),
                  onTap: () => _seekToSeconds(_currentSeconds - 5.0),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 5.w,
                      vertical: 3.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fast_rewind_rounded,
                          size: 15.sp,
                          color: textSecondary,
                        ),
                        Text(
                          '-5s',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                InkWell(
                  borderRadius: BorderRadius.circular(8.r),
                  onTap: () => _seekToSeconds(_currentSeconds + 5.0),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 5.w,
                      vertical: 3.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fast_forward_rounded,
                          size: 15.sp,
                          color: textSecondary,
                        ),
                        Text(
                          '+5s',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '🎤 ${_formatDuration(_currentSeconds)} / ${_formatDuration(_totalSeconds)}',
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.bold,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
