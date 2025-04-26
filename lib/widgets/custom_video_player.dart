import 'package:naturafit/utilities/color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class CustomVideoPlayer extends StatefulWidget {
  final File? videoFile;
  final String? videoUrl;
  final double? width;
  final bool showControls;
  final bool showFullscreenButton;
  final VoidCallback? onDelete;

  const CustomVideoPlayer({
    Key? key,
    this.videoFile,
    this.videoUrl,
    this.width,
    this.showControls = true,
    this.showFullscreenButton = true,
    this.onDelete,
  }) : assert(videoFile != null || videoUrl != null),
       super(key: key);

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.videoFile != null 
        ? VideoPlayerController.file(widget.videoFile!)
        : VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!));
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    await _controller.initialize();
    
    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration) {
        setState(() {
          _isPlaying = false;
          _controller.seekTo(Duration.zero);
        });
      }
    });

    setState(() {
      _isInitialized = true;
    });
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _controller.setVolume(_controller.value.volume > 0 ? 0 : 1);
    });
  }

  void _openFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, StateSetter setFullscreenState) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: Stack(
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () {
                          _togglePlayPause();
                          setFullscreenState(() {});
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: AnimatedOpacity(
                            opacity: !_controller.value.isPlaying ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              _toggleMute();
                              setFullscreenState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _controller.value.volume > 0 
                                    ? Icons.volume_up 
                                    : Icons.volume_off,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator(color: myBlue60));
    }

    return SizedBox(
      width: widget.width,
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              VideoPlayer(_controller),
              if (widget.showControls) ...[
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(color: Colors.transparent),
                  ),
                ),
                if (!_controller.value.isPlaying)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        color: Colors.transparent,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleMute,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _controller.value.volume > 0 
                                ? Icons.volume_up 
                                : Icons.volume_off,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      if (widget.showFullscreenButton) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _openFullscreen,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      ]
                    ],
                  ),
                ),
                if (widget.onDelete != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 