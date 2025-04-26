import 'package:flutter/material.dart';
import 'package:naturafit/widgets/custom_video_player.dart';
import 'dart:io';

class PopupVideoPlayer extends StatefulWidget {
  final Future<File> futureVideoFile;
  final VoidCallback? onClose;

  const PopupVideoPlayer({
    Key? key,
    required this.futureVideoFile,
    this.onClose,
  }) : super(key: key);

  static void show(BuildContext context, {
    required Future<File> futureVideoFile,
    VoidCallback? onClose,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(1),
      builder: (context) => PopupVideoPlayer(
        futureVideoFile: futureVideoFile,
        onClose: onClose,
      ),
    );
  }

  @override
  State<PopupVideoPlayer> createState() => _PopupVideoPlayerState();
}

class _PopupVideoPlayerState extends State<PopupVideoPlayer> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              FutureBuilder<File>(
                future: widget.futureVideoFile,
                builder: (context, snapshot) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: MediaQuery.of(context).size.width * (_isExpanded ? 1.0 : 1.0),
                    height: MediaQuery.of(context).size.width * (_isExpanded ? 1.0 : 1.0) * (1920 / 1080),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: snapshot.hasData
                        ? CustomVideoPlayer(
                            videoFile: snapshot.data!,
                            width: MediaQuery.of(context).size.width * (_isExpanded ? 1.0 : 1.0),
                            showFullscreenButton: false,
                          )
                        : const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                  );
                },
              ),

/*
              Positioned(
                bottom: 8,
                left: 8,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              */
              Positioned(
                right: 8,
                top: 8,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    widget.onClose?.call();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
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
          ),
        ],
      ),
    );
  }
} 