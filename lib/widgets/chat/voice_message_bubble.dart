import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../theme/app_theme.dart';

class VoiceMessageBubble extends StatefulWidget {
  final String voiceUrl;
  final int? duration;
  final bool isMe;
  final Timestamp? timestamp;
  final bool showAvatar;
  final String? avatarUrl;
  final String? userName;

  const VoiceMessageBubble({
    super.key,
    required this.voiceUrl,
    this.duration,
    required this.isMe,
    this.timestamp,
    this.showAvatar = false,
    this.avatarUrl,
    this.userName,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _showTimestamp = false;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    // Tải trước để lấy tổng thời lượng chính xác
    if (widget.voiceUrl.isNotEmpty) {
      _audioPlayer.setSourceUrl(widget.voiceUrl).then((_) {
        // Sau khi setSource, duration có thể được cập nhật tự động
      });
    }
  }

  void _initAudioPlayer() {
    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          // Chỉ hiển thị loading nếu đang play nhưng vị trí vẫn là 0
          _isLoading = state == PlayerState.playing && _currentPosition == Duration.zero;
        });
      }
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    // Listen to completion
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero; // Reset về 0 khi hoàn tất
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        setState(() {
          _isLoading = true; // Bắt đầu loading khi chuẩn bị play
        });
        if (_currentPosition == Duration.zero || _currentPosition >= _totalDuration) {
          await _audioPlayer.play(UrlSource(widget.voiceUrl));
        } else {
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      debugPrint('❌ Error playing voice message: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi phát tin nhắn thoại: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatMessageTime(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hôm qua ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
      return '${weekdays[date.weekday % 7]} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = _totalDuration > Duration.zero
        ? _totalDuration
        : (widget.duration != null ? Duration(seconds: widget.duration!) : Duration.zero);

    // Tính toán thanh tiến trình
    final progress = effectiveDuration > Duration.zero
        ? _currentPosition.inMilliseconds / effectiveDuration.inMilliseconds
        : 0.0;

    // Hiển thị thời gian (Đang chạy > Total Duration từ metadata)
    final timeDisplay = _currentPosition > Duration.zero && _isPlaying
        ? _formatDuration(_currentPosition) // Hiển thị vị trí đang chạy
        : _formatDuration(effectiveDuration); // Hiển thị tổng thời lượng

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: widget.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar (Bên trái nếu không phải là tôi)
          if (!widget.isMe && widget.showAvatar) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              backgroundImage: widget.avatarUrl != null
                  ? NetworkImage(widget.avatarUrl!)
                  : null,
              child: widget.avatarUrl == null && widget.userName != null
                  ? Text(
                widget.userName![0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            ),
            const SizedBox(width: 8),
          ] else if (!widget.isMe)
            const SizedBox(width: 40), // Tạo khoảng trống khi không có avatar

          Flexible(
            child: Dismissible(
              key: UniqueKey(),
              direction: widget.isMe
                  ? DismissDirection.endToStart
                  : DismissDirection.startToEnd,
              confirmDismiss: (direction) async {
                setState(() {
                  _showTimestamp = true;
                });
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    setState(() {
                      _showTimestamp = false;
                    });
                  }
                });
                return false;
              },
              background: Container(
                alignment: widget.isMe
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                padding: EdgeInsets.only(
                  left: widget.isMe ? 0 : 50,
                  right: widget.isMe ? 20 : 0,
                ),
                child: widget.timestamp != null
                    ? Text(
                        _formatMessageTime(widget.timestamp!),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              child: Column(
                crossAxisAlignment: widget.isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 160,
                      maxWidth: 240,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isMe
                          ? context.primary
                          : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(widget.isMe ? 20 : 4),
                        bottomRight: Radius.circular(widget.isMe ? 4 : 20),
                      ),
                      boxShadow: !widget.isMe
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Play/Pause button - nhỏ hơn
                        Material(
                          color: widget.isMe
                              ? Colors.white.withValues(alpha: 0.2)
                              : context.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _togglePlayPause,
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              child: _isLoading
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          widget.isMe ? Colors.white : context.primary,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      _isPlaying ? Icons.pause : Icons.play_arrow,
                                      color: widget.isMe
                                          ? Colors.white
                                          : context.primary,
                                      size: 20,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 2. Progress Indicator - gọn hơn
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Progress bar (Waveform giả) - mỏng hơn
                              ClipRRect(
                                borderRadius: BorderRadius.circular(1.5),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: widget.isMe
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    widget.isMe
                                        ? Colors.white
                                        : context.primary,
                                  ),
                                  minHeight: 3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              // 3. Thời gian (Ngắn gọn) - nhỏ hơn
                              Text(
                                timeDisplay,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.isMe
                                      ? context.onPrimary.withValues(alpha: 0.9)
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Timestamp hiển thị khi vuốt
                  if (_showTimestamp && widget.timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatMessageTime(widget.timestamp!),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
